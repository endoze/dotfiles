---
name: handoff
description: Compact the current conversation into a handoff document for another agent to pick up.
argument-hint: "What will the next session be used for?"
disable-model-invocation: true
---

Write a handoff document summarising the current conversation so a fresh agent can continue the work. Save it as `<root>/.scratch/handoffs/HANDOFF-<topic>.md`, where `<root>` is the main checkout, so the file is found from any workspace. `.scratch/` is gitignored globally. Never use OS temp storage: a wipe would delete the handoff before the user is done with it. Use the absolute path.

Resolve `<root>` with this command. A secondary jj workspace's `.jj/repo` is a file pointing at the main checkout's `.jj/repo`, and `jj workspace root --name default` fails in repos whose default workspace has no recorded path:

```sh
r=$(jj workspace root); p="$r/.jj/repo"; if [ -f "$p" ]; then t=$(cat "$p"); case $t in /*) ;; *) t="$r/.jj/$t";; esac; r=$(cd "$t/../.." && pwd); fi; echo "$r"
```

End your reply with a one-sentence prompt the user can paste to resume from the document.

Include a "suggested skills" section in the document, naming which skills the next agent should call the Skill tool for.

Do not duplicate content already captured in other artifacts (specs, plans, ADRs, issues, commits, diffs). Reference them by path or URL instead.

Redact any sensitive information, such as API keys, passwords, or personally identifiable information.

If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.
