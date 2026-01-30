{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
    gh
    lazygit
  ];

  home.file = {
    ".gitignore".source = "${sourceRoot}/config/gitignore";
  };

  programs.git = {
    enable = true;
    settings = {
      user = {
        email = userConfig.userEmail;
        userName = config.home.username;
      };

      init = {
        defaultBranch = "master";

      };
      pull = {
        rebase = true;
        default = "current";
      };
      push = {
        autoSetupRemote = true;
        default = "current";
      };
      fetch = {
        prune = true;
      };
      core = {
        editor = "nvim";
        excludesFile = "~/.gitignore";
        pager = "delta";
      };
      diff = {
        colorMoved = "default";
      };
      color = {
        diff = "auto";
        status = "auto";
        branch = "auto";
        interactive = "auto";
      };
      web = {
        browser = "open";
      };
      interactive = {
        diffFilter = "delta --color-only";
      };

      alias = {
        st = "status";
        ci = "commit";
        co = "checkout";
        br = "branch";
        sl = "log --oneline --decorate -20";
        sla = "log --oneline --decorate --graph --all -20";
        slap = "log --oneline --decorate --graph --all";
        track = "!git branch --set-upstream-to=origin/$(git current)";
        cleanlocal = "!zsh -c 'BRANCH=`git current`; if [[ ! $BRANCH =~ ^$(git head-branch)$ ]];then read \"?Are you sure you want to run while not in $(git head-branch) (you run the risk of deleting $(git head-branch))? (y/n) \" choice; if [[ ! $choice =~ ^[Yy]$ ]]; then echo Nothing done; exit 0; fi ; fi; for stale_branch (`git branch --merged $BRANCH | grep -v $BRANCH`) git branch -d $stale_branch'";
        current = "symbolic-ref --short HEAD";
        upstream-name = "!git remote | egrep -o '(upstream|origin)' | tail -1";
        remote-head-branch = "!git rev-parse --abbrev-ref $(git upstream-name)/HEAD";
        head-branch = "!git remote-head-branch | sed 's|^.*/||'";
        some = "!git switch $(git head-branch) && git pull --rebase && git remote prune origin && git cleanlocal";
        branches = "for-each-ref --sort=-committerdate --format=\"%(color:blue)%(authordate:relative)\t%(color:red)%(authorname)\t%(color:white)%(color:bold)%(refname:short)\" refs/remotes";
      };
    };

    signing = {
      key = userConfig.gpgKey;
      signByDefault = userConfig.gpgKey != "";
    };
  };

  programs = {
    delta = {
      enable = true;
      options = {
        navigate = true;
        light = false;
        side-by-side = true;
        syntax-theme = "TwoDark"; # Change this to your preferred bat theme
      };
    };
  };
}
