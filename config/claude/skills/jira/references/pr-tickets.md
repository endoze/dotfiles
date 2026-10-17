# Jira tickets for pull requests

Create one tracking ticket per GitHub PR: typed from the conventional commit
prefix, described as the need rather than the fix, synced to the PR's state,
added to the active sprint, and cross-linked from the PR.

Every `jira` command here follows SKILL.md: the literal `-c <full path>` from
its table (ask for an unknown repo), `--no-input`, one command at a time, and
no shell variables or `$(...)`.

## Workflow

1. **Gather PR data**: `gh pr view <num> --repo <owner>/<repo> --json title,body,url,state,isDraft,reviewDecision`
   for each PR. `state` is `OPEN`, `MERGED`, or `CLOSED`.
2. **Pick the config** for each PR's repo from the SKILL.md table. Flightline
   Forge PRs go to `FF` even when they mention an old `MCTB-*` key.
3. **Confirm decisions** when scope is non-trivial (see Confirmation below).
4. **Create each ticket** (see Create).
5. **Set status** from the PR state (see Status sync).
6. **Add to the active sprint** of each project (see Sprint). Tickets left in
   the backlog do not show on the team's sprint board.
7. **Cross-link** by commenting the Jira key and URL on the PR.
8. **Verify**: `issue view <KEY>` for each, then one `issue list -a<account>`
   sweep per project, with the account taken from `jira -c <cfg> me`.

## Issue type from the conventional commit prefix

| PR prefix           | Issue type |
| ------------------- | ---------- |
| `feat(...)`         | Story      |
| `fix(...)`          | Bug        |
| anything else       | Task       |

Honor a different mapping if the user asks (all Tasks, or CTB `Feature` for
feats).

## Summary

Strip the conventional commit prefix from the PR title:
`fix(helm): cut requests, fix rollout deadlock` becomes
`Cut requests, fix rollout deadlock`.

## Description: frame the need, not the solution

The ticket describes the problem that made the PR necessary: the operational
pain, the user impact, the broken invariant. The PR already explains the fix.
Read the PR body for context, then rewrite it as a problem statement; never
copy or paraphrase it. End with a blank line and `PR: <pr-url>`.

> **PR body:** "Lower the web container CPU request from 250m to 100m and the
> sidecar from 100m/256Mi to 25m/64Mi..."
>
> **Ticket body:** "The chronos production GKE node pool has hit
> `maxNodeCount` with CPU requests at ~98% of allocatable but real usage at
> ~17%, blocking new pods and timing out Helm rollouts. The chronos web
> container and its cloud-sql-proxy sidecar reserve roughly 20x their observed
> CPU. We need to right-size the chronos web pod's resource requests so
> deploys succeed at min replicas."

## Create

Write the body to a temp file with the Write tool, then:

```bash
jira -c ~/Projects/c2ai/.jira.yml issue create --no-input -tStory -s"Cut requests, fix rollout deadlock" -a"you@example.com" --template /path/to/body.md
```

Use `x` as the assignee to leave it unassigned.

## Status sync

| PR state                      | Transition       |
| ----------------------------- | ---------------- |
| `MERGED`                      | `Done`           |
| `OPEN` and in review          | `In Review`      |
| `OPEN`, draft or not reviewed | leave in backlog |
| `CLOSED` without merging      | ask the user     |

```bash
jira -c ~/Projects/c2ai/.jira.yml issue move CTB-123 "Done"
```

If a transition name is rejected, try the likely variants (`Review`,
`Code Review`, `In Progress`) before asking.

## Sprint

Once per project, find the active sprint, then add all of that project's new
keys in one call:

```bash
jira -c ~/Projects/c2ai/.jira.yml sprint list --state active --table --plain --columns id,name,state
jira -c ~/Projects/c2ai/.jira.yml sprint add <sprint-id> CTB-123 CTB-124
```

If no sprint is active, skip it and say so; never guess a future sprint.
Merged PRs still go in the sprint they were delivered against, so velocity
reporting stays accurate.

## Cross-link

```bash
gh pr comment <num> --repo <owner>/<repo> --body "Tracked in <KEY>: https://<jira-host>/browse/<KEY>"
```

## Confirmation

For three or more PRs, or any ambiguous mapping, confirm before creating:
issue type mapping, summary style (stripped prefix by default), status sync,
and whether to cross-link (yes by default). Skip this for a single
straightforward PR or when the user already said.
