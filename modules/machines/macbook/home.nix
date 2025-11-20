{ config, pkgs, lib, ... }:

{
  imports = [
    ../../home/meta/cli.nix
    ../../home/meta/gui-darwin.nix
  ];

  home.packages = with pkgs; [ ];

  home.sessionVariables = {
    DEVELOPMENT_MACHINE = "macbook";
  };

  programs.mysql = {
    enable = true;
    runAtLoad = true;
  };
  programs.redis = {
    enable = true;
    runAtLoad = true;
  };
  programs.rabbitmq = {
    enable = true;
    runAtLoad = true;
  };
  programs.postgres = {
    enable = true;
    runAtLoad = true;
  };
}
