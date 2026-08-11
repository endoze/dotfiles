{ config, pkgs, lib, userConfig, ... }:

{
  # Disable nix management to avoid conflicts with base image's nix installation
  # The base nixos/nix image already has nix configured properly
  nix.enable = false;


  imports = [
    ../../home/meta/cli.nix
  ];

  services.gpg-agent.enable = lib.mkForce false;

  # The container has no use for a coding agent, and its settings.json symlink
  # would dangle since the dotfiles checkout isn't present at runtime.
  programs.pi-coding-agent.enable = lib.mkForce false;

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
