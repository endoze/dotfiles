{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [ ];

  xdg.configFile = {
    "kitty".source = "${sourceRoot}/config/kitty";
  };
}
