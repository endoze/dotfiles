{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [
    fastfetch
  ];

  xdg.configFile = {
    "fastfetch".source = "${sourceRoot}/config/fastfetch";
  };
}