{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [ ];

  xdg.configFile = {
    "rofi".source = "${sourceRoot}/config/rofi";
  };
}
