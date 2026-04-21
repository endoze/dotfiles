{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, sourceRoot, ... }:

{
  imports = [
    ../../system/meta/cli-darwin.nix
    ../../system/meta/gui-darwin.nix
  ];

  sops = {
    age.keyFile = "${userConfig.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = sourceRoot + "/secrets/shared.enc.yaml";
    secrets."attic-admin-key" = { };
  };

  services.dnsmasq-resolver.enable = true;

  networking = {
    hostName = systemConfig.hostName or "macbook";
    computerName = systemConfig.computerName or "MacBook";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
    };
  };

  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
