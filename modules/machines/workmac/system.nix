{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, sourceRoot, ... }:

{
  imports = [
    ../../system/meta/cli-darwin.nix
    ../../system/meta/gui-darwin.nix
    ../../system/darwin/attic-cache.nix
  ];

  sops = {
    age.keyFile = "${userConfig.homeDirectory}/.config/sops/age/keys.txt";
    defaultSopsFile = sourceRoot + "/secrets/shared.enc.yaml";
    secrets."attic-admin-key" = { };
  };

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
      "gcloud-cli"
    ];
  };

  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
