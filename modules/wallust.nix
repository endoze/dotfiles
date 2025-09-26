{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    wallust
  ];

  xdg.configFile = {
    "wallust/wallust.toml".source = "${sourceRoot}/config/wallust/wallust.toml";
    "wallust/templates" = {
      source = "${sourceRoot}/config/wallust/templates";
      recursive = true;
    };
  };

  # Create cache directory for wallust output
  xdg.cacheFile."wallust/.keep".text = "";
}