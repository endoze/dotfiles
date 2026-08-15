---
name: suggest-commit
description: Suggest a conventional commit message for staged/pending changes. Use when the user asks to suggest, draft, or write a commit message, or when they invoke /skill:suggest-commit. Analyzes diffs to generate commit messages focused on WHY the change was made, not WHAT changed.
---

# Suggest Commit

Generate conventional commit messages that focus on the reasoning behind changes.

## Workflow

### 1. Get the Diff

**For Jujutsu:**
```bash
jj diff
```

**For Git:**
```bash
git diff --cached
```

If the Git staged diff is empty, check for unstaged changes with `git diff` and inform the user they need to stage changes first.

### 2. Get Recent Commit Messages

Review recent commits to match the repository's style:

**For Git:**
```bash
git log --oneline -10
```

### 3. Generate the Commit Message

Follow conventional commit format:

```
<type>(<scope>): <subject>

<body>
```

**Types:** feat, fix, docs, style, refactor, perf, test, build, ci, chore

**Rules:**
- Subject line: imperative mood, lowercase, no period, max 50 chars
- Body: wrap at 72 chars, explain WHY not WHAT
- Scope: optional, indicates area of codebase affected
- Do NOT include `Co-Authored-By` or any attribution
- Do NOT use markdown formatting (no backticks, bold, etc.)
- Do NOT use labels like `Title:` or `Body:`
- Output ONLY the commit message text, nothing else

**Focus on WHY:**
The diff already shows WHAT changed. The commit message should explain:
- Why was this change necessary?
- What problem does it solve?
- What motivated this approach?

### 4. Present the Message

Output the suggested commit message as plain text. Do not wrap it in code blocks or add any commentary before or after.

## Examples

**Good commit message:**
```
feat(auth): add session timeout handling

Users were getting unexpectedly logged out without warning when their
session expired. This adds a warning modal 5 minutes before expiration
and allows extending the session without losing work.
```

**Bad commit message (focuses on WHAT):**
```
feat(auth): add SessionTimeoutModal component and useSessionTimeout hook

Added a new modal component that displays when session is about to
expire. Also added a custom hook to track session expiration time.
```

The good example explains the user problem and solution. The bad example just describes the code changes, which are already visible in the diff.
