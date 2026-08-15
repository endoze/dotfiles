---
name: code-review
description: Review the current change, or a PR number, revset, or path target, for correctness bugs and reuse, simplification, efficiency, altitude, and convention cleanups at a given effort level (low and medium give fewer, high-confidence findings; high through max give broader coverage and may include uncertain findings). Use when the user asks to review a diff, a change, a revision, or a GitHub PR, or invokes /skill:code-review. Pass --comment to post findings as inline PR comments, or --fix to apply them to the working copy after the review.
---

# Code Review

## Invocation

```
/skill:code-review [low|medium|high|xhigh|max] [--fix] [--comment] [<pr#>|<revset>|<path>]
```

Parse the trailing `User:` line as: an effort level if the first bare word is
one of the five, otherwise `medium`; the flags `--fix` and `--comment`; and a
target from whatever remains. If a word looks like a level but is not one, say
you are ignoring it, name the valid levels, and use `medium`.

Open with one short line naming the effort level and noting that typing a
level (for example `/skill:code-review high`) changes it. When a target was
given, state it as ``Review target: `<target>` ``.

## What to load

Read `levels/<effort>.md` and follow it exactly. That file is the review.
Read only that one; the five levels are alternatives, not stages.

Then also read and follow `flags/comment.md` if `--comment` was passed, and
`flags/fix.md` if `--fix` was passed.

Use `jj` for all version control. Never use `git`, including read-only
commands. Reach for `jj log`, `jj show`, and `jj file annotate` when you need
history or line provenance.

## Output

The level file returns findings as a JSON array. Present that array as PR
comment ready feedback per the global review rules: numbered items, file path
and line, a fenced block of the relevant code, and the explanation and fix in
first person.

## Fan-out

Where a level file says to run finder angles or verifiers via the `Agent`
tool, dispatch each one as its own `Agent` call, all in a single message so
they run concurrently, then collect with `get_subagent_result`.

If the `Agent` tool is not in your tool set, work each angle and each
verification yourself, sequentially, in this context, and say so in your
summary.

Do not run tests, linters, formatters, builds, or typechecks. CI covers those.
