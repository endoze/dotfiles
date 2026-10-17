Local overrides for superpowers. These are the user's standing rules and take precedence over the skill text above wherever they conflict.

- Jujutsu only. Never run git, not even read-only. Map the skill's git steps to jj:
  - repo root: `jj root`
  - task base (instead of BASE/HEAD SHAs): `jj log -r @ --no-graph -T commit_id`, recorded before the task starts
  - review diff: `jj diff --from <base> --to @ --git --context 10`, written to a file for the reviewer
  - files changed: `jj diff --from <base> --to @ --stat`
- Do not run the plugin's git-backed scripts (`sdd-workspace`, `task-start`, `task-done`, `review-package`). Do their job with the jj commands above. The plan workspace is `$(jj root)/.superpowers/sdd/<plan-basename>/`; create it with `mkdir -p` and make sure `.superpowers/sdd/.gitignore` contains `*`. `task-brief` has no git and is fine when given an explicit OUTFILE.
- No commits. Every change stays in the working copy `@` unless the plan's `## Rules` or the user says otherwise. Do not run `jj commit`, `jj new`, `jj describe`, `jj squash`, `jj split`, `jj abandon`, `jj restore`, `jj undo` or `jj rebase` on your own. Wherever the skill says "commit", update the plan's `## Status` instead.
- No worktrees. Work in the current jj workspace. Never create, forget or touch other jj workspaces.
