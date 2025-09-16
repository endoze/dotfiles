{ config, pkgs, lib, userConfig, sourceRoot, systemConfig, ... }:

{
  imports = [
    # Tool modules
    ../bat.nix
    ../fish.nix
    ../ghostty.nix
    ../git.nix
    ../lsd.nix
    ../mise.nix
    ../neovim.nix
    ../selene.nix
    ../shell-ai.nix
    ../starship.nix
    ../tmux.nix

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
      # Core utilities
      fzf
      jq
      tldr

      # Development tools
      chromedriver
      deno
      docker
      docker-buildx
      docker-compose
      dotnet-sdk
      google-cloud-sdk
      ktlint
      kubectl
      terraform

      # Security
      openssl

      # Networking
      dnsmasq
      ngrok

      # Image processing
      imagemagick

      # Fonts
      nerd-fonts.inconsolata-go
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

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };

  news.display = "silent";
}
