---
name: gh-stack-link
description: Link already-created PRs into GitHub's native stacked-PR UI with the gh-stack extension. Use when the user asks to link, stack, or connect PRs in GitHub's stack UI, adds a PR on top of an existing stack, or mentions gh-stack or `gh stack`.
argument-hint: "[pr-number ...]"
---

# Link a PR stack

Stacks are created and managed with jujutsu. `gh-stack` is used for
exactly one thing: linking already-created PRs into GitHub's native
stacked-PR UI. Nothing else.

## Rules

- ALWAYS invoke the binary `gh-stack` (e.g. `gh-stack link ...`), NEVER
  `gh stack`.
- NEVER run any gh-stack command that touches branches or local stack
  state: `init`, `add`, `modify`, `submit`, `push`, `rebase`, `sync`,
  `unstack`. They adopt local tracking and/or fetch-rebase-force-push,
  which clobbers jj-managed branches. Navigation/`view` are harmless but
  unnecessary; inspect with jj.
- ALWAYS pass PR numbers, never branch names. A branch argument gets
  auto-pushed to the remote; PR numbers are looked up and used as-is
  (never pushed), which keeps pushing under jj's control.

## Workflow

1. Confirm the order from the real refs for each PR:

   ```bash
   gh pr view <n> --json number,baseRefName,headRefName
   ```

   The bottom PR must target the trunk and each PR above must target the
   branch below. If the chain is broken or ambiguous, stop and ask.

2. Link bottom to top:

   ```bash
   gh-stack link <bottom-pr> <next-pr> ... <top-pr>
   ```

`link` is additive: it only adds PRs to a stack and never removes
existing members, so it is safe to re-run when a PR is added on top.
