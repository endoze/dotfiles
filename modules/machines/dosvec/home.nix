{ config, pkgs, lib, userConfig, ... }:

{
  imports = [
    ../../home/meta/cli.nix
  ];

  services.gpg-agent = {
    pinentry.package = lib.mkForce pkgs.pinentry-curses;
    defaultCacheTtl = 86400;
    maxCacheTtl = 86400;
  };

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
