function reviewpr -d "Fetch a PR branch and start a Claude /review session for it"
  if test (count $argv) -ne 1
    echo "Usage: reviewpr <branch-name>"
    echo ""
    echo "Looks up the open PR for <branch-name> in the current repo,"
    echo "fetches origin, checks out the branch, and starts 'claude /review <pr>'."
    return 1
  end

  # Accept either "my-branch" or "origin/my-branch"
  set -l branch (string replace -r '^origin/' '' $argv[1])

  # Fail fast: resolve the PR number from the branch in this repo (gh
  # auto-detects the repo from the origin remote). Abort before touching
  # jj state if there is no open PR.
  set -l pr (gh pr view "$branch" --json number --jq .number 2>/dev/null)

  if test -z "$pr"
    echo "Error: No open PR found for branch '$branch' in this repository"
    return 1
  end

  echo "Reviewing PR #$pr ($branch)"

  if not jj git fetch
    return 1
  end

  if not jj new "$branch@origin"
    return 1
  end

  claude --permission-mode auto "/review $pr"
end
