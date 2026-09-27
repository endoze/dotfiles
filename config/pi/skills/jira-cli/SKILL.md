---
name: jira-cli
description: Manage Jira issues, epics, sprints, and boards from the terminal using the `jira` command (ankitpokhrel/jira-cli). Use when the user wants to create, edit, view, list, transition, assign, comment on, or link Jira issues, work with epics/sprints, or otherwise interact with Jira from the command line.
---

# jira-cli

Wraps the `jira` binary (ankitpokhrel/jira-cli). If a command fails with a config error, ask the user to run `jira init` themselves in a normal terminal outside this session. It requires interactive prompts, which have no TTY here and will hang indefinitely.

## MANDATORY: always pass `-c <full path>`

**EVERY `jira` invocation MUST include `-c` with the full config path written out
literally in the command. No exceptions.**

- Run ONE `jira` command at a time. No shell variables, no `$CONFIG`, no
  `export`, no command chaining, no `$(...)` substitution.
- Type the full path directly into every command:

| Repo (path contains) | Pass exactly                                 | Project key |
| -------------------- | -------------------------------------------- | ----------- |
| `c2ai`               | `-c ~/Projects/c2ai/.jira.yml`               | `CTB`       |
| `omnius-mc`          | `-c ~/Projects/omnius-mc/.jira.yml`          | `MCTB`      |
| `f-forge`            | `-c ~/Projects/f-forge/.jira.yml`            | `FF`        |
| anything else        | STOP — ask the user which `.jira.yml` to use | —           |

```bash
jira -c ~/Projects/c2ai/.jira.yml me
```

### Flightline Forge (`f-forge`) lives on `FF`, not `MCTB`

Flightline Forge work used to be tracked on the `MCTB` board and was migrated to
its own `FF` project. `MCTB` is now Mission Command / Omnius work only.

- In `f-forge`, always use `-c ~/Projects/f-forge/.jira.yml` (project `FF`).
- Old `MCTB-*` keys for migrated issues still resolve, because Jira redirects a
  moved issue's old key. A live `MCTB-*` key in an f-forge branch name, commit
  message, or PR body is a pre-migration reference, NOT a reason to use the
  omnius-mc config. Look the issue up under `FF`.
- Never file new Flightline Forge issues on `MCTB`.

### Red flags — STOP if you catch any of these

- A `jira` command without `-c <full path>`.
- Using `$CONFIG`, a variable, `export`, or `$(...)` instead of the literal path.
- Guessing a config path for an unknown repo instead of asking.
- "It probably uses the default config" — no, pass the full `-c` path.
- Worktrees: a worktree under `c2ai/.worktrees/...` still uses the c2ai path, and
  one under `f-forge/.worktrees/...` still uses the f-forge path.
- Reaching for the omnius-mc config in `f-forge` because you saw an `MCTB-*` key
  — see the Flightline Forge note above.

## General rules

- Always pass flags non-interactively: combine `--no-input` with required flags so commands don't drop into a TUI/prompt. Interactive prompts will hang in this environment.
- When the user gives an issue key (e.g. `ABC-123`), use it directly. When they don't, infer from context or ask.
- Project defaults come from the config file. Use `-p PROJECT` only when overriding.
- For multi-line bodies/descriptions/comments, pipe via stdin or use `--template <file>` rather than a giant `-b` string. With stdin, still pass `--no-input`.
- For machine-readable output use `--plain` (table) or `--raw` (JSON). The default output is an interactive TUI — avoid it in scripts.
- After mutating commands, confirm what was done (echo the issue key/URL from output).

## Common operations

### View / list

```bash
jira -c ~/Projects/c2ai/.jira.yml issue view ABC-123                          # render issue
jira -c ~/Projects/c2ai/.jira.yml issue view ABC-123 --comments 10            # include recent comments
jira -c ~/Projects/c2ai/.jira.yml issue view ABC-123 --raw                    # full JSON

jira -c ~/Projects/c2ai/.jira.yml issue list --plain --no-truncate            # all issues, plain text
jira -c ~/Projects/c2ai/.jira.yml issue list -a you@example.com -s~Done --plain   # mine (use your own account)
jira -c ~/Projects/c2ai/.jira.yml issue list -q'sprint in openSprints() AND assignee = currentUser()' --plain
jira -c ~/Projects/c2ai/.jira.yml issue list "search text" --plain            # text search
```

### Create

