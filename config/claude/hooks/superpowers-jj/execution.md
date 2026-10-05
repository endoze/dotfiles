Bookkeeping while executing a plan:

- The plan's `## Status` is the single record a fresh agent resumes from. `.superpowers/sdd/<plan>/progress.md` may hold scratch (briefs, review files, fix-round lines), but done/in progress/next/left, rulings, deferred minors and out-of-scope findings all go in the plan. Never leave state only in progress.md.
- Before starting a task, record its base id under In progress. After its review passes, move it to Done with evidence and set Next. Tick plan checkboxes only after verification.
- Implementers never commit and never edit the plan or Status; the controller owns both. Say so in every implementer dispatch, because the implementer prompt tells it to commit.
- If the plan has no Status/Rules/Resume sections, add them before Task 1.
- At the end, keep the plan and the workspace. Do not run the merge, PR, push or discard options of finishing-a-development-branch; report final Status and stop.
- When the user asks for a prompt to pick up where we left off: update Status first, then reply with one sentence naming the plan file, for example "Resume `docs/superpowers/plans/<file>.md` from its Status section." Add the execution mode only if it is not in the plan's Rules. Nothing else; state belongs in the plan.
