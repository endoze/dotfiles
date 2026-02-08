{ config, pkgs, lib, userConfig, ... }:

{
  home.stateVersion = "24.05";

  imports = [
    ../../home/meta/cli.nix
  ];

  home.packages = with pkgs; [
    readline
    readline.dev
    ncurses
    ncurses.dev
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
