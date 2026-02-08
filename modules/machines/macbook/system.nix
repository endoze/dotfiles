{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

{
  imports = [
    ../../system/meta/cli-darwin.nix
    ../../system/meta/gui-darwin.nix
  ];

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

  # Configure screenshot settings
  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
