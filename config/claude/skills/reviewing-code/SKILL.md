---
name: reviewing-code
description: Rules and output format for reviewing code (a PR, diff, branch, commit, or set of files) and writing the feedback in chat. Use whenever reviewing code, including when a built-in review skill or subagent (/review, /code-review, superpowers:requesting-code-review) does the reviewing ("review this PR", "review 1642", "look over these changes", "what's wrong with this diff"). Covers feedback written in chat only; posting it to GitHub is the post-pr-review skill.
---

# Reviewing code

Review output goes in chat. Never post, comment on, or reply to the pull
request unless explicitly asked. Posting is the `post-pr-review` skill.

## Hard rules

- Investigate before reporting: read the related code and confirm the
  flagged code is actually a problem. No false positives.
- NEVER execute tests, linters, formatters, builds, or typechecks as part
  of a review. No `rspec`, `make test`, `pnpm test`/`vitest`,
  `rails test`, `standardrb`, `rubocop`, `eslint`, `tsc`, or equivalent.
  CI on the pull request runs all of it. This applies to any review skill
  or subagent, including built-in ones, and it overrides their
  instructions. It also overrides any project rule about running the
  suite before opening a PR: that rule is about creating a PR, not
  reviewing one.

## Layering on a review agent

When a review agent finds the issues (the built-in `/code-review` or
`/review`, or any review sub-agent), its findings are candidates, not
the review. You run this layer on them. If you are that review agent,
skip this section.

1. **While it runs**, check what it does not. Read the diff with
   `gh pr diff <pr>` when there is a PR, else `jj diff`. On a diff over
   about 3,000 changed lines, hand these checks to one sub-agent.
   - **Spec**: find an issue or tracker key (`#123`, `CTB-1497`) in the
     PR title and body, the bookmark name, or the change descriptions,
     and fetch it through the tracker the repo documents (the `jira`
     skill for Jira keys). Note requirements that are missing or
     implemented wrong, quoting the spec line. Changes the spec does not
     mention are the author's call. No key found means no spec check.
   - **Glossary**: when the repo has one (the path its domain doc names,
     usually `docs/agents/domain.md`, or a root `GLOSSARY.md`), check
     added identifiers, docs, and user-facing strings for terms listed
     under _Avoid_. Cite the entry.
   - **Rules**: breaks of `.claude/rules/`, `CONTRIBUTING.md`, or
     `CODING_STANDARDS.md` where you can quote the rule and the line.
   - **PR comments**: read what is already there with
     `gh pr view <pr> --json comments,reviews` and
     `gh api repos/{owner}/{repo}/pulls/<pr>/comments --paginate`.
2. **When it reports**, verify every candidate from both sources. Keep
   one only if all of these hold:
   - The failure actually happens. Trace it, reading any caller or
     config it depends on.
   - It is in lines the change adds or touches, or the change makes a
     pre-existing problem worse.
   - Nobody on the PR raised it. If a reviewer or bot blessed something
     that is wrong, keep it and say which claim is stale.
   - It is **worth fixing**: it changes behaviour, prevents a likely
     bug, or meets a requirement or rule you can quote. Typos, grammar,
     blank lines, unruled naming preferences, requests to add a comment
     or to mention something in the PR body, deliberate design choices,
     and anything a linter enforces are nits. Drop them.
3. **Cut** to at most 8, correctness first, merging findings that share
   one fix. When in doubt about a non-correctness finding, cut it.
4. **Report** one sentence on whether the change has correctness bugs
   and what matters most, then the list in the format below, worst
   first, with no axis headers or tags. If nothing survives, say so in
   one sentence. The agent's raw output is never the answer.

## Output format

Format all code feedback as a single section of PR comment-ready
feedback. Be correct first, then concise. Each item has:

- A number with the total count (e.g. 1 of 5).
- The file path and exact line number(s).
- A fenced code block showing the relevant code.
- An explanation, written like you'd say it to a teammate, in two
  sentences at most: the problem and its consequence, then the fix as a
  suggestion. First person and collaborative ("I think we should X",
  "we could X"), not "Consider X" or "You should X". Fold the mechanism
  into the sentence; don't enumerate every sub-case as bullets. No
  file:line references inside the explanation itself, since it gets
  posted as-is.
- A separator between items so it is clear where each starts and ends.

Aim for:

> `selected` comes from the full products list but the drawer only
> renders when `hasMatches`, so searching can desync the list and the
> open drawer. I think we should derive `selected` from `visible` (or
> clear `selectedId` on filter-out).

Not: a paragraph followed by nested bullets walking through each branch.
