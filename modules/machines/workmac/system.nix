{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

{
  imports = [
    ../../system/meta/cli-darwin.nix
    ../../system/meta/gui-darwin.nix
  ];

  services.dnsmasq-resolver.enable = true;

  networking = {
    hostName = systemConfig.hostName or "workmac";
    computerName = systemConfig.computerName or "WorkMac";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "none";
    };
    casks = [
      "google-cloud-sdk"
    ];
  };

  # Configure screenshot settings
  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
