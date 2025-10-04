{ config, pkgs, lib, ... }:

{
  nixpkgs.config = {
    allowUnsupportedSystem = true;
    allowUnfree = true;
  };

  home.packages = with pkgs; [
    caffeine
    colima
    notion-app
    trash-cli
  ];

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };
}
