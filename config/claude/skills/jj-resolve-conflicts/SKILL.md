---
name: jj-resolve-conflicts
description: Resolve jj merge conflicts in the commits the session is working on, or the ones the user names. Use when the user says "resolve the conflicts", "fix the conflicts in the working copy", or a jj command reports a conflicted commit.
argument-hint: "[revision | bookmark | file]"
---

# Resolve conflicts

Resolve conflicts with jujutsu. Never use git.

1. Set the scope: the revision, bookmark, or file the user named, else the
   chain the session is on, `trunk()..@`. Every query below is limited to
   that scope. The bare `conflicts()` revset spans every branch in the repo,
   so always intersect it: `jj log -r 'conflicts() & (<scope>)'`.
   Nothing listed: say so and stop.
2. Start at the oldest conflicted commit; fixing it often clears the ones
   above it. List its files with `jj resolve --list -r <rev>`.
3. Learn what each side meant before editing: `jj log` and `jj diff -r` on
   the commits that brought in each side. Resolve to keep both intents.
   When the two intents truly clash, ask which wins.
4. Edit in place:
   - Conflicted commit is `@`: edit the files directly.
   - Otherwise: `jj new <rev>`, edit, then `jj squash` into `<rev>`.

   A `%%%%%%%` section is a diff: apply its change to the other side, and
   drop the markers and the `+`/`-` prefixes.
5. Repeat from step 2 until `jj log -r 'conflicts() & (<scope>)'` is empty.
6. Report each conflict in a sentence: which file, what the two sides
   wanted, what you kept. End with the next step on the last line. If the
   user also asked to squash or push, continue with the `ship-pr` skill.
