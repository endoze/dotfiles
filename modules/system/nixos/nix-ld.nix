# nix-ld - Dynamic library shim for running unpatched binaries
{ config, pkgs, lib, ... }:

{
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      readline.dev
      readline
      ncurses.dev
      ncurses
      icu
      openssl
      krb5
      curl
      libffi
      libyaml
      gdbm
      sqlite
      bzip2
      xz
      expat
      libxcrypt
      gmp
      libGL
      glib
      libxml2
      libxslt
      unixODBC
    ];
  };
}
