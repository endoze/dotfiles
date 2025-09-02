{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    _1password-cli
  ];

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
