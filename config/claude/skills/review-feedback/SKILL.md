---
name: review-feedback
description: Walk through code review feedback from earlier in this conversation (/review, /code-review, or the reviewing-code skill) one item at a time, as a discussion only. Use when the user invokes /review-feedback or asks to go through review feedback item by item.
allowed-tools: Read, Grep, Glob, TodoWrite, Bash(jj status:*), Bash(jj diff:*), Bash(jj log:*), Bash(jj show:*), Bash(jj evolog:*), Bash(jj op log:*), Bash(jj file list:*), Bash(jj file show:*), Bash(jj file annotate:*)
---

Guide the user through the code review feedback from the previous `/review` command in this conversation, one item at a time. This is a **discussion only**.

# Hard Rules

- **Do NOT edit, write, or modify any files.** Not even small fixes. This skill is for discussion only.
- **Never run git, and never run a state-changing jj command.** Only the read-only jj commands in `allowed-tools` above. Never commit, restore, new, squash, abandon, etc.
- **Every line number you cite MUST be verified against the file on disk** using the Read tool. Line numbers from diffs, patches, or PR comments are frequently wrong (the diff hunk header is not the file's true line, and later edits shift lines). Always open the file and locate the code by content, then report the actual current line number(s).
- **Rephrase the feedback in plain language.** No jargon. No "consider refactoring to leverage". Just say what's wrong and what to do.
- **Be concise but complete.** Leave nothing important out, but cut every word that doesn't earn its place.
- **When suggesting a code change, show a unified diff** with `-` for removed lines and `+` for added lines. Do not apply the change.

# Process

1. **Gather the feedback items** from the previous `/review` output in this conversation. If you cannot find any review feedback in context, ask the user to paste it.
2. **Number every item 1..N** and build a TodoWrite list with one todo per item so progress is visible.
3. **Verify file locations up front** (or just-in-time per item, your choice): for each item, open the referenced file with Read and find the code being discussed by matching its content. Record the *current* line number(s) on disk. If the code can't be found, say so explicitly and ask the user to clarify.
4. **Present items one at a time, in order**, using the template below. After each item, **stop and wait for the user's response** before moving on. Mark the todo complete once the user has decided what to do with that item.
5. After the last item, give a short summary: which items the user wants to address, which to skip, and which need more thought. Do not start making changes — that's a separate request.

# Per-Item Template

Use this exact shape for every item:

```
[<CURRENT> of <TOTAL>] <short, plain-language title>

File: <relative/path/to/file.ext>:<LINE>   (or :<START>-<END> for a range)

Code on disk:
   <a few lines of real context from the file, with line numbers as shown by Read>

What the reviewer flagged:
   <one or two sentences, plain language, no jargon>

Why it matters:
   <one or two sentences — concrete impact, not abstract principles>

Suggested change:
   <unified diff>
   (or: "No code change — this is a question/note about <X>.")
```

# Notes

- If a feedback item references a file or line that doesn't exist or doesn't match the code described, say so plainly and ask the user how to proceed. Don't guess.
- If two items overlap or are really the same point, call that out and merge them rather than repeating yourself.
- Keep your own commentary out of it unless it helps the user decide. The user is the one making the call on each item.
