{ config, pkgs, lib, sourceRoot, ... }:

{
  home.packages = with pkgs; [
    sqruff
  ];

  xdg.configFile = {
    "sqruff/config.cfg".source = "${sourceRoot}/config/sqruff/config.cfg";
  };
}
