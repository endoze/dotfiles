function __fish_worktree_branches
  set -l git_common_dir (git rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
  set -l main_root (string replace -r '/\.git$' '' $git_common_dir)
  set -l worktrees_dir "$main_root/.worktrees"

  if test -d "$worktrees_dir"
    for dir in $worktrees_dir/*/
      basename $dir
    end
  end
end

function __fish_worktree_needs_subcommand
  set -l cmd (commandline -opc)

  if test (count $cmd) -eq 1
    return 0
  end

  return 1
end

function __fish_worktree_using_subcommand
  set -l cmd (commandline -opc)

  if test (count $cmd) -ge 2 -a "$cmd[2]" = "$argv[1]"
    return 0
  end

  return 1
end

complete -c worktree -f

complete -c worktree -n __fish_worktree_needs_subcommand -a add -d "Create a new worktree"
complete -c worktree -n __fish_worktree_needs_subcommand -a list -d "List all worktrees"
complete -c worktree -n __fish_worktree_needs_subcommand -a remove -d "Remove a worktree"
complete -c worktree -n __fish_worktree_needs_subcommand -a merged -d "Check if branch is merged into origin/main"

complete -c worktree -n '__fish_worktree_using_subcommand add' -a '(__fish_git_branches)' -d "Branch"
complete -c worktree -n '__fish_worktree_using_subcommand remove' -a '(__fish_worktree_branches)' -d "Worktree"
complete -c worktree -n '__fish_worktree_using_subcommand remove' -s f -l force -d "Force removal"
complete -c worktree -n '__fish_worktree_using_subcommand merged' -a '(__fish_worktree_branches)' -d "Branch"
