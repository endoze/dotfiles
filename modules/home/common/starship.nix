{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    starship
  ];

  xdg.configFile = {
    "starship.toml".source = "${sourceRoot}/config/starship.toml";
  };
}
