/** The anchors last served for one file, aligned to its lines. */
export type HashlineSnapshot = { anchors: string[]; hashes: number[] }

/** The file as it stood before the last hashline edit, for one level of undo. */
export type HashlineUndo = {
  text: string
  snapshot: HashlineSnapshot
  writtenHash: number
}

/** An edit's change as the transcript draws it, keyed by the call's tool_use_id. */
export type HashlineDiff = {
  /** The path as the call gave it, which picks the highlighter. */
  path: string
  /** Unified-diff hunks, at most 10,000 characters. */
  source: string
}

declare module 'claude-code' {
  interface PluginState {
    hashline: {
      counter: number
      files: StateFamily<HashlineSnapshot>
      undo: StateFamily<HashlineUndo | null>
      diffs: StateFamily<HashlineDiff>
    }
  }
}
