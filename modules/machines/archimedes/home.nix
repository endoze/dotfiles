# archimedes - home-manager configuration
{ config, pkgs, lib, userConfig, ... }:

{
  home.stateVersion = "24.05";

  imports = [
    ../../home/meta/cli.nix
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
