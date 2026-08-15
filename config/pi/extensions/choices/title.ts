// The terminal title, in the two forms this extension needs. pi offers no way
// to read the current title back, so restoring one means rebuilding the string
// pi would have set; keeping both forms here is what stops the marked and
// unmarked variants from drifting apart.

import path from "node:path";

/**
 * pi's own APP_TITLE for a default install. pi substitutes the configured app
 * name when a custom pi config name is set, which an extension cannot read, so
 * such a session restores to this instead. Cosmetic, and no such name is in
 * use here.
 */
const APP_TITLE = "π";

/**
 * What herdr's `osc_title_blocked` rule for pi matches on. The same string
 * codex uses, so one vocabulary covers both agents in herdr's manifests.
 */
const MARKER = "[Action Required]";

/** The title pi sets for itself, rebuilt from the same two inputs pi uses. */
export function sessionTitle(sessionName: string | undefined, cwd: string): string {
  const basename = path.basename(cwd);

  return sessionName
    ? `${APP_TITLE} - ${sessionName} - ${basename}`
    : `${APP_TITLE} - ${basename}`;
}

/** The same title, marked so an outside watcher can see the session is stuck. */
export function blockedTitle(sessionName: string | undefined, cwd: string): string {
  return `${sessionTitle(sessionName, cwd)} ${MARKER}`;
}