```bash
# Minimal task
jira -c ~/Projects/c2ai/.jira.yml issue create --no-input -tTask -s"Summary here" -b"Description body"

# Bug with labels/priority/assignee
jira -c ~/Projects/c2ai/.jira.yml issue create --no-input -tBug -yHigh -s"Crash on login" \
  -lurgent -lregression -a you@example.com -b"Repro steps..."

# Body from stdin (multi-line)
printf '## Context\n...\n## Steps\n...\n' | jira -c ~/Projects/c2ai/.jira.yml issue create --no-input -tTask -s"Summary"

# Body from a file (good for long descriptions)
jira -c ~/Projects/c2ai/.jira.yml issue create --no-input -tStory -s"Summary" --template /tmp/desc.md

# Sub-task (parent required)
jira -c ~/Projects/c2ai/.jira.yml issue create --no-input -t"Sub-task" -P ABC-100 -s"Subtask summary"

# Custom fields (e.g. story points)
jira -c ~/Projects/c2ai/.jira.yml issue create --no-input -tStory -s"Title" --custom story-points=3
```

### Edit

```bash
jira -c ~/Projects/c2ai/.jira.yml issue edit ABC-123 --no-input -s"New summary" -yHigh
jira -c ~/Projects/c2ai/.jira.yml issue edit ABC-123 --no-input -a you@example.com     # assign (your own account)
echo "Updated description" | jira -c ~/Projects/c2ai/.jira.yml issue edit ABC-123 --no-input    # body from stdin
jira -c ~/Projects/c2ai/.jira.yml issue edit ABC-123 --no-input -lneedsreview                   # append label
jira -c ~/Projects/c2ai/.jira.yml issue edit ABC-123 --no-input --label -urgent                 # remove label (leading -)
```

### Transition / assign / comment

```bash
jira -c ~/Projects/c2ai/.jira.yml issue move ABC-123 "In Progress"
jira -c ~/Projects/c2ai/.jira.yml issue move ABC-123 Done -R Fixed --comment "Shipped in v1.2"

jira -c ~/Projects/c2ai/.jira.yml issue assign ABC-123 you@example.com   # to self (your own account)
jira -c ~/Projects/c2ai/.jira.yml issue assign ABC-123 jane@example.com
jira -c ~/Projects/c2ai/.jira.yml issue assign ABC-123 x                          # unassign

jira -c ~/Projects/c2ai/.jira.yml issue comment add ABC-123 "Quick note" --no-input
printf 'Multi-line\n\ncomment body' | jira -c ~/Projects/c2ai/.jira.yml issue comment add ABC-123 --no-input
```

### Link / clone / delete / watch

```bash
jira -c ~/Projects/c2ai/.jira.yml issue link ABC-1 ABC-2 Blocks
jira -c ~/Projects/c2ai/.jira.yml issue unlink ABC-1 ABC-2
jira -c ~/Projects/c2ai/.jira.yml issue clone ABC-123 -s"Copy of thing"
jira -c ~/Projects/c2ai/.jira.yml issue delete ABC-123
jira -c ~/Projects/c2ai/.jira.yml issue watch ABC-123
```

### Worklog

```bash
jira -c ~/Projects/c2ai/.jira.yml issue worklog add ABC-123 "1h 30m" --no-input
jira -c ~/Projects/c2ai/.jira.yml issue worklog add ABC-123 "45m" --comment "Investigation" --no-input
```

### Epics / sprints

```bash
jira -c ~/Projects/c2ai/.jira.yml epic list --plain
jira -c ~/Projects/c2ai/.jira.yml epic create --no-input -n"Epic name" -s"Summary" -b"Body"
jira -c ~/Projects/c2ai/.jira.yml epic add ABC-100 ABC-101 ABC-102   # add issues to epic

jira -c ~/Projects/c2ai/.jira.yml sprint list --plain
jira -c ~/Projects/c2ai/.jira.yml sprint add <sprint-id> ABC-101 ABC-102
```

### Open in browser

```bash
jira -c ~/Projects/c2ai/.jira.yml open ABC-123
```

## Tips

- `jira -c ~/Projects/c2ai/.jira.yml me` prints the configured user. Run it as its own command first, then paste the returned account into `-a`/`-r`. Do NOT use `$(...)` substitution.
- Status filters accept `~` for "not equal": `-s~Done`.
- For scripts/parsing, use `--plain --no-headers --no-truncate` or `--raw`.
- `--web` on most mutating commands opens the issue in a browser after success — useful when the user asks to "create and open".
- `-c ~/Projects/c2ai/.jira.yml` is REQUIRED on every command — see the MANDATORY section above. Never rely on the default config or omit `-c`.
- See `references/jql.md` for common JQL snippets to combine with `jira -c ~/Projects/c2ai/.jira.yml issue list -q`.
