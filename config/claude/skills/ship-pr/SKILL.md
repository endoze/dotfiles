---
name: ship-pr
description: Push a jj bookmark (committing and bookmarking uncommitted work first) and open its pull request, or update the one already open, then reply with the link and watch CI. Use when the user says "push this up and open a PR", "squash and push", "push the bookmark", "open a pull request", or "give me a link to the PR".
argument-hint: "[bookmark]"
---

# Ship a PR

Push one bookmark with jujutsu and hand back its pull request link. Never use git.

1. Pick the bookmark: the one the user named, else the one on `@-` or `@`
   (`jj log -r 'trunk()..@' -T 'bookmarks ++ " " ++ description.first_line() ++ "\n"'`).
   - None, and `@` has changes: commit them with the `commit` skill and
     `bookmark`, then use the new bookmark.
   - None and nothing to commit, or several fit: ask which.
2. Fold any work in `@` that belongs to this PR into its commit
   (`jj squash --into <bookmark>`, keeping the bookmark's message).
3. Check the shape: `jj log -r 'trunk()..<bookmark>'` shows exactly one
   commit per bookmark, none conflicted. Squash extras into the bookmark's
   commit. A conflict goes to the `jj-resolve-conflicts` skill first.
4. Push only this bookmark: `jj git push -b <bookmark>`.
5. Find its PR: `gh pr view <bookmark> --json url,state`.
   - Open PR: it now carries the push. Go to step 6.
   - No PR: base it on the bookmark below in the stack, else trunk. Write
     the body with the `pr` skill, then
     `gh pr create --base <base> --head <bookmark> --title "<commit subject>" --body-file <file>`.
     A PR based on another PR's bookmark gets linked with the
     `gh-stack-link` skill.
6. Post what the PR does in a few plain words and its link, then watch its
   checks with the `watch-ci` skill.
7. Reply with the CI verdict (for red, the failing check and its link) and
   the next step on the last line.

Local checks belong to CI. Run tests or linters first only when the repo's
instructions require them and the user has not said to skip them.
