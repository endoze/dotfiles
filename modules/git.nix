{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    git
    git-lfs
    delta
    gh
    lazygit
  ];

  home.file = {
    ".gitignore".source = "${sourceRoot}/config/gitignore";
  };

  programs.git = {
    enable = true;
    userEmail = userConfig.userEmail;
    userName = config.home.username;

    signing = {
      key = userConfig.gpgKey;
      signByDefault = userConfig.gpgKey != "";
    };

    extraConfig = {
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
        current = "!git rev-parse --abbrev-ref HEAD | sed 's|heads/||'";
        upstream-name = "!git remote | egrep -o '(upstream|origin)' | tail -1";
        head-branch = "!git remote show $(git upstream-name) | awk '/HEAD branch/ {print $NF}'";
        some = "!git checkout \"$(git head-branch)\" && git pull --rebase && git remote prune origin && git cleanlocal";
        branches = "for-each-ref --sort=-committerdate --format=\"%(color:blue)%(authordate:relative)%09%(color:red)%(authorname)%09%(color:white)%(color:bold)%(refname:short)\" refs/remotes";
      };

    };

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
