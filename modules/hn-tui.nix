{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [ ];

  xdg.configFile = {
    "hn-tui.toml".source = "${sourceRoot}/config/hn-tui.toml";
  };
}
