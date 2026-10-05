# JQL snippets for `jira issue list -q`

Pass any of these via `-q '<jql>'`. Combine with `--plain` for parseable output.

Every invocation still needs `-c` with the full config path typed out literally,
e.g. `jira -c ~/Projects/c2ai/.jira.yml issue list -q'...'`. Never use `$CONFIG`,
a shell variable, or the default config. See the MANDATORY section in SKILL.md.

## Assignment / ownership

```
assignee = currentUser()
assignee = "jane@example.com"
assignee is EMPTY
reporter = currentUser() AND resolution = Unresolved
```

## Status / resolution

```
status = "In Progress"
status in ("To Do", "In Progress")
status != Done
resolution = Unresolved
statusCategory != Done
```

## Time windows

```
created >= -7d
updated >= startOfWeek()
resolved >= startOfMonth()
duedate <= endOfWeek() AND resolution = Unresolved
```

## Sprint / epic / parent

```
sprint in openSprints()
sprint in openSprints() AND assignee = currentUser()
"Epic Link" = ABC-100
parent = ABC-100
```

## Labels / components / versions

```
labels in (backend, urgent)
component = "API"
fixVersion = "1.2.0"
affectedVersion = "1.1.0"
```

## Text search

```
text ~ "login error"
summary ~ "timeout"
```

## Useful combos

```
# My open work this sprint
assignee = currentUser() AND sprint in openSprints() AND statusCategory != Done

# Stale tickets (no update in 2 weeks, not done)
updated <= -14d AND statusCategory != Done

# Bugs reported this week
type = Bug AND created >= startOfWeek()

# Blocked issues
status = Blocked OR labels = blocked OR "Flagged" is not EMPTY
```

## Ordering

Append `ORDER BY <field> [ASC|DESC]`:

```
assignee = currentUser() ORDER BY priority DESC, updated DESC
```
