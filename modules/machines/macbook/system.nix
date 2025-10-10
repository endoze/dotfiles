{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

{
  imports = [
    ../../os/php.nix
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
      # Don't remove anything - leave manually installed packages alone
      cleanup = "none";
    };

    brews = [
      "autoconf"
      "gettext"
      "gmp"
      "jpeg-turbo"
      "libnghttp2"
      "libyaml"
      "libyaml"
      "openssl@3"
      "pkgconf"
      "readline"
      "zstd"
    ];

    casks = [
      "alfred"
      "ghostty"
      "orbstack"
      "postico"
      "sequel-ace"
      "sizeup"
    ];
  };

  # Additional system packages for this machine
  environment.systemPackages = with pkgs; [ ];

  # Configure screenshot settings
  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
