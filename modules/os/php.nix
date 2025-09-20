{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.php;
in {
  options.programs.php = {
    enable = mkEnableOption "PHP development environment";
  };

  config = mkIf cfg.enable {
    homebrew = {
      taps = [
        "shivammathur/php"
      ];

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
    };
  };
}