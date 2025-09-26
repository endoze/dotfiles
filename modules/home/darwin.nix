{ config, pkgs, lib, ... }:

{
  home.packages = with pkgs; [
    colima
    tableplus
    trash-cli
  ];

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };
}
