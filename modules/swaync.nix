{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [ ];

  xdg.configFile = {
    "swaync".source = "${sourceRoot}/config/swaync";
  };
}
