{ config, pkgs, lib, userConfig, ... }:

{
  home.stateVersion = "24.05";

  # Disable nix management to avoid conflicts with base image's nix installation
  # The base nixos/nix image already has nix configured properly
  nix.enable = false;


  imports = [
    ../../home/meta/cli.nix
  ];

  services.gpg-agent.enable = lib.mkForce false;

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
