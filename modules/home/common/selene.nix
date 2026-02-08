{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    selene
  ];

  xdg.configFile = {
    "selene".source = "${sourceRoot}/config/selene";
  };
}