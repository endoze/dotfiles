{ config, pkgs, lib, ... }:

{
  imports = [
    ../../home/meta/cli.nix
    ../../home/meta/gui-darwin.nix
  ];

  home.packages = with pkgs; [
    actionlint
    aria2
    jira-cli-go
    kubernetes-helm
    lazydocker
    nixd
    playwright-test
    shellcheck
    sonarqube-cli
    xcodegen
    zed-editor
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
