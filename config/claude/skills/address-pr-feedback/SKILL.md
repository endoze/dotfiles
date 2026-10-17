---
name: address-pr-feedback
description: Pull review feedback (teammates, CodeRabbit, Copilot) on the user's own pull request or stack of pull requests, verify each item in code, keep only what is valid and actionable, and fix it in the right PR of a jj stack bottom-up. Use when the user says "go get the feedback on this PR", "address the feedback", "what did coderabbit/copilot say", "is this feedback valid", or wants review comments fixed across stacked PRs.
argument-hint: "[pr-number ...]"
---

# Address PR feedback

Jujutsu only, never git. Never comment on, reply to, or resolve anything on the PR unless the user asks.

A pushed fix is the reply. When the fix does what the reviewer asked, the item is handled once it is pushed: it needs no written reply, and resolving the thread needs none either. That includes a reviewer's note that a thread "still needs a reply". Draft a reply only where the fix deviates from the ask, or the code deliberately keeps something nonstandard, and the reply says why.

## 1. Map the stack

Start from the PRs in `$ARGUMENTS`, or the PRs whose bookmarks are in `jj log -r 'trunk()..@'`, then extend to the **whole stack**: down to the PR that targets trunk, and up through every open PR whose base is a branch already in the chain (`gh pr list --base <branch> --state open`). Every PR in the stack is collected and triaged, including ones the user did not name. For each:

```bash
gh pr view <n> --json number,url,baseRefName,headRefName,isDraft
```

Order them bottom to top from the real base/head refs: the bottom PR targets trunk, each PR above targets the branch below. If the chain is broken or ambiguous, stop and ask. Never guess stack shape.

## 2. Collect all feedback

Per PR, get every source: review threads with replies and resolution state, review bodies, and top-level comments.

```bash
gh api graphql -F owner='{owner}' -F repo='{repo}' -F n=<n> -f query='
query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$n){
  reviewThreads(first:100){nodes{isResolved isOutdated path line
    comments(first:50){nodes{author{login} body url}}}}
  reviews(first:100){nodes{author{login} state body}}
  comments(first:100){nodes{author{login} body url}}}}}'
```

Skip resolved threads. Read the user's own replies: they often already accepted, rejected, or deferred an item.

## 3. Verify every item in code

Every claim gets checked against the code at that PR's head (`jj file show -r <bookmark> <path>`, or read the file after `jj new <bookmark>`). Read the referenced lines, then trace callers, types, and tests far enough to prove or disprove it. If it is a behavior claim, reproduce it with a test or a command. A comment that "sounds right" is not verified.

**Copilot is never trusted.** Treat anything from Copilot (any author login containing `copilot`, such as `copilot-pull-request-reviewer`) as wrong until the code proves otherwise. Do not repeat, paraphrase, or act on a Copilot claim you have not confirmed in code yourself. Bot feedback in general (CodeRabbit included) gets the same scrutiny, and so do humans, but Copilot is guilty until proven innocent.

## 4. Report triage, then wait

One short line per item, grouped by PR, bottom to top:

- **Fix**: valid and actionable. Say what the code does wrong and the fix.
- **Skip**: invalid, already handled, or not worth it. Say why, citing the code that disproves it.
- **Ask**: needs the user's call.

Stop and wait for the user to approve the list before changing anything.

## 5. Fix bottom-up, one PR at a time

For each PR with approved fixes, starting at the bottom of the stack:

```bash
jj new <pr-bookmark>                      # empty change on top of the PR
# make the fixes for this PR only, run the relevant tests
jj squash --use-destination-message       # fold them into the PR's commit
jj log -r 'conflicts()'                   # descendants rebase automatically; check them
```

Then move to the next PR up and repeat. A fix belongs in the lowest PR that introduced the code, not on top of the stack and never as a separate "fix" commit. Each PR stays exactly one commit with its bookmark, which moves with the squash. If the rebase leaves a conflict in a PR above, resolve it when you reach that PR, the same way (`jj new <bookmark>`, resolve, `jj squash`).

## 6. Finish

Show `jj log -r 'trunk()..'` and list what was fixed per PR. Leave `@` on the last change you worked in: the user continues from where the work is, so never `jj edit` back to where `@` started.

Do not push. If the user asks to push, push only the stack's bookmarks by name:

```bash
jj git push -b <bookmark-1> -b <bookmark-2> ...
```

A push opens a second round: reviewers (Copilot always) re-review every pushed PR, and CI reruns. Wait for both to finish: watch every PR in the stack with the `watch-ci` skill, which judges each PR on its newest head (a push can cancel an earlier run, which shows red). Then repeat step 2 on every PR in the stack and report what is new. The work is done when every PR's newest CI run passes and no thread is left unverified.
