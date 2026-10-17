---
name: watch-ci
description: Watch CI checks on one or more pull requests, or watch one deploy, with blocking scripts that end in a verdict. Use when waiting on CI after a push, asked to watch or babysit a PR or stack, or watching a deploy or rollout after a merge.
argument-hint: "[pr-number ...] | deploy [pr-number]"
---

# Watch CI

Two scripts do all the watching. Each blocks until the thing settles, prints a line per change, ends with a `---` and a verdict, and exits with the verdict's code. Run the script from the repo's directory with the Bash tool's `run_in_background: true`; the harness wakes you when it exits. While it runs, carry on with other work or end your turn: the script is the only poller.

| Exit | Verdict | Next |
| ---- | ------- | ---- |
| 0 | green | report it |
| 1 | red | report each failed check or job with its link; diagnose from what the script printed before fetching more logs |
| 2 | bad call | fix the arguments from the error and rerun |
| 3 | timed out, still pending | rerun the same command |

## Repo config

Read the `### Watch` sub-block of the repo's `## Agent skills` block (in `CLAUDE.md`, `AGENTS.md`, or `.claude/CLAUDE.md`). It holds the arguments this repo needs, and they go on every call:

```markdown
### Watch

Checks: `--ignore 'sonar|codecov'`.
Deploy: `--workflow deploy.yml --rollout prod/api --rollout prod/worker --context prod-cluster`.
```

With no sub-block, use the defaults below. Once the watch is running, offer to add the sub-block with the arguments you worked out, in the file that holds the `## Agent skills` block.

## Checks: one PR or many

```bash
~/.claude/skills/watch-ci/scripts/checks.sh [--fail-fast] <pr>...
```

The PRs are `$ARGUMENTS`, else the whole stack: each bookmark in `jj log -r 'trunk()..@'` mapped with `gh pr list --head <bookmark> --json number`. Pass every PR to one call; a PR URL works in place of a number and may name another repo.

Checks named like `sonar` are ignored by default; the repo's `--ignore` replaces that. Add `--fail-fast` when you will start fixing the first failure before the rest finish. A push mid-watch is followed: the script reports the new head and watches its checks.

## Deploy: exactly one

```bash
~/.claude/skills/watch-ci/scripts/deploy.sh --workflow <file> --pr <merged-pr>
~/.claude/skills/watch-ci/scripts/deploy.sh --workflow <file> --sha <sha>
~/.claude/skills/watch-ci/scripts/deploy.sh --workflow <file> --branch <trunk>
~/.claude/skills/watch-ci/scripts/deploy.sh --run <id-or-url>
```

Pick the target from what the user named: a merged PR, a commit, "the latest deploy" (the trunk branch), or a run. The script waits for the workflow's run on that commit to appear, which for a `workflow_run` trigger means after upstream CI finishes, so a long wait before the first job line is normal.

Without a `--workflow` from repo config, read `.github/workflows/*.yml` for the workflow that deploys on a push to trunk or on `workflow_run`. When two could fit, ask which. For a `workflow_dispatch` deploy, trigger it, take the id from `gh run list --workflow <file> --event workflow_dispatch -L 1 --json databaseId`, and pass `--run`.

`--rollout NAMESPACE/DEPLOYMENT` (repeatable, with `--context`) waits on `kubectl rollout status` after a green run and prints each deployment's image, marking an image tagged with the run's commit. Add it when repo config names deployments or the user asks to confirm the cluster.

## Report

One line per PR or deploy: what it is in plain words, the verdict, and for red the failed check or job, its failing step, and its link.

## Tests

`scripts/test.sh` runs both scripts against stub `gh` and `kubectl` in `tests/bin/`. Run it after editing either script.
