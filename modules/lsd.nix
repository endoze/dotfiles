{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    lsd
  ];

  xdg.configFile = {
    "lsd".source = "${sourceRoot}/config/lsd";
  };
}