{ config, pkgs, lib, ... }:

{
  nixpkgs.config = {
    allowUnsupportedSystem = true;
    allowUnfree = true;
  };

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };
}
