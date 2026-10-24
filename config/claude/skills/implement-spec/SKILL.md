---
name: implement-spec
description: "Implement the result of /to-spec and /to-tickets in code."
disable-model-invocation: true
---

You have been provided a spec. This spec should have tickets associated with it, describing how to implement the spec.

The issue tracker should have been provided to you. If not, tell the user to run `/setup-matt-pocock-skills`.

The goal is the entire spec implemented as a **stack**: one change per ticket, each with its own bookmark and its own PR, stacked linearly on `trunk()`, with every ticket resolved the way the issue tracker closes work. A PR is exactly one commit, always: never a "fix" or follow-up commit, and never two tickets under one bookmark. The **top of the stack** is the bookmark of the last ticket landed, or `trunk()` before the first.

This repo uses jujutsu. Use `jj` for every version-control command, never `git`, and never the Agent tool's `isolation: "worktree"` (it creates git worktrees). The user keeps other jj workspaces in this repo: never touch a workspace this run did not create.

The tickets are not a list of steps. They are a **task graph** with blocking relationships between them. This means there is always a **frontier** of tickets which are ready to be grabbed.

Communication to and from subagents should be sparse. Communicate primarily through **context pointers**: to the spec, tickets, research notes, and previous commits. Don't duplicate information already available via pointers.

**Implementer subagents** should be run in the background where possible for maximum concurrency.

## Steps

1. Read the spec and tickets to understand the task graph.

2. (optional) Use an **exploration subagent** to conduct any exploration required by the tickets - relevant codebase files or external documentation. Ensure the exploration subagent can save files - it should save its markdown notes in a directory outside the repo, accessible by all future subagents. This lets **implementer subagents** focus on implementation rather than exploration.

3. Each ticket's bookmark is named `<type>/<ticket-id>-<slug>` (e.g. `feat/proj-142-airlift-planner`). Nothing is created up front.

4. Use **implementer subagents** to implement each ticket. Work happens in the workspace the run started in, whichever one that is: an implementer running alone works there on a new change, `jj new <top>`, where `<top>` is the current top of the stack. Create a jj workspace only when two or more implementers run at once, one per concurrent implementer; a linear task graph never needs one. Put it next to the user's existing workspaces (`jj workspace list` shows where; default `.worktrees/<ticket-slug>`): `jj workspace add <path> --name <ticket-slug> -r <top>`. Before the first `jj new`, note the starting workspace's `@`, and return to it when the run ends (`jj edit <change>`, or `jj new <its parent>` if jj abandoned it as empty). Each implementer subagent:
   - works only inside its working copy (the starting workspace, or its own), and confirms `jj log -r @-` is the top of the stack (or rebases with `jj rebase -s @ -d <top>`) before starting;
   - calls the Skill tool with `tdd` to build the ticket;
   - records the work as exactly one change with `jj commit -m "<conventional message>"`, so it sits at `@-`, and folds any later edits into it with `jj squash --into @-` rather than committing again;
   - rebases onto the current top of the stack (`jj rebase -s @- -d <top>`), resolves anything `jj log -r 'conflicts()'` shows, and reports its change ID.

5. Once an **implementer subagent** completes, land its change with a **merger subagent**, one merger at a time so the stack only grows upward: from the workspace the run started in, `jj rebase -s <change-id> -d <top>`, resolve any conflicts, then `jj bookmark create <ticket-bookmark> -r <change-id>`. That bookmark is the new top. History stays linear: one change, one bookmark, one PR per ticket, each PR based on the bookmark below it.

6. If this changes the **frontier** of available tickets, kick off more **implementer subagents** to work on the new tickets. This allows for maximum concurrency.

7. Once all tickets are complete, call the Skill tool with `code-review`, with `trunk()` as the fixed point and the top of the stack as the target. Fix each issue in the change of the ticket that introduced the code, bottom-up, never as a new change: `jj new <ticket-bookmark>`, fix, `jj squash --use-destination-message`, then resolve anything `jj log -r 'conflicts()'` shows in the changes above. Run these fixes one at a time, from the bottom of the stack up.

8. Check `jj log -r 'trunk()..<top>'` shows exactly one commit per ticket bookmark. If the user asked for PRs, push every bookmark by name (`jj git push -b <b1> -b <b2> ...`) and open one PR per bookmark, bottom-up, each based on the bookmark below it (the bottom one on trunk), then link them with the `gh-stack-link` skill and watch the stack's CI with the `watch-ci` skill. Otherwise, resolve each ticket the way the issue tracker closes work, and report the stack's bookmarks bottom to top. Push nothing the user didn't ask for.

9. If this run created workspaces, list them and ask the user before cleaning them up. On approval, for each one only: `jj workspace forget <name>`, then delete its directory.
