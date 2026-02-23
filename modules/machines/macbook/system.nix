{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

let
  githubUser = userConfig.username;
  publicKeysFile = builtins.readFile (pkgs.fetchurl {
    url = "https://github.com/${githubUser}.keys";
    sha256 = "M2WlzzEtbO5nMTU/nsfOpCw/ayjsKk25+04lDSE81jE=";
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

  users.users."${userConfig.username}" = {
    openssh.authorizedKeys.keys = publicKeys;
  };

  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
