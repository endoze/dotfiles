{ config, pkgs, lib, ... }:

{
  imports = [
    ../../home/meta/cli.nix
    ../../home/meta/gui-darwin.nix
  ];

  home.packages = with pkgs; [
    actionlint
    aria2
    kubernetes-helm
    lazydocker
    playwright-test
    shellcheck
  ];

  programs.mysql = {
    enable = false;
    runAtLoad = false;
  };
  programs.redis = {
    enable = false;
    runAtLoad = false;
  };
  programs.rabbitmq = {
    enable = false;
    runAtLoad = false;
  };
  programs.postgres = {
    enable = false;
    runAtLoad = false;
  };
}
