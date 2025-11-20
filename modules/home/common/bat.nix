{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    bat
  ];

  xdg.configFile = {
    "bat".source = "${sourceRoot}/config/bat";
  };
}
