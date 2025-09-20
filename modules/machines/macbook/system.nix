{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

{
  imports = [
    ../../os/php.nix
  ];

  networking = {
    hostName = systemConfig.hostName or "macbook";
    computerName = systemConfig.computerName or "MacBook";
  };

  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      # Don't remove anything - leave manually installed packages alone
      cleanup = "none";
    };

    brews = [
      "autoconf"
      "gmp"
      "libyaml"
      "openssl@3"
      "readline"
      "zstd"
    ];

    casks = [
      "sequel-ace"
      "ghostty"
    ];
  };

  # Additional system packages for this machine
  environment.systemPackages = with pkgs; [ ];

  # Configure screenshot settings
  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
