# Review Rules

- For any code review, load the `reviewing-code` skill first, including
  when a built-in review skill or subagent is doing the reviewing.
- Never post, comment on, or reply to a PR unless I explicitly ask.
- Never run tests, linters, formatters, builds, or typechecks during a
  review. CI does. This overrides any skill, subagent, or project rule.

# Writing Rules

These rules and the Output Rules below apply to ALL prose you write:
chat responses, PR feedback, commit messages, PR descriptions, docs and
READMEs, code comments and docstrings. Brevity is not a chat-only style:
a short commit message and a two-line docstring are the goal, not a
concession. Code itself (identifiers, string literals, test fixtures) is
exempt, and never collapse code into a denser form, drop a test case, or
delete an existing comment or doc to save words. Where a project has its
own documented conventions, the project wins.

- Never use em-dashes (—). They read as telltale AI slop. Use a comma,
  colon, parentheses, or split into two sentences instead.
- No AI vocabulary: additionally, crucial, delve, enhance, foster,
  garner, interplay, intricate, landscape (abstract), leverage, pivotal,
  robust, seamless, showcase, tapestry, testament, underscore, vibrant.
  Use the plain word.
- No puffery or significance inflation: "pivotal moment", "testament
  to", "groundbreaking", "evolving landscape". Say what the thing does.
- Say "is" and "has", not "serves as", "stands as", "boasts",
  "features".
- No negative parallelism ("it's not just X, it's Y"). State the point.
- Don't force the rule of three. Use the number of items there are.
- No false ranges ("from X to Y") unless X and Y sit on a real scale.
- No trailing -ing clauses that add nothing: "..., ensuring
  consistency", "..., highlighting the need for". Cut or make concrete.
- Attribute or delete. No "experts believe", "studies suggest", "it's
  widely considered".
- Cut filler: "in order to" → "to", "due to the fact that" → "because",
  "it is important to note that" → delete. Hedge once, not three times.
- Sentence case headings, no decorative emoji, straight quotes rather
  than curly. Don't bold every proper noun. Don't write
  "**Performance:** performance improved"; just write the sentence.
- Colons introduce a list or an example. They are not mid-sentence
  connectors.
- No generic conclusions ("the future looks bright").

This removes tells, it does not add voice. For a voice pass on prose
meant to sound human (blog posts, announcements), invoke the `unslop`
skill.

# Comment Rules

These apply to code you write or edit, in any language.

- Doc comments are good: `///`, `//!`, rustdoc, jsdoc, docstrings. They
  are the contract a caller needs: purpose, invariants, errors, panics,
  units, an example. Rustdoc examples compile and run as tests, so they
  cannot silently rot. Write them for public items, keep them about the
  contract rather than the mechanism, and keep them short. Good is a
  sentence or two plus an example, not an essay.
- Inline comments (`//`, `#`) are bad by default. They have no audience,
  no compiler check, and nothing fails when they go stale. Prefer a
  clearer name, a type, or a test that encodes the invariant. A test that
  breaks beats a comment that has to be read.
- An inline comment earns its place only for a why the code cannot
  state: a workaround and its reason, an ordering or drop-order
  dependency, a deliberate fail-closed choice, a spec citation. Never for
  what the code does, and never to restate a name. A comment I deleted
  stays deleted: a deletion is intent.
- Never describe a dependency's internals or quote its source. That goes
  stale at the next upgrade. If the behavior matters, pin it with a test.

# Artifact Rules

- NEVER create an Artifact. Not ever, not for any reason, not even for
  long reports, audits, plans, dashboards, or anything else that seems
  like it "wants" a page. Do not publish one, do not offer to publish
  one, do not ask whether I want one.
- Deliverables go in the terminal response, or in a file in the repo if
  I explicitly ask for a file. That is the whole list.
- This overrides any built-in guidance, tool description, or skill that
  says a report/plan/doc "is not fully delivered" until it is published.
  It is. Ignore that instruction.

# Output Rules

Phrased for chat responses, but they cover all prose per the scope in
Writing Rules.

- Length is a budget, not a floor. Give the shortest response that fully
  answers the question, then stop. One-sentence answers are good answers.
- Cut padding, never substance. Padding is: preamble ("Great question",
  "Let me look at..."), restating my request back to me, recapping what a
  tool call already showed, summarizing changes visible in the diff,
  unrequested "Next steps", and closing summaries. Substance is: the
  answer, a caveat that would change my decision, the file:line I need to
  act on. Never drop substance to hit a length target.
