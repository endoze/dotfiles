function worktree -a branch_name -d "Create a new git worktree in .worktrees subdirectory"
  if test -z "$branch_name"
    echo "Usage: worktree <branch-name>"

    return 1
  end

  if not git rev-parse --is-inside-work-tree &>/dev/null
    echo "Error: Not inside a git repository"

    return 1
  end

  set worktree_path ".worktrees/$branch_name"

  if test -d "$worktree_path"
    echo "Error: Worktree directory '$worktree_path' already exists"

    return 1
  end

  if git show-ref --verify --quiet "refs/heads/$branch_name"
    git worktree add "$worktree_path" "$branch_name"
  else
    git worktree add "$worktree_path" -b "$branch_name"
  end
end
