---
name: mine-skills
description: Mine recent Claude Code sessions for repeated prompts, repeated commands, corrections, and skill usage, then propose skills to add, extend, or retire, and build the approved ones. Use when the user asks what should become a skill, wants their sessions or history mined for skills, wants their skills audited against recent work, or invokes /mine-skills.
argument-hint: "[Nd | YYYY-MM-DDTHH:MM:SSZ]"
---

# Mine skills

Find repeated work in recent sessions and turn it into skills. Jujutsu only,
never git. Never commit.

## 1. Digest

```bash
~/.claude/skills/mine-skills/scripts/digest.sh
```

Add `--since <window>` only when the arguments or the request name a window
("last 60 days" becomes `60d`; a date becomes `2026-09-01T00:00:00Z`).
Without it the window starts at the last run, or 30 days back on the first
run. Keep the end time from the `window:` line for
step 4. If the digest says `nothing new since`, say so and stop.

## 2. Inventory

Read what exists, so candidates extend it instead of duplicating it:

- `~/.claude/skills/*/SKILL.md` and each skill's `references/`
- `~/.claude/commands/*.md`
- the skill names in this session's skill list, plugins included
- `~/.claude/CLAUDE.md`

## 3. Rank candidates

Group the digest's signals into at most eight candidates, ranked by count
times spread across sessions and projects. Give each one action:

- New skill: a repeated prompt or command sequence no skill covers.
- Extend: a pattern an existing skill or command almost covers. Name it.
- CLAUDE.md rule: a correction that applies to all work, not one workflow.
- Retire or merge: an Unused skills entry, or two skills covering the same
  ground. An entry with `changed_in_window` set to `yes` is new or recently
  edited; before proposing to retire it, check Skill usage for an older name
  it replaced (a renamed skill keeps its usage under the old name).

Drop a signal an existing skill or CLAUDE.md rule already covers, unless
its corrections keep recurring; then the candidate is fixing that skill or
rule. When a digest line does not show what the workflow is, find the
sessions with `grep -l` under `~/.claude/projects`, then read only the
user prompts from them, never whole transcript lines:

```bash
jq -r 'select(.type == "user" and (.message.content | type) == "string") | .message.content[0:300]' <session>.jsonl
```

## 4. Report, mark, stop

One block per candidate:

```
1 of N  <name> (<action>)
Evidence: <count> times, <sessions> sessions, <projects>
  "<quoted example>"
  "<quoted example>"
Change: <one sentence>
```

Then record the run with the end time from the `window:` line:

```bash
~/.claude/skills/mine-skills/scripts/digest.sh --mark <window end>
```

Stop and wait for the user to approve candidates by number.

## 5. Build what was approved

- New skill: write `~/.claude/skills/<name>/SKILL.md` with `name` and a
  `description` that says what it does and lists trigger phrases, in the
  style of the existing skills. Keep the body short and imperative.
- Extend, CLAUDE.md rule: edit the file with the hashline tools.
- Retire: delete only what the user approved by name.

Report one line per candidate saying what changed.
