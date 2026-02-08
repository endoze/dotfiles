{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [ ];

  xdg.configFile = {
    "waybar".source = "${sourceRoot}/config/waybar";
  };
}
