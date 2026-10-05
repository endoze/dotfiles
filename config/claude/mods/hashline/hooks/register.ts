import { update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { HashlineDiff, HashlineSnapshot } from '../types'
import {
  MAX_BYTES,
  MAX_ROWS,
  SEP,
  align,
  anchorFor,
  cleanAnchor,
  decodeGlyphs,
  diffOps,
  fill,
  fnv,
  hashLine,
  hasToken,
  hunks,
  parse,
  renderDiff,
  rows,
  serialize,
  textLines,
  tokenFor,
  unifiedDiff,
} from './hashline'
import type { Change, Parsed } from './hashline'

const counter = { plugin: 'hashline', key: 'counter' } as const
const files = { plugin: 'hashline', key: 'files' } as const
const undos = { plugin: 'hashline', key: 'undo' } as const
const diffs = { plugin: 'hashline', key: 'diffs' } as const

/** fs.read refuses past this, so the tools say so first. */
const MAX_FILE_BYTES = 4 * 1024 * 1024

type Input = Record<string, unknown>

class Refusal extends Error {}

const ROW_FORMAT = `Each row is \`anchor${SEP}content\`: a 4-letter anchor, the separator ${SEP}, then the line exactly as it is in the file (the separator and anchor are not part of the file). Private-use glyphs (U+E000 to U+F8FF: powerline and most nerd font icons) show as tokens such as ⟦U+E0B0⟧.`

const GLYPHS = `Type a private-use glyph as its ⟦U+XXXX⟧ token, never as the glyph itself, which is lost in transit. Every edit turns tokens into their code points. A typed \\u and four hex digits arrive as that character, so to write a literal \\u escape, type its backslash as ${tokenFor(0x5c)}: ${tokenFor(0x5c)}uE0B0.`

const TOOLS = [
  {
    name: 'read',
    description: [
      'Read a text file with a stable 4-letter anchor on every line. Use this, not Read, for any text file you may edit: the hashline edit tools address lines only by these anchors.',
      ROW_FORMAT,
      `Anchors stay valid across your own edits; a line changed on disk gets a new one. Serves at most ${MAX_ROWS} lines or ${MAX_BYTES / 1024}KB per call; use offset (1-based line) and limit to page.`,
    ].join('\n\n'),
    inputSchema: {
      type: 'object',
      properties: {
        path: { type: 'string', description: 'File path, absolute or relative to the working directory' },
        offset: { type: 'integer', minimum: 1, description: 'First line to serve, 1-based' },
        limit: { type: 'integer', minimum: 1, description: 'Most lines to serve' },
      },
      required: ['path'],
      additionalProperties: false,
    },
  },
  {
    name: 'replace',
    description: [
      'Replace the lines from anchor remove_from through anchor remove_to (inclusive) with text. For one line, pass the same anchor twice.',
      'text is the new content without anchors or separators; "" deletes the range, and one trailing newline is ignored. Every anchor must come from your latest read or edit result of this file.',
      'The result is a diff whose + rows carry the fresh anchors of the new lines.',
      GLYPHS,
    ].join('\n\n'),
    inputSchema: {
      type: 'object',
      properties: {
        path: { type: 'string' },
        remove_from: { type: 'string', description: 'Anchor of the first line to replace' },
        remove_to: { type: 'string', description: 'Anchor of the last line to replace' },
        text: { type: 'string', description: 'Replacement lines' },
      },
      required: ['path', 'remove_from', 'remove_to', 'text'],
      additionalProperties: false,
    },
  },
  {
    name: 'replace_match',
    description: [
      'Within the lines replace_from through replace_to (inclusive), replace every occurrence of old_string with new_string, left to right, without retyping the rest of the lines.',
      'old_string may span lines (join them with \\n). Fails, showing the current rows, when old_string is not in the range.',
      GLYPHS,
    ].join('\n\n'),
    inputSchema: {
      type: 'object',
      properties: {
        path: { type: 'string' },
        replace_from: { type: 'string' },
        replace_to: { type: 'string' },
        old_string: { type: 'string', minLength: 1 },
        new_string: { type: 'string' },
      },
      required: ['path', 'replace_from', 'replace_to', 'old_string', 'new_string'],
      additionalProperties: false,
    },
  },
  {
    name: 'insert',
    description: [
      'Insert text as new lines before or after the line at anchor, removing nothing. "" inserts one blank line.',
      'Leave anchor out to insert at the start (before) or end (after) of the file, which is how to add lines to an empty file.',
      GLYPHS,
    ].join('\n\n'),
    inputSchema: {
      type: 'object',
      properties: {
        path: { type: 'string' },
        anchor: { type: 'string' },
        direction: { type: 'string', enum: ['before', 'after'] },
        text: { type: 'string' },
      },
      required: ['path', 'direction', 'text'],
      additionalProperties: false,
    },
  },
  {
    name: 'undo_last_change',
    description:
      "Revert this session's last hashline edit of a file, restoring its previous content and anchors. One level per file; refused if the file changed since that edit.",
    inputSchema: {
      type: 'object',
      properties: { path: { type: 'string' } },
      required: ['path'],
      additionalProperties: false,
    },
  },
]

const locks = new Map<string, Promise<void>>()

/** Serialises edits per file so parallel tool calls apply one after another. */
async function acquire(key: string): Promise<() => void> {
  const before = locks.get(key) ?? Promise.resolve()
  let release!: () => void
  const mine = before.then(() => new Promise<void>(resolve => (release = resolve)))
  locks.set(key, mine)
  await before
  return () => {
    release()
    if (locks.get(key) === mine) locks.delete(key)
  }
}

function refuse(error: unknown): { deny: string } {
  if (error instanceof Refusal) return { deny: error.message }
  return { deny: `[E_INTERNAL] ${error instanceof Error ? error.message : String(error)}` }
}

function needString(input: Input, field: string): string {
  const value = input[field]
  if (typeof value !== 'string') throw new Refusal(`[E_BAD_SHAPE] ${field} must be a string.`)
  if (value.includes('\0')) throw new Refusal(`[E_BAD_SHAPE] ${field} contains a NUL byte.`)
  return value
}

async function resolvePath($: EngineInterface, path: string): Promise<string> {
  const stat = await $.fs.stat(path, { resolve: true }).catch(() => undefined)
  if (!stat || stat.realPath === undefined) throw new Refusal(`[E_NOT_FOUND] ${path} does not exist.`)
  if (stat.kind !== 'file') throw new Refusal(`[E_BAD_SHAPE] ${path} is not a file.`)
  if (stat.size > MAX_FILE_BYTES) throw new Refusal(`[E_FILE_TOO_LARGE] ${path} is over 4 MiB.`)
  return stat.realPath
}

async function readText($: EngineInterface, real: string, path: string): Promise<string> {
  const text = await $.fs.read(real)
  if (text.includes('\0')) throw new Refusal(`[E_BINARY] ${path} looks binary; use Read for images, PDFs and other non-text files.`)
  return text
}

async function allocate($: EngineInterface, n: number): Promise<string[]> {
  if (n === 0) return []
  const end = await update($, counter, value => (value ?? 0) + n)
  return Array.from({ length: n }, (_, k) => anchorFor(end - n + k))
}

/** Realigns the stored anchors with the file as it is on disk now, and stores the result. */
async function sync(
  $: EngineInterface,
  real: string,
  lines: string[],
  prev: HashlineSnapshot | undefined,
): Promise<HashlineSnapshot> {
  const hashes = lines.map(hashLine)
  const slots = align(prev, hashes)
  const fresh = await allocate($, slots.filter(slot => slot === undefined).length)
  const snapshot = { anchors: fill(slots, fresh), hashes }
  await $.state.set({ ...files, id: real }, snapshot)
  return snapshot
}

async function readTool($: EngineInterface, input: Input): Promise<string> {
  const path = needString(input, 'path')
  const offset = typeof input.offset === 'number' ? Math.max(1, Math.floor(input.offset)) : 1
  const limit = typeof input.limit === 'number' ? Math.max(1, Math.floor(input.limit)) : MAX_ROWS
  const real = await resolvePath($, path)
  const release = await acquire(real)
  try {
    const { lines } = parse(await readText($, real, path))
    const { value: prev } = await $.state.get({ ...files, id: real })
    const { anchors } = await sync($, real, lines, prev)
    if (lines.length === 0) return `${path} is empty. Use insert without an anchor to add lines.`
    if (offset > lines.length) throw new Refusal(`[E_BAD_SHAPE] offset ${offset} is past the end (${lines.length} lines).`)
    const out: string[] = []
    let bytes = 0
    let last = offset - 1
    const stop = Math.min(lines.length, offset - 1 + Math.min(limit, MAX_ROWS))
    for (let i = offset - 1; i < stop; i++) {
      const served = rows(lines, anchors, i, i)[0]!
      bytes += served.length + 1
      if (bytes > MAX_BYTES && out.length > 0) break
      out.push(served)
      last = i + 1
    }
    const head = `${path} · lines ${offset}-${last} of ${lines.length}`
    const more = last < lines.length ? `\n… ${lines.length - last} more lines; read with offset=${last + 1}` : ''
    return `${head}\n${out.join('\n')}${more}`
  } finally {
    release()
  }
}

type Located = { index: (raw: unknown, field: string) => number }

function locator(snapshot: HashlineSnapshot, prev: HashlineSnapshot, lines: string[]): Located {
  const known = new Set(prev.anchors)
  return {
    index(raw, field) {
      const anchor = cleanAnchor(raw)
      if (anchor === undefined) throw new Refusal(`[E_BAD_SHAPE] ${field} is not an anchor.`)
      const at = snapshot.anchors.indexOf(anchor)
      if (at >= 0) return at
      if (!known.has(anchor)) {
        throw new Refusal(`[E_STALE_ANCHOR] ${anchor} is not an anchor of this file in this session. Call read for fresh anchors.`)
      }
      const near = prev.anchors.indexOf(anchor)
      const current = rows(lines, snapshot.anchors, near - 3, near + 3).join('\n')
      throw new Refusal(`[E_RANGE_STALE] The line at ${anchor} changed on disk since you read it. Current rows near it:\n${current}`)
    },
  }
}

type Plan = { start: number; removedCount: number; added: string[]; note?: string }

function plan(kind: string, input: Input, lines: string[], at: Located, snapshot: HashlineSnapshot): Plan {
  if (kind === 'replace') {
    let from = at.index(input.remove_from, 'remove_from')
    let to = at.index(input.remove_to ?? input.remove_from, 'remove_to')
    const note = from > to ? '[W_BAD_SHAPE] remove_from was after remove_to; the range was flipped.' : undefined
    if (from > to) [from, to] = [to, from]
    const text = needString(input, 'text')
    if (hasToken(text) && lines.slice(from, to + 1).some(hasToken)) {
      throw new Refusal('[E_LITERAL_TOKEN] Those lines hold a ⟦U+XXXX⟧ token as literal text, which retyping would turn into a glyph. Use replace_match to edit around it.')
    }
    return { start: from, removedCount: to - from + 1, added: textLines(decodeGlyphs(text)), note }
  }
  if (kind === 'replace_match') {
    let from = at.index(input.replace_from, 'replace_from')
    let to = at.index(input.replace_to ?? input.replace_from, 'replace_to')
    if (from > to) [from, to] = [to, from]
    const old = decodeGlyphs(needString(input, 'old_string')).replace(/\r\n/g, '\n')
    const replacement = decodeGlyphs(needString(input, 'new_string')).replace(/\r\n/g, '\n')
    if (old === '') throw new Refusal('[E_BAD_SHAPE] old_string is empty.')
    const segment = lines.slice(from, to + 1).join('\n')
    const parts = segment.split(old)
    if (parts.length === 1) {
      const current = rows(lines, snapshot.anchors, from, Math.min(to, from + 49)).join('\n')
      throw new Refusal(`[E_SUBSTRING_NOT_FOUND] old_string is not in that range. Current rows:\n${current}`)
    }
    const note = parts.length > 2 ? `Replaced ${parts.length - 1} occurrences.` : undefined
    return { start: from, removedCount: to - from + 1, added: parts.join(replacement).split('\n'), note }
  }
  const direction = input.direction
  if (direction !== 'before' && direction !== 'after') throw new Refusal('[E_BAD_SHAPE] direction must be "before" or "after".')
  const text = decodeGlyphs(needString(input, 'text'))
  const added = text === '' ? [''] : textLines(text)
  if (input.anchor === undefined || input.anchor === '') {
    return { start: direction === 'after' ? lines.length : 0, removedCount: 0, added }
  }
  const i = at.index(input.anchor, 'anchor')
  return { start: direction === 'after' ? i + 1 : i, removedCount: 0, added }
}

/** Drops the lines a plan would replace with themselves, so only real changes get new anchors. */
function trim(lines: string[], { start, removedCount, added }: Plan): Change & { lines: string[] } {
  const removed = lines.slice(start, start + removedCount)
  let head = 0
  while (head < removed.length && head < added.length && removed[head] === added[head]) head++
  let tail = 0
  while (
    tail < removed.length - head &&
    tail < added.length - head &&
    removed[removed.length - 1 - tail] === added[added.length - 1 - tail]
  ) tail++
  return {
    start: start + head,
    removed: removed.slice(head, removed.length - tail),
    added: added.length - head - tail,
    lines: added.slice(head, added.length - tail),
  }
}

/** An edit tool's answer: the text the model reads and the diff the transcript draws. */
type Edited = { text: string; view?: HashlineDiff }

async function editTool($: EngineInterface, kind: string, input: Input): Promise<Edited> {
  const path = needString(input, 'path')
  const real = await resolvePath($, path)
  const release = await acquire(real)
  try {
    const original = await readText($, real, path)
    const parsed = parse(original)
    const { value: prev } = await $.state.get({ ...files, id: real })
    if (!prev) throw new Refusal(`[E_STALE_ANCHOR] No anchors for ${path} in this session. Call read first.`)
    const snapshot = await sync($, real, parsed.lines, prev)
    const steps = plan(kind, input, parsed.lines, locator(snapshot, prev, parsed.lines), snapshot)
    const change = trim(parsed.lines, steps)
    if (change.removed.length === 0 && change.added === 0) return { text: `No change: ${path} already has that text.` }

    const end = change.start + change.removed.length
    const segment = {
      anchors: snapshot.anchors.slice(change.start, end),
      hashes: snapshot.hashes.slice(change.start, end),
    }
    const addedHashes = change.lines.map(hashLine)
    const slots = align(segment, addedHashes)
    const fresh = await allocate($, slots.filter(slot => slot === undefined).length)
    const lines = [...parsed.lines.slice(0, change.start), ...change.lines, ...parsed.lines.slice(end)]
    const next: HashlineSnapshot = {
      anchors: [...snapshot.anchors.slice(0, change.start), ...fill(slots, fresh), ...snapshot.anchors.slice(end)],
      hashes: [...snapshot.hashes.slice(0, change.start), ...addedHashes, ...snapshot.hashes.slice(end)],
    }
    const written: Parsed = { ...parsed, lines, hasFinalEol: parsed.lines.length === 0 || parsed.hasFinalEol }
    const text = serialize(written)
    await $.fs.write(real, text)
    await $.state.set({ ...files, id: real }, next)
    await $.state.set({ ...undos, id: real }, { text: original, snapshot, writtenHash: fnv(text) })

    const ops = diffOps(change.start, change.removed, segment.anchors, change.lines, slots)
    const removed = ops.filter(op => op.kind === '-').length
    const added = ops.filter(op => op.kind === '+').length
    const summary = `Edited ${path}: -${removed} +${added} at line ${change.start + 1}.`
    const diff = renderDiff(hunks(ops, lines, 1), next.anchors)
    return {
      text: [summary, steps.note, diff].filter(Boolean).join('\n'),
      view: { path, source: unifiedDiff(hunks(ops, lines, 3)) },
    }
  } finally {
    release()
  }
}

async function undoTool($: EngineInterface, input: Input): Promise<Edited> {
  const path = needString(input, 'path')
  const real = await resolvePath($, path)
  const release = await acquire(real)
  try {
    const { value: entry } = await $.state.get({ ...undos, id: real })
    if (!entry) throw new Refusal(`[E_NO_UNDO] No hashline edit of ${path} to undo in this session.`)
    const current = await readText($, real, path)
    if (fnv(current) !== entry.writtenHash) {
      throw new Refusal(`[E_RANGE_STALE] ${path} changed since the last hashline edit; undo would discard that. Edit it directly instead.`)
    }
    const { value: now } = await $.state.get({ ...files, id: real })
    await $.fs.write(real, entry.text)
    await $.state.set({ ...files, id: real }, entry.snapshot)
    await $.state.set({ ...undos, id: real }, null)
    const text = `Reverted the last edit of ${path}; the anchors from before it are valid again.`
    if (!now) return { text }
    const restored = parse(entry.text).lines
    const ops = diffOps(0, parse(current).lines, now.anchors, restored, entry.snapshot.anchors)
    return { text, view: { path, source: unifiedDiff(hunks(ops, restored, 3)) } }
  } finally {
    release()
  }
}

const EDIT_TOOLS = new Set([
  'mcp__hashline__replace',
  'mcp__hashline__replace_match',
  'mcp__hashline__insert',
  'mcp__hashline__undo_last_change',
])

/** Answers an edit tool's call, keeping its diff for the transcript under the call's tool_use_id. */
async function answer($: EngineInterface, id: string | undefined, run: () => Promise<Edited>) {
  try {
    const { text, view } = await run()
    if (id && view?.source) await $.state.set({ ...diffs, id }, view)
    return { result: text }
  } catch (error) {
    return refuse(error)
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    for (const tool of TOOLS) await $.tool.register(tool)
    return next(e)
  })

  on('tool.describe', { tool: 'Edit' }, async ($, e, next) => ({
    ...(await next(e)),
    description:
      'Disabled by the hashline mod. Edit text files with mcp__hashline__read, then mcp__hashline__replace, mcp__hashline__replace_match or mcp__hashline__insert.',
    isDeferred: true,
  }))

  on('tool.describe', { tool: 'Read' }, async ($, e, next) => {
    const described = await next(e)
    return {
      ...described,
      description: `${described.description}\n\nFor a text file you may edit, use mcp__hashline__read instead: Edit is disabled, and the hashline edit tools need its anchors.`,
    }
  })

  on('tool.call', { tool: 'Edit' }, () => ({
    deny: 'Edit is disabled by the hashline mod. Call mcp__hashline__read for anchors, then mcp__hashline__replace, replace_match or insert.',
  }))

  on('tool.call', { tool: 'mcp__hashline__read' }, async ($, e) => {
    try {
      return { result: await readTool($, e as unknown as Input) }
    } catch (error) {
      return refuse(error)
    }
  })

  on('tool.call', { tool: 'mcp__hashline__replace' }, ($, e) => answer($, e.tool_use_id, () => editTool($, 'replace', e as unknown as Input)))

  on('tool.call', { tool: 'mcp__hashline__replace_match' }, ($, e) =>
    answer($, e.tool_use_id, () => editTool($, 'replace_match', e as unknown as Input)),
  )

  on('tool.call', { tool: 'mcp__hashline__insert' }, ($, e) => answer($, e.tool_use_id, () => editTool($, 'insert', e as unknown as Input)))

  on('tool.call', { tool: 'mcp__hashline__undo_last_change' }, ($, e) => answer($, e.tool_use_id, () => undoTool($, e as unknown as Input)))

  on('ui.render', { component: 'ToolResult' }, async ($, e, next) => {
    if (!EDIT_TOOLS.has(e.props.tool) || e.props.isErrored) return next(e)
    const { value: view } = await $.state.get({ ...diffs, id: e.props.tool_use_id })
    if (!view) return next(e)
    const { Code } = $.ui.resolve(e)
    return Code({ source: view.source, format: 'diff', path: view.path })
  })
}
