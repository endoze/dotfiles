#!/usr/bin/env zsh

set +e
git config user.name > /dev/null 2>&1

GIT_USER_NAME_EXISTS=$?

if [[ $GIT_USER_NAME_EXISTS -eq 1 ]]; then
  if [[ -t 0 ]]; then
    vared -p "What name would you like to use for git? " -c GIT_NAME
    vared -p "What email address would you like to use for git? " -c GIT_EMAIL
  else
    GIT_NAME=${GIT_NAME:-"<change me to your name>"}
    GIT_EMAIL=${GIT_EMAIL:-"<change-me-to-your-email@example.com>"}
    echo "Shell is non-interactive, setting GIT_NAME and GIT_EMAIL in gitconfig from environment"
  fi


cat <<- EOF > ~/.gitconfig
[core]
  excludesfile = ~/.gitignore
  pager = delta
[interactive]
  diffFilter = delta --color-only
[delta]
  navigate = true  # use n and N to move between diff sections
  light = true    # set to true if you're in a terminal w/ a light background color (e.g. the default macOS terminal)
  syntax-theme = braver-solarized-light
  side-by-side = true
  true-color = always
[diff]
  colorMoved = default
[merge]
  summary = true
  conflictstyle = diff3
[color]
  diff = auto
  status = auto
  branch = auto
  interactive = auto
[branch]
  autosetupmerge = true
[push]
  default = current
[pull]
  default = current
[web]
  browser = open
[init]
  templatedir = ~/.git_template
[alias]
  st = status
  ci = commit
  co = checkout
  br = branch
  cleanlocal = "!zsh -c 'BRANCH=\`git current\`; if [[ ! \$BRANCH =~  ^master$ ]];then read \"?Are you sure you want to run while not in master (you run the risk of deleting master)? (y/n) \" choice; if [[ ! \$choice =~ ^[Yy]$ ]]; then echo Nothing done; exit 0; fi ; fi; for stale_branch (\`git branch --merged \$BRANCH | grep -v \$BRANCH\`) git branch -d \$stale_branch'"
  current = !git rev-parse --abbrev-ref HEAD
  some = !git checkout master && git pull --rebase && git remote prune origin && git cleanlocal
[user]
  name = $GIT_NAME
  email = $GIT_EMAIL
EOF
fi
 set -e
