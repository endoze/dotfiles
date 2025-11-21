{ config, pkgs, lib, userConfig, ... }:

{
  home.stateVersion = "24.05";

  imports = [
    ../../home/meta/cli.nix
  ];

  services.gpg-agent.enable = lib.mkForce false;

  xdg = {
    enable = true;
    userDirs = {
      enable = true;
      createDirectories = true;
    };
  };
}
