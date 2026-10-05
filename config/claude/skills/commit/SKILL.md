---
name: commit
description: Draft a conventional commit message for the jujutsu working copy and commit it, or stop at the draft when only a suggestion was asked for, optionally setting a conventional bookmark. Use when the user invokes /commit, asks to suggest, draft, or write a commit message, or says "jj diff, /suggest-commit, jj commit", "commit this", or "commit and set a bookmark".
argument-hint: "[suggest] [bookmark] [ticket-id] [paths...]"
---

# Commit

Commit the working copy (`@`) with jujutsu. Never use git.

## Workflow

1. Run `jj status` and `jj diff`. If `@` has no changes, say so and stop.
   Read recent subjects to match the repo's style:
   `jj log -r '::@-' -n 10 --no-graph -T 'description.first_line() ++ "\n"'`.
   Then check whether `@-` already carries a bookmark ahead of trunk
   (`jj log -r 'trunk()..@-' -T 'bookmarks ++ " " ++ description.first_line() ++ "\n"'`).
   A pull request is exactly one commit, so:
   - If `@-` has a bookmark and the user did not ask for a new bookmark,
     this work belongs to that PR. Fold it in instead of committing:
     `jj squash --into @-`, then rewrite `@-`'s message with
     `jj describe -r @-` only if the new work changes what it says.
     Skip steps 4 and 5.
   - If the user asked for a new bookmark, the work is a new PR stacked
     on `@-`: commit and bookmark it as in steps 4 and 5.
2. Draft the message by the rules under Message.
3. If the user only asked for a suggestion (`suggest` in `$ARGUMENTS`, or
   "suggest/draft/write a commit message"), output the message as plain text,
   with no code block and no commentary, and stop.
4. Commit without asking for approval:

   ```bash
   jj commit -m "$(cat <<'EOF'
   <message>
   EOF
   )"
   ```

   If the user named paths, pass them after the message so only those are
   committed.
5. If `$ARGUMENTS` includes `bookmark` or the user asked for a bookmark, set
   one on the new commit (`@-` after `jj commit`):

   ```bash
   jj bookmark create <type>/<slug> -r @-
   ```

   `<type>` is the commit's conventional type. `<slug>` is a short kebab-case
   summary of the subject, prefixed with a lowercased ticket id if one was
   given or is in the bookmark/branch context (for example
   `feat/ctb-1209-combine-switchers`, `ci/sonar-scan-coverage`). If `@-`
   already carries a bookmark, leave it alone and say so.
6. Run `jj log -r '@-'` and report the commit's subject, its change id, and
   the bookmark if one was set. Nothing else.

## Message

```
<type>(<scope>): <subject>

<body>
```

- Types: feat, fix, docs, style, refactor, perf, test, build, ci, chore.
  Scope is optional and names the area of the codebase.
- Subject: imperative mood, lowercase, no period, 50 characters at most.
- Body: why the change was needed, not what changed; the diff already shows
  that. One paragraph, two at most, wrapped at 72. Skip it if the subject
  says it all.
- Plain text only: no markdown, no `Title:` or `Body:` labels.

Good, because it names the problem:

```
feat(auth): add session timeout handling

Users were logged out without warning when their session expired. This
warns them five minutes ahead and lets them extend the session without
losing work.
```

Bad, because it restates the diff:

```
feat(auth): add SessionTimeoutModal component and useSessionTimeout hook
```
## Rules

- Do not push.
- Do not describe or touch any revision other than `@`, except `@-` when
  folding work into its PR's commit (step 1).
- Never leave two commits under one bookmark: one commit per PR, never a
  "fix" or follow-up commit.
- No attribution trailers.
