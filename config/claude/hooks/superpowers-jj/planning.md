Specs and plans must let a fresh agent stop and resume at any task boundary with no context beyond the plan file:

- The spec records the effort's rules (commit policy, jj only, anything else the user stated) so the plan inherits them.
- The plan starts with three sections, before the tasks:
  - `## Status`: Last updated; Done (task number plus one line of evidence: the test command and its result); In progress (task, step, what is partly written, and its jj base id); Next; Left.
  - `## Rules`: the user's constraints for this effort, copied from the spec and this conversation.
  - `## Resume`: read Status and Rules; run `jj status` and `jj diff --stat` and check they match Status; if In progress is set, re-run that task's last verification and finish or fix the partial work by editing (never `jj restore` or `jj undo`); continue from Next. If anything disagrees, stop and ask in a sentence or two.
- The plan ends with an append-only `## Decisions` section for deviations and rulings, and `## Deferred` for out-of-scope findings and review minors.
- Every task ends with "Update Status" instead of "Commit". Size tasks so each one ends green and verifiable.
- Plans and specs live under `docs/superpowers/`, never in a scratchpad or tmp path.
