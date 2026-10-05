---
name: implement
description: "Implement a piece of work based on a spec or set of tickets."
disable-model-invocation: true
---

Implement the work described by the user in the spec or tickets.

If the user passes a ticket reference, fetch it from the issue tracker and state its title before starting. If the reference is ambiguous, ask.

Call the Skill tool with "tdd" where possible, at pre-agreed seams.

Run typechecking regularly, single test files regularly, and the full test suite once at the end. Use the commands the repo documents (the `## Agent skills` block's checks, `CLAUDE.md`, or the `Makefile`/`package.json`).

Once done, call the Skill tool with "code-review" to review the work.

Record the work as one change by calling the Skill tool with "commit". Its message rules are the only ones: a conventional subject plus a body saying why the change was needed. Don't push.

A pull request is exactly one commit. Everything after that first `jj commit`, code-review fixes included, is folded into it (`jj squash --into <change>`), never recorded as a "fix" or follow-up commit. If the ticket turns out to be two pieces of work, make it two stacked changes, each with its own bookmark and PR.

You MUST show the commit in your final response, every time, with no exceptions: its change id and the full message verbatim in a code block. This holds for every write of the commit: the first `jj commit`, every fold, and every message change. Read the message back from jj rather than from memory, with `rtk proxy jj log -r <change> --no-graph -T description` so blank lines survive.
