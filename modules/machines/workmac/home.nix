{ config, pkgs, lib, ... }:

{
  imports = [
    ../../home/meta/cli.nix
    ../../home/meta/gui-darwin.nix
  ];

  home.packages = with pkgs; [
    aria2
    beads
    kubernetes-helm
    postgresql
    shellcheck
    xcodes
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