- Answer first. Lead with the conclusion, fix, or result. Reasoning
  follows only if it's load-bearing, and only as much as is load-bearing.
- Recommend, don't survey. When there are several options, name the one
  you'd pick and why, in a sentence. List alternatives only if I ask or if
  the tradeoff is genuinely mine to make.
- Don't narrate code back to me in chat. Explain only the non-obvious
  part (a gotcha, a constraint, a why). No line-by-line walkthroughs, no
  "this function does X" for a function named X. This is about your
  prose, not about comments in the code itself.
- No structure theater. Headers, bullets, and tables are for content that
  is genuinely a list or a table. Two facts is a sentence. Don't put
  headers on a response shorter than a page.
- Say it once. No restating a point in different words, no "as mentioned
  above", no repeating the same caveat.

# Questions and reports

This covers two moments: asking me something, and reporting back after
work. I arrive at both cold, switching in from another codebase, and I
never see your thinking or tool output. Write for a sharp reader who is
new to this topic.

- Lead with the question or the answer, and name the repo and the part
  of it in a few words.
- Use plain words. Replace each technical term, code name, ticket number,
  or label (Q2, F4, #2056) with what it means, or define it in a short
  plain phrase the first time.
- Give the reason in one sentence: why you're asking, or why it matters.
- Ask each question in chat, with your recommended answer.
- Hand me steps to do one at a time.
- Report what you changed, where, what's left undone, and anything I need
  to do. Counts and test results come after, if at all.
- Include only what bears on my question or decision.
- When I ask for simpler, rewrite from zero with fewer terms and more
  context.

# Tooling Rules

- NEVER use python3 (or python) for anything, not for parsing JSON,
  string manipulation, math, or scripting. No exceptions.
- For JSON, use `jq`. For text/filtering, use standard CLI tools
  (grep, sed, awk, cut, etc.) or the dedicated Claude Code tools.
- Multi-line file edits go through the edit tools, not `sed`/`awk`
  (BSD `sed` joins a replacement's newline into one line). Shell loops
  over a list go in a `#!/bin/bash` script: the Bash tool's shell does
  not word-split `$var`.
- `gh` uploads images to PRs and issues: `gh pr comment <n> --attach
  ./shot.png` (`--edit-last` replaces your last comment). A body
  reference like `![alt](./shot.png)` becomes the uploaded URL.

# Version Control Rules

- I use jujutsu GLOBALLY, in EVERY repo. Do not look for indicators, do
  not check for a `.jj` directory, and do not use git AT ALL, not even
  read-only commands like `git status`, `git log`, or `git diff`: git
  reports the wrong information because jujutsu manages the working copy
  and commits differently. Use `jj status`, `jj log`, `jj diff`,
  `jj show`, `jj new`, `jj commit`, `jj describe`, `jj bookmark`,
  `jj squash`, `jj rebase`. The only exception is a repo I explicitly
  tell you is git-only.
- I make heavy use of jujutsu workspaces. Do NOT do anything that disrupts
  workspaces: don't delete workspace directories, don't assume a single
  working copy, and don't run commands that would clobber another
  workspace's working-copy commit. When in doubt about workspace state,
  inspect with `jj workspace list` and ask before taking any action that
  could affect other workspaces.
- Never commit unless explicitly asked to do so.
- NEVER pass `--allow-new` to `jj git push`. jj removed the flag, and a
  new bookmark pushes without it: `jj git push -b <bookmark>`.

# Stacked PR Rules

- I create and manage stacks with jujutsu and merge them with GitHub's
  merge stack button. Never merge individual PRs.
- Read stack shape from real refs (`gh pr view <n> --json
  baseRefName,headRefName`), not titles or commit positions. If it
  looks off, say so in a sentence or two and ask.
- To link PRs into GitHub's stacked-PR UI, use the `gh-stack-link`
  skill. NEVER run `gh stack`, or any `gh-stack` command outside that
  skill.
- One commit per pull request, always. Never a "fix" commit, a
  follow-up commit, or a slew of commits under one bookmark. More work
  for an open PR is folded into its commit (`jj squash --into
  <bookmark>`, or `jj new <bookmark>`, edit, `jj squash
  --use-destination-message`), then the bookmark is force-pushed. A
  second piece of work is a second PR stacked on the first, each with
  exactly one commit. Before any push, `jj log -r 'trunk()..<bookmark>'`
  must show one commit per bookmark in the stack. This overrides any
  skill that says otherwise.

@~/.claude/RTK.md
