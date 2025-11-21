{ config, pkgs, lib, userConfig, ... }:

{
  home.stateVersion = "24.05";

  imports = [
    ../../home/meta/cli.nix
    ../../home/meta/gui-linux.nix
  ];

  home.packages = with pkgs; [
    ollama-cuda
  ];

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
  };
}
