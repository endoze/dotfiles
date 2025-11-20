{ config, pkgs, lib, ... }:

{
  imports = [
    ../darwin/php.nix
  ];

  environment.systemPackages = with pkgs; [
    coreutils
    curl
    fish
    vim
  ];

  homebrew.brews = [
    "autoconf"
    "gettext"
    "gmp"
    "jpeg-turbo"
    "libnghttp2"
    "libyaml"
    "openssl@3"
    "pkgconf"
    "readline"
    "zstd"
  ];
}
