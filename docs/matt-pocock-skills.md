# Matt Pocock skills: machine-wide setup

Matt Pocock's 27 skills are now installed machine-wide in
`config/claude/skills/`. They are upstream v1.3.1 (`mattpocock/skills` at
`49dd158`, 2026-10-09), with every general edit from f-forge, c2ai, and
gjallarhorn merged on top. `~/.claude/skills` is an out-of-store symlink to
that directory, so they are live already: no `nix-home` needed. Superpowers
is uninstalled. Nothing is committed.

Per-project things now live only in per-project config, and the
`setup-matt-pocock-skills` skill writes that config. The existing projects
need the [swap steps](#swap-existing-projects-to-the-global-skills).

## Precedence

Claude Code resolves a skill name enterprise > personal > project
([skills docs](https://code.claude.com/docs/en/skills.md), "Resolve skills
that share a name"). Two results:

- A personal skill shadows the project skill of the same name. The edited
  copies in f-forge, c2ai, and gjallarhorn no longer run for you wherever the
  name matches, so global skills must be fully generic. Project differences
  go in the `## Agent skills` block and `docs/agents/*.md`, not in a project
  copy of the skill.
- `code-review` is not installed as a personal skill, so `/code-review` and
  `/review` run Claude Code's built-in reviewer. The `code-review-layer.sh`
  hook then has the main session run the `reviewing-code` layer (spec,
  glossary, verification, cut, format) on its findings.

## What was installed

How it was built: each upstream HEAD file was three-way merged (`diff3`)
with f-forge's edits, using f-forge's install base (`423ed08`) as the
ancestor. Then the project-specific parts were made generic. The `agents/openai.yaml`
Codex metadata was dropped.

Identical to upstream (11): codebase-design, domain-modeling, grill-me,
grill-with-docs, research, retro, teach, to-questionnaire, wait-what, wizard,
writing-for-agents.

Changed from upstream:

| Skill | Change | Source |
|---|---|---|
| code-review | Removed (2026-10-12). Its four parallel axes and Fowler smell baseline produced mostly nits. The built-in reviewer runs instead; the spec, glossary, and rules checks moved into `reviewing-code`'s "Layering on a review agent" section. | review sessions in f-forge and c2ai, 09-14 to 10-13 |
| implement | `jj commit`, no push. One commit per PR, review fixes squashed in. Uses the repo's documented check commands. | f-forge, c2ai |
| implement-spec | jj workspaces instead of git worktrees, never `isolation: "worktree"`, never touch other workspaces. A stack of one-commit PRs (one bookmark per ticket) instead of an integration branch, fixes folded bottom-up, `gh-stack-link`, ask before `jj workspace forget`. | f-forge |
| pr | One commit per PR check. Follows the repo's PR template and conventions when present. "Pushed again", not "force-pushed". | f-forge, c2ai |
| to-tickets, to-spec, ask-matt | Stack of one-commit PRs, no `ready-for-agent`. | f-forge |
| triage, setup (triage-labels.md) | Four roles: `needs-triage`, `needs-info`, `ready`, `wontfix`. `AGENT-BRIEF.md` is now `BRIEF.md`, with agent wording removed. PR verification runs in its own jj workspace. | f-forge, gjallarhorn, c2ai's labels doc |
| handoff | Always saves to `<main checkout>/.scratch/handoffs/` (resolved through the workspace's `.jj/repo` pointer), globally gitignored and found from any workspace. Never OS temp. Ends with a one-sentence resume prompt. | all three repos, generalized |
| improve-codebase-architecture | `jj log`. HTML report goes to the main checkout's `.scratch/`, not `$TMPDIR`. | f-forge, your "I couldn't find it" correction |
| prototype, wayfinder | `prototype/<name>` and `research/<name>` bookmarks off `trunk()`. The wayfinder fix was missed in every project copy. | f-forge, new |
| diagnosing-bugs | `jj bisect run`. | f-forge |
| grilling | At most three questions per round, grouped by topic, in plain language with context. Never a bare ticket number or file path as the subject. | your corrections in c2ai, f-forge, gjallarhorn |
| setup-matt-pocock-skills | `jj git remote list`. New Visibility section: local (default) puts the block in `.claude/CLAUDE.md` with absolute paths, committed adds `.gitignore` negations. New Checks section. Jira guidance: `jira` skill, `-c <abs>/.jira.yml`, `--no-input`, one command at a time, labels left alone, PRs not a request surface. | f-forge and c2ai setup sessions |

## Superpowers

Uninstalled at user scope (`claude plugin uninstall`). The `superpowers-jj`
hooks are no longer registered: they were removed from
`config/claude/settings.base.json` and from the live
`~/.claude/settings.json`. The pre-change live file is saved as
`~/.claude/settings.json.pre-superpowers-removal`. The hook scripts stay in
`config/claude/hooks/` and are still linked into `~/.claude/hooks/`.

To use it again:
1. `claude plugin install superpowers@claude-plugins-official`
2. Restore the `hooks` block in `settings.base.json` from jj history.
3. Run `nix-home`.

The merge in `settings-merge.jq` only adds base entries, so removing the
hooks from the base alone would not have removed them from the live file.

## Your preferences, as learned

From 41 sessions that used these skills, plus the three install sessions.
Each item says where it is now enforced.

- **jj everywhere**, including `jj new <target>`, edit, `jj squash`. Leave
  `@` where the work ended. Pushing needs no "force". Enforced in the skills
  above and in global CLAUDE.md.
- **One commit per PR**, with fixes folded into the commit that introduced
  the code and separate work stacked. This was your loudest correction
  (f-forge 10-06, 10-07, 10-08; c2ai 10-09). Enforced in implement,
  implement-spec, pr, and to-tickets, and in global CLAUDE.md.
- **Humans work tickets, assisted by agents.** No `ready-for-agent` or
  `ready-for-human`. Enforced in triage, to-spec, to-tickets, setup.
- **Never touch Jira labels** you don't own. Record triage roles as
  comments. Enforced in setup's Jira guidance and each project's
  `triage-labels.md`.
- **Questions need context and small batches.** "I also don't want to do 1
  at a time either" (c2ai 10-07), "You can't just drop fucking random ticket
  numbers on me" (f-forge 10-08). Enforced in grilling.
- **Persistent, gitignored output**, never OS temp. Enforced in handoff and
  improve-codebase-architecture.
- **Short, direct output.** Global Output Rules already cover it.
- **No code comments as fixes.** Global Comment Rules plus code-review.
- **Editable files, not the plugin** ("I want the actual files/skills here
  in the repo so I can adjust them"). That is why this is a vendored copy.

Seen repeatedly but not written into any skill yet. Say which you want and
where:

1. **Fix it now, in this change.** No deferring findings to another ticket or
   PR ("fix the damn n+1, I don't care that another pr fixes it", "is
   everything fixed and nothing is left deferred?"). Best home: a line in
   global CLAUDE.md, since it applies outside these skills too.
2. **End `/implement` with the next unblocked ticket and the exact command
   to start it.** You asked "what's next?" after almost every run.
3. **Grilling defaults:** no feature flags, don't over-protect when there is
   an audit trail, and record assumptions as assumptions. These came from
   c2ai and f-forge research. They may be project-specific.

## Machine-wide vs per project

| Machine-wide (`config/claude/skills`, global CLAUDE.md) | Per project |
|---|---|
| The 27 skills and their jj, stacking, and output behavior | Issue tracker: GitHub, local `.scratch/`, or Jira project key plus `.jira.yml` |
| Four-role triage vocabulary | Label policy: create labels, or leave them alone and use comments |
| Handoffs in `.scratch/handoffs/` | Domain docs location: committed `GLOSSARY.md` + `docs/adr/`, or local `docs/agents/GLOSSARY.md` + `docs/agents/adr/` |
| Global gitignore of `.claude/`, `docs/agents/`, `.scratch/`, `.out-of-scope/`, `.jira.yml` | Visibility: local `.claude/CLAUDE.md` block, or committed `CLAUDE.md` block plus `.gitignore` negations |
| Review output format (`reviewing-code`) | Check commands: typecheck, one test file, full suite |
| | PR template and conventions (`.github/PULL_REQUEST_TEMPLATE.md`, `.claude/rules/`) |
| | Domain rules and conventions in the project CLAUDE.md |
| | Project-only skills, named so they don't collide with a global skill |

## New project setup

1. Run `/setup-matt-pocock-skills` in the main jj workspace. It asks about
   tracker, labels (only if `triage` applies), domain layout (only in a
   monorepo), visibility, and checks (only if `CLAUDE.md` lacks them). Take
   the recommended answers unless the repo says otherwise.
2. Local (the default) writes:
   - `.claude/CLAUDE.md` with the `## Agent skills` block
   - `docs/agents/issue-tracker.md`
   - `docs/agents/triage-labels.md`
   - `docs/agents/domain.md`

   All paths are absolute so `.worktrees/*` workspaces resolve them. All of
   it is already gitignored globally. Committed writes the block into the
   root `CLAUDE.md` and adds `!/.claude/`, `!/docs/agents/`, and
   `/.claude/settings.local.json` to `.gitignore`, the way gjallarhorn does.
3. For Jira, create `<repo>/.jira.yml` with the `jira` skill. It is globally
   ignored.
4. A project-only skill goes in `<repo>/.claude/skills/<name>/`, named so it
   does not collide with a global skill. To change a global skill's behavior
   for one repo, put the difference in the Agent skills block or
   `docs/agents/*.md`. A same-named project copy will not load.

## Swap existing projects to the global skills

The global skills already win over the project copies. These steps remove the
dead copies and move what was project-specific into config. All of it is
untracked except in gjallarhorn. Run each step from the project's main
workspace.

### f-forge

Done (2026-10-11):
- The handoffs were moved to `.scratch/handoffs/`, and the references in
  `docs/superpowers/` specs and plans now point there.
- `.claude/skills/` was deleted. Every copy had a same-named global twin, so
  none of them loaded.
- The superpowers key was removed from `.claude/settings.local.json`.

Left: finish the glossary consolidation from session 2485cd42 (merge
`docs/superpowers/GLOSSARY.md` into the root `GLOSSARY.md`), then point
`docs/agents/domain.md` and the block at the root file.

`.claude/CLAUDE.md` and `docs/agents/*.md` already match the global setup's
local layout, so nothing else changes.

### c2ai

Done (2026-10-11):
- The handoffs were moved to `.scratch/handoffs/`.
- Every `.claude/agents-local/...` path in `CLAUDE.local.md` and
  `.claude/agents-local/*.md` is now absolute, so `.worktrees/*` workspaces
  resolve them.
- `triage-labels.md` now uses the `ready` role.
- No `### Checks` section is needed: the tracked `CLAUDE.md` already says to
  run `make test` and `make test-js`, and `implement` reads it.
- `.claude/skills/` was deleted, including the stale, unused
  `reset-reservations`. A headless session in c2ai confirmed `pr` loaded from
  `~/.claude/skills/pr` before the deletion.
- The 27 skill lines were removed from `.git/info/exclude`, and the
  superpowers key from `.claude/settings.local.json`.

The other c2ai-specific edits are covered generically now:
- The PR template mapping: `pr` follows `.github/PULL_REQUEST_TEMPLATE.md`
  and `.claude/rules/pr-conventions.md`.
- The `CTB-` key lookup: `code-review` reads tracker keys.

Optional: move `.claude/agents-local/` to `docs/agents/` and drop the remap
lines in `CLAUDE.local.md`. That would match the standard layout.

### gjallarhorn

Handoffs already go to `.scratch/handoffs/`, and its `CLAUDE.md` block needs
no change. Its skills are committed, so choose:

- **Keep the committed copies** if anyone else, or a cloud session, uses the
  repo. They are shadowed for you locally. Nothing to do except removing the
  superpowers key from the committed `.claude/settings.json` in your next PR.
- **Remove them** (recommended if only you use it): delete `.claude/skills/`
  and the superpowers key in `.claude/settings.json`, and keep the `!/.claude/`
  negation so `settings.json` stays tracked. That is a commit and a PR, so do
  it as its own change.

### Gonkulator, Gonkulator-migration

No skills are installed, but they have tracked `docs/agents/` and a
`CONTEXT.md` from an older upstream. Upstream renamed it `GLOSSARY.md` on
2026-09-17. Rename it and update `docs/agents/domain.md` the next time you
work there.

## Not covered

pi: these skills target Claude Code (Skill and Agent tools) and are not
installed under `config/pi/skills`. pi has no recorded use of them.

## Updating from upstream

The installed copy is upstream `49dd158` plus local edits. To take a newer
upstream:
1. Shallow-clone `mattpocock/skills` at both `49dd158` and the new tag into a
   scratch dir.
2. For each file, run `diff3 -m <installed> <49dd158 copy> <new copy>`.
3. Drop `agents/` and resolve conflicts by hand.
4. Record the new base commit here.

## Other findings

- Install history:
  - f-forge: 10-05, hand-copied from upstream `423ed08`.
  - c2ai: 10-07, from `f3fc563`. The plugin was tried and removed.
  - gjallarhorn: 10-10, copied from f-forge.
  - No skills-lock file or `npx skills` anywhere.
- c2ai lagged f-forge: no one-commit-per-PR edits, and `ready-for-agent` was
  still in 7 skill files. The global copy supersedes both.
- `~/Projects.local` is a stale pre-migration snapshot of `~/Projects` on
  the internal disk, frozen about 2026-10-08 01:06. `~/Projects` is now the
  external APFS volume. Nothing references `Projects.local`. Don't use it as
  a source.
- Never used in any session: grill-me, implement-spec, triage, wayfinder,
  prototype, wizard, teach, to-questionnaire, diagnosing-bugs. They are
  installed anyway, because ask-matt routes to them.
