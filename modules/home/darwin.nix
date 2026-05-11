{ config, pkgs, lib, ... }:

{
  imports = [
    ./darwin/attic-cache.nix
  ];

  nixpkgs.config = {
    allowUnsupportedSystem = true;
    allowUnfree = true;
  };

  home.packages = [ pkgs.pinentry_mac ];

  services.gpg-agent = {
    enable = true;
    pinentry.package = pkgs.pinentry_mac;
  };
}
