import { describe, expect, test } from 'claude-code/testing'
import type { On } from 'claude-code'

import { align, anchorFor, cleanAnchor, decodeGlyphs, encodeGlyphs, parse, serialize, unifiedDiff } from '../hooks/hashline'

const POWERLINE = String.fromCharCode(0xe0b0)
const GITHUB = String.fromCharCode(0xf113)
const token = (hex: string) => `⟦U+${hex}⟧`

function disk(on: On, files: Record<string, string>) {
  on('fs.stat', ($, e) => {
    const text = files[e.path]
    if (text === undefined) return { deny: 'ENOENT' }
    return { value: { kind: 'file', size: text.length, mtimeMs: 0, isLink: false, realPath: e.path } }
  })
  on('fs.read', ($, e) => {
    const text = files[e.path]
    if (text === undefined) return { deny: 'ENOENT' }
    return { value: text }
  })
  on('fs.write', ($, e) => {
    files[e.path] = e.text
    return { value: undefined }
  })
}

function anchorsOf(text: string): string[] {
  return [...text.matchAll(/^[+ ]?([A-Z][a-z]{3})│/gm)].map(m => m[1]!)
}

async function call($: { tool: { call: (input: never) => Promise<unknown> } }, input: Record<string, unknown>) {
  const ran = (await $.tool.call(input as never)) as { result?: unknown; deny?: string; text?: string }
  return String(ran.deny ?? ran.result ?? ran.text)
}

describe('core', () => {
  test('anchors are four letters and distinct', () => {
    const seen = new Set(Array.from({ length: 5000 }, (_, n) => anchorFor(n)))
    expect(seen.size).toBe(5000)
    expect(anchorFor(0)).toBe('Alsp')
  })

  test('parse and serialize round-trip line endings', () => {
    for (const text of ['', 'a', 'a\n', 'a\r\nb\r\n', '\n\n']) {
      expect(serialize(parse(text))).toBe(text)
    }
  })

  test('align keeps anchors of unchanged lines around a change', () => {
    const prev = { anchors: ['Aaaa', 'Bbbb', 'Cccc', 'Dddd'], hashes: [1, 2, 3, 4] }
    expect(align(prev, [1, 9, 3, 4])).toEqual(['Aaaa', undefined, 'Cccc', 'Dddd'])
    expect(align(prev, [1, 3, 7, 4])).toEqual(['Aaaa', 'Cccc', undefined, 'Dddd'])
  })

  test('cleanAnchor accepts pasted rows', () => {
    expect(cleanAnchor('Dafo│function hello() {')).toBe('Dafo')
    expect(cleanAnchor('+Dafo│x')).toBe('Dafo')
    expect(cleanAnchor('nope')).toBe(undefined)
  })

  test('glyph tokens stand in for private-use code points only', () => {
    const line = `a${POWERLINE}b 日本 ⟦U+0⟧`
    expect(encodeGlyphs(line)).toBe(`a${token('E0B0')}b 日本 ⟦U+0⟧`)
    expect(decodeGlyphs(encodeGlyphs(line))).toBe(line)
    expect(decodeGlyphs(token('F0001'))).toBe(String.fromCodePoint(0xf0001))
    expect(decodeGlyphs('⟦U+0000⟧ ⟦U+D800⟧ ⟦U+110000⟧')).toBe('⟦U+0000⟧ ⟦U+D800⟧ ⟦U+110000⟧')
  })

  test('a unified diff cut to its budget still counts its rows', () => {
    const ops = Array.from({ length: 50 }, (_, k) => ({ kind: '+' as const, before: 0, after: k, text: `line ${k}` }))
    const source = unifiedDiff([ops, ops], 200)
    const [header, ...body] = source.split('\n')
    expect(source.length <= 200).toBe(true)
    expect(header).toBe(`@@ -0,0 +1,${body.length} @@`)
  })
})

