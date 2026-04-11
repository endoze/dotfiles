{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    matugen
  ];

  xdg.configFile = {
    "matugen/config.toml".source = "${sourceRoot}/config/matugen/config.toml";
    "matugen/templates" = {
      source = "${sourceRoot}/config/matugen/templates";
      recursive = true;
    };
  };

  xdg.cacheFile."matugen/.keep".text = "";
}
