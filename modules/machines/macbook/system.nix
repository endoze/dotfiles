{ config, pkgs, lib, userConfig ? { }, systemConfig ? { }, ... }:

{
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
      "automake"
      "bison"
      "bzip2"
      "composer"
      "jpeg"
      "freetype"
      "gd"
      "gettext"
      "gmp"
      "icu4c"
      "krb5"
      "libedit"
      "libiconv"
      "libjpeg"
      "libpng"
      "libxml2"
      "libyaml"
      "libzip"
      "mhash"
      "openssl@3"
      "pkg-config"
      "re2c"
      "readline"
      "zlib"
      "zstd"
    ];

    casks = [
      "sequel-ace"
      "ghostty"
    ];

    taps = [
      "shivammathur/php"
    ];
  };

  # Additional system packages for this machine
  environment.systemPackages = with pkgs; [ ];

  # Configure screenshot settings
  system.defaults = {
    screencapture.location = "~/Pictures/screenshots";
  };
}