describe('tools', () => {
  test('read serves anchored rows and replace edits by anchor', async ($, on) => {
    const files: Record<string, string> = { '/a.ts': 'one\ntwo\nthree\n' }
    disk(on, files)

    const read = await call($, { tool: 'mcp__hashline__read', path: '/a.ts' })
    const [a1, a2, a3] = anchorsOf(read.split('\n').slice(1).join('\n'))
    expect(read).toContain(`${a2}│two`)

    const edited = await call($, { tool: 'mcp__hashline__replace', path: '/a.ts', remove_from: a2, remove_to: a2, text: 'TWO\n2b' })
    expect(files['/a.ts']).toBe('one\nTWO\n2b\nthree\n')
    expect(edited).toContain(`-two`)

    const again = await call($, { tool: 'mcp__hashline__read', path: '/a.ts' })
    expect(again).toContain(`${a1}│one`)
    expect(again).toContain(`${a3}│three`)
    expect(again).not.toContain(`${a2}│`)
  })

  test('a stale anchor is refused after the line changes on disk', async ($, on) => {
    const files: Record<string, string> = { '/b.ts': 'x\ny\n' }
    disk(on, files)
    const read = await call($, { tool: 'mcp__hashline__read', path: '/b.ts' })
    const [, ay] = anchorsOf(read)
    files['/b.ts'] = 'x\nchanged\n'
    const out = await call($, { tool: 'mcp__hashline__replace', path: '/b.ts', remove_from: ay, remove_to: ay, text: 'z' })
    expect(out).toContain('[E_RANGE_STALE]')
    expect(files['/b.ts']).toBe('x\nchanged\n')
  })

  test('replace_match, insert and undo', async ($, on) => {
    const files: Record<string, string> = { '/c.ts': 'const a = 1\nconst b = 1\n' }
    disk(on, files)
    const [aa, ab] = anchorsOf(await call($, { tool: 'mcp__hashline__read', path: '/c.ts' }))

    const diff = await call($, { tool: 'mcp__hashline__replace_match', path: '/c.ts', replace_from: aa, replace_to: ab, old_string: '1', new_string: '2' })
    expect(files['/c.ts']).toBe('const a = 2\nconst b = 2\n')

    const stale = await call($, { tool: 'mcp__hashline__replace_match', path: '/c.ts', replace_from: aa, replace_to: aa, old_string: '2', new_string: '3' })
    expect(stale).toContain('[E_STALE_ANCHOR]')

    const [fresh] = anchorsOf(diff.split('\n').filter(line => line.startsWith('+')).join('\n'))
    const missing = await call($, { tool: 'mcp__hashline__replace_match', path: '/c.ts', replace_from: fresh, replace_to: fresh, old_string: 'zzz', new_string: 'q' })
    expect(missing).toContain('[E_SUBSTRING_NOT_FOUND]')

    const reread = anchorsOf(await call($, { tool: 'mcp__hashline__read', path: '/c.ts' }))
    await call($, { tool: 'mcp__hashline__insert', path: '/c.ts', anchor: reread[0], direction: 'after', text: '// mid' })
    expect(files['/c.ts']).toBe('const a = 2\n// mid\nconst b = 2\n')

    await call($, { tool: 'mcp__hashline__undo_last_change', path: '/c.ts' })
    expect(files['/c.ts']).toBe('const a = 2\nconst b = 2\n')
  })

  test('insert without an anchor fills an empty file', async ($, on) => {
    const files: Record<string, string> = { '/d.ts': '' }
    disk(on, files)
    await call($, { tool: 'mcp__hashline__read', path: '/d.ts' })
    await call($, { tool: 'mcp__hashline__insert', path: '/d.ts', direction: 'after', text: 'hello' })
    expect(files['/d.ts']).toBe('hello\n')
  })

  test('the built-in Edit is denied', async ($, on) => {
    on('tool.call', () => ({ result: 'ran' }))
    const out = await call($, { tool: 'Edit', file_path: '/a.ts', old_string: 'a', new_string: 'b' })
    expect(out).toContain('hashline')
  })

  test('private-use glyphs read as tokens and edit back into glyphs', async ($, on) => {
    const files: Record<string, string> = { '/e.kdl': `left "${POWERLINE} x"\nicon "${GITHUB}"\n` }
    disk(on, files)
    const read = await call($, { tool: 'mcp__hashline__read', path: '/e.kdl' })
    expect(read).toContain(`left "${token('E0B0')} x"`)
    const [left, icon] = anchorsOf(read)

    const diff = await call($, { tool: 'mcp__hashline__replace_match', path: '/e.kdl', replace_from: left, replace_to: left, old_string: token('E0B0'), new_string: token('E0B2') })
    expect(diff).toContain(`-left "${token('E0B0')} x"`)
    await call($, { tool: 'mcp__hashline__replace', path: '/e.kdl', remove_from: icon, remove_to: icon, text: `icon "${token('F113')} ${token('E0A0')}"` })
    expect(files['/e.kdl']).toBe(`left "${String.fromCharCode(0xe0b2)} x"\nicon "${GITHUB} ${String.fromCharCode(0xe0a0)}"\n`)
  })

  test('replace refuses to retype a literal token', async ($, on) => {
    const files: Record<string, string> = { '/f.lua': `sep = "${token('E0B0')}"\n` }
    disk(on, files)
    const [sep] = anchorsOf(await call($, { tool: 'mcp__hashline__read', path: '/f.lua' }))
    const out = await call($, { tool: 'mcp__hashline__replace', path: '/f.lua', remove_from: sep, remove_to: sep, text: `sep = "${token('E0B0')}" -- x` })
    expect(out).toContain('[E_LITERAL_TOKEN]')
    expect(files['/f.lua']).toBe(`sep = "${token('E0B0')}"\n`)
  })

  test('a backslash token writes a literal backslash-u escape', async ($, on) => {
    const files: Record<string, string> = { '/h.json': '{}\n' }
    disk(on, files)
    const [brace] = anchorsOf(await call($, { tool: 'mcp__hashline__read', path: '/h.json' }))
    await call($, { tool: 'mcp__hashline__insert', path: '/h.json', anchor: brace, direction: 'before', text: `"${token('005C')}uE0B0"` })
    expect(files['/h.json']).toBe(`"${String.fromCharCode(92)}uE0B0"\n{}\n`)
  })

  test('replace_match diffs show only the lines that changed', async ($, on) => {
    const files: Record<string, string> = { '/g.txt': 'one\ntwo\nthree\nfour\nfive\n' }
    disk(on, files)
    const [first, , three, , last] = anchorsOf(await call($, { tool: 'mcp__hashline__read', path: '/g.txt' }))
    const diff = await call($, { tool: 'mcp__hashline__replace_match', path: '/g.txt', replace_from: first, replace_to: last, old_string: 'o', new_string: '0' })
    expect(files['/g.txt']).toBe('0ne\ntw0\nthree\nf0ur\nfive\n')
    expect(diff).toContain('-3 +3')
    expect(diff).not.toContain('-three')
    expect(diff).toContain(` ${three}│three`)
    expect(diff.split('\n').filter(line => line.startsWith('-')).length).toBe(3)
    expect(diff.split('\n').filter(line => line.startsWith('+')).length).toBe(3)
  })

  test('an edit result draws as a unified diff and keeps its text for the model', async ($, on) => {
    const files: Record<string, string> = { '/i.ts': 'one\ntwo\nthree\n' }
    disk(on, files)
    const [, two] = anchorsOf(await call($, { tool: 'mcp__hashline__read', path: '/i.ts' }))
    const tool = 'mcp__hashline__replace'
    const text = await call($, { tool, tool_use_id: 'toolu_diff', path: '/i.ts', remove_from: two, remove_to: two, text: 'TWO' })
    expect(text).toMatch(/^\+[A-Z][a-z]{3}│TWO$/m)
    for (const surface of ['terminal', 'desktop'] as const) {
      const props = { tool_use_id: 'toolu_diff', tool, output: text, isErrored: false }
      const ui = await $.ui.mount({ plugin: 'hashline', surface, component: 'ToolResult', requestId: 'toolu_diff', props })
      const code = await ui.find({ type: 'Code' })
      expect(code?.props.format).toBe('diff')
      expect(code?.props.path).toBe('/i.ts')
      expect(code?.props.source).toBe('@@ -1,3 +1,3 @@\n one\n-two\n+TWO\n three')
      await ui.unmount()
    }
  })

  test('undo draws the lines it restored', async ($, on) => {
    const files: Record<string, string> = { '/j.ts': 'a\nb\n' }
    disk(on, files)
    const [a] = anchorsOf(await call($, { tool: 'mcp__hashline__read', path: '/j.ts' }))
    await call($, { tool: 'mcp__hashline__insert', path: '/j.ts', anchor: a, direction: 'after', text: 'mid' })
    const tool = 'mcp__hashline__undo_last_change'
    const text = await call($, { tool, tool_use_id: 'toolu_undo', path: '/j.ts' })
    const props = { tool_use_id: 'toolu_undo', tool, output: text, isErrored: false }
    const ui = await $.ui.mount({ plugin: 'hashline', surface: 'terminal', component: 'ToolResult', requestId: 'toolu_undo', props })
    expect((await ui.find({ type: 'Code' }))?.props.source).toBe('@@ -1,3 +1,2 @@\n a\n-mid\n b')
  })
})
