{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    _1password-cli
  ];

  home.sessionVariables = {
    DEVELOPMENT_MACHINE = "macbook";
  };
}
