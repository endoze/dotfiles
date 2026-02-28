function worktree -d "Manage git worktrees in .worktrees subdirectory"
  if test (count $argv) -lt 1
    echo "Usage: worktree <subcommand> [args]"
    echo ""
    echo "Subcommands:"
    echo "  add <branch> [base]   Create a new worktree"
    echo "  list                  List all worktrees"
    echo "  remove <name> [-f]    Remove a worktree"
    echo "  merged <branch>       Check if branch is merged into origin/main"
    echo ""
    echo "Other subcommands are passed through to git worktree."

    return 1
  end

  if not git rev-parse --is-inside-work-tree &>/dev/null
    echo "Error: Not inside a git repository"

    return 1
  end

  set -l git_common_dir (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  set -l main_root (string replace -r '/\.git$' '' $git_common_dir)
  set -l worktrees_dir "$main_root/.worktrees"

  set -l subcommand $argv[1]
  set -l args $argv[2..]

  switch $subcommand
    case add
      set -l branch_name $args[1]
      set -l base_branch $args[2]

      if test -z "$branch_name"
        echo "Usage: worktree add <branch-name> [base-branch]"

        return 1
      end

      set -l worktree_path "$worktrees_dir/$branch_name"

      if test -d "$worktree_path"
        echo "Error: Worktree directory '$worktree_path' already exists"

        return 1
      end

      if git show-ref --verify --quiet "refs/heads/$branch_name"
        git worktree add "$worktree_path" "$branch_name"
      else
        if test -n "$base_branch"
          git worktree add "$worktree_path" -b "$branch_name" "$base_branch"
        else
          git worktree add "$worktree_path" -b "$branch_name"
        end
      end

    case list
      git worktree list $args | string replace (dirname $main_root)"/" ""

    case remove
      set -l force false
      set -l name ""

      for arg in $args
        switch $arg
          case --force -f
            set force true
          case '*'
            set name $arg
        end
      end

      if test -z "$name"
        echo "Usage: worktree remove <name> [--force]"

        return 1
      end

      set -l worktree_path "$worktrees_dir/$name"

      if not test -d "$worktree_path"
        echo "Error: Worktree '$name' not found in $worktrees_dir"

        return 1
      end

      if test $force = true
        git worktree remove --force "$worktree_path"
      else
        git worktree remove "$worktree_path"
      end

    case merged
      set -l branch_name $args[1]

      if test -z "$branch_name"
        echo "Usage: worktree merged <branch>"

        return 1
      end

      git fetch origin main &>/dev/null

      set -l unmerged (git cherry origin/main $branch_name 2>/dev/null)

      if test $status -ne 0
        echo "Error: Could not compare '$branch_name' with origin/main"

        return 1
      end

      if test -z "$unmerged"
        echo "Merged"
      else
        echo "Not merged"
      end

    case '*'
      git worktree $subcommand $args
  end
end
