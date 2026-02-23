{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

let
  githubUser = userConfig.username;
  publicKeysFile = builtins.readFile (pkgs.fetchurl {
    url = "https://github.com/${githubUser}.keys";
    sha256 = "+75tNZAGfdQdnSPUaak4OtGTeiNqI5duNV5y8rDpiGg=";
  });
  publicKeys = lib.splitString "\n" (lib.removeSuffix "\n" publicKeysFile);
in
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

  users.users."${userConfig.username}" = {
    openssh.authorizedKeys.keys = publicKeys;
  };

  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
