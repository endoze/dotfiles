{ config, pkgs, lib, userConfig, sourceRoot, systemConfig, ... }:

{
  imports = [
    # Tool modules
    ../bat.nix
    ../fish.nix
    ../ghostty.nix
    ../git.nix
    ../hn-tui.nix
    ../jujutsu.nix
    ../lsd.nix
    ../mise.nix
    ../neovim.nix
    ../selene.nix
    ../shell-ai.nix
    ../starship.nix
    ../tmux.nix
    ../weechat.nix

    # Language modules
    ../ruby.nix

    # Service modules
    ../databases.nix
  ];

  home = {
    username = userConfig.username;
    homeDirectory = userConfig.homeDirectory;

    stateVersion = "24.05";

    packages = with pkgs; [
      chromedriver
      docker
      docker-buildx
      docker-compose
      gitAndTools.delta
      gh-dash
      htop
      imagemagick
      jq
      kubectl
      kubectx
      nerd-fonts.inconsolata-go
      nerd-fonts.jetbrains-mono
      ngrok
      nix-diff
      openssl
      terraform
      tldr
      unar
      unrar
      unzip
      zip
      zsh
    ];
  };

  home.file = {
    ".rustfmt.toml".source = "${sourceRoot}/config/rustfmt.toml";
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less";
  };

  programs = {
    home-manager.enable = true;

    gpg = {
      enable = true;
      settings = {
        use-agent = true;
      };
    };

    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };

  news.display = "silent";
}
