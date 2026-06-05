# archimedes - home-manager configuration
{ config, pkgs, lib, userConfig, ... }:

{
  imports = [
    ../../home/meta/cli.nix
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
