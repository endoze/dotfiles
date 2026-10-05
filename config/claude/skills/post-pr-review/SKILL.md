---
name: post-pr-review
description: Post code review feedback to a GitHub pull request as inline comments only, or tighten drafted feedback without posting it. Use when asked to post, leave, publish, or push review feedback onto a PR ("post these inline", "leave these comments on the PR", "post this review", "put that feedback on 1522"), or to clean up review feedback against what is already on the PR ("clean up this feedback", "cut the slop from these comments", "/pr-review-pre"). Enforces one inline thread per finding with no summary comment, no headers or "N of M" labels, and a hard per-comment word budget so the author is not buried in text.
---

# Post PR Review Feedback

Post only when explicitly asked. Reviewing a PR does not imply posting it.

## Cleaning up feedback without posting

When asked only to clean up drafted feedback, do Workflow steps 1 to 3, then
rewrite each item by "Writing one comment": cut the fluff, keep the code
fences and the first-person suggestive voice, two sentences of prose at most,
no file:line references in the prose. Output it in the `reviewing-code` skill's format
and stop. Posting is a separate request.

## Hard rules

1. **Confirm before posting.** Show the exact comment bodies and anchors and
   get an explicit go-ahead first. Never post in the same turn as showing
   them. Posting notifies the author, so a mistake cannot be quietly undone.
2. **Never post a summary comment, overview, or review body.** No exceptions,
   not even an empty-bodied review. Every finding is its own inline thread.
3. **Never use `gh pr review` or `POST /pulls/{pr}/reviews`.** Both attach a
   review-level body. Use `POST /pulls/{pr}/comments` (the script does).
4. **No header of any kind on a comment.** No `**1 of 7**`, no `## Finding`,
   no bold label line, no severity tag. The first line is the feedback itself
   or the code block. The comment is already anchored to the code, so a title
   is pure noise.
5. **Concise or it does not ship.** 120 words is the hard ceiling; aim for
   40 to 70. A wall of text does not get read.
6. **No em-dashes.**

## Workflow

1. **Read what is already on the PR** before writing anything:

   ```bash
   gh pr view <pr> --repo <owner/repo> --json comments,reviews
   gh api repos/<owner/repo>/pulls/<pr>/comments --paginate \
     -q '.[] | "\(.user.login) \(.path):\(.line) \(.body[0:80])"'
   ```

   Drop any finding a human reviewer or a review bot already raised. If a bot
   blessed something as fine and it is not fine, that correction is worth a
   comment; say which claim is stale.

2. **Cut the list.** Keep only findings that would change the code. Six to
   eight threads is a lot already. Merge related findings into one comment
   rather than posting two. If a finding is truly minor and the PR is
   otherwise sound, drop it.

3. **Verify each finding** against the surrounding code before posting. A
   false positive costs the author more than a missed nit.

4. **Write the manifest** (see below) and validate it with `--dry-run`. This
   is required, not optional: it catches headers, over-budget bodies, and
   anchors outside the diff before anything is posted.

5. **Get confirmation.** Output the final comment bodies verbatim in chat,
   each with its `path:line` anchor, and flag any anchor that had to move off
   the code it describes. Then stop and wait for an explicit go-ahead. Do not
   post yet.

6. **Post** with the script once approved, then report the resulting anchors
   and comment ids.

## Writing one comment

Structure: optional short code block, then one or two sentences naming the
problem and its consequence, with the fix folded in as a suggestion.

- Code block only when the anchor does not already make the target obvious.
  Four lines maximum.
- First person and collaborative: "I think we should X", "we could X". Never
  "Consider X" or "You should X".
- No bullet lists walking through each sub-case. Fold the mechanism into the
  sentence.
- Name the real line in prose when the anchor had to move.

Good:

```
`selected` comes from the full products list but the drawer only renders when
`hasMatches`, so searching can desync the list and the open drawer. I think we
should derive `selected` from `visible`, or clear `selectedId` on filter-out.
```

Bad: a bolded title, then a paragraph of setup, then nested bullets walking
every branch, then a restatement of the fix.

## Anchoring

Anchors are RIGHT-side (post-change) line numbers and **must fall inside a
diff hunk** or the API rejects them.

- Multi-line anchor: `start_line` plus `line`.
- If the code to flag is not in the diff, anchor on the nearest related
  changed line and name the real line in the body.
- One finding that spans two files stays one comment: anchor the primary
  file, mention the other path in the body. Never split it across threads.

## Posting

Write a manifest, then run the script. Do not hand-roll `gh api` loops: the
interactive shell is fish, so bash function and loop one-liners break, and
inline JSON mangles backticks and newlines.

```bash
# validate first, always
~/.claude/skills/post-pr-review/scripts/post_inline.sh \
  --repo <owner/repo> --pr <n> --manifest <file> --dry-run

# then, only after an explicit go-ahead
~/.claude/skills/post-pr-review/scripts/post_inline.sh \
  --repo <owner/repo> --pr <n> --manifest <file>
```

Manifest is a JSON array, one object per comment:

```json
[
  {
    "path": "app/controllers/foo_controller.rb",
    "start_line": 9,
    "line": 16,
    "body": "This branch isn't rebased on main, where #1516 already split the concern, so `create` lands on the write gate. I think we should authorize `show_event_templates?` explicitly."
  },
  {
    "path": "spec/requests/foo_spec.rb",
    "line": 21,
    "body": "No unit-leader case here, and they're the audience this gate actually affects. I think we should add a `users(:jane_user)` 201."
  }
]
```

Write it with a quoted heredoc (`<<'EOF'`) or `jq -n` so backticks survive.

The script refuses to post anything if a body carries a header or an `N of M`
label, runs over the word budget, or anchors outside the diff, and it fails
loudly if the issue-comment count changes (a leaked summary comment). These
checks are a backstop, not a substitute for the confirmation step.
