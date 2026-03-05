# buildFHSEnv for compiling language toolchains via mise on NixOS
#
# Usage:
#   nix develop ~/.dotfiles#mise-compile   # interactive shell
#   nix run ~/.dotfiles#mise-compile       # one-shot mise install
{ pkgs }:

let
  fhsEnv = pkgs.buildFHSEnv {
    name = "mise-compile";

    extraOutputsToInstall = [ "dev" ];

    targetPkgs = pkgs: with pkgs; [
      # Core toolchain
      gcc
      gnumake
      autoconf
      automake
      pkg-config
      patch
      perl

      # Shared libraries (with .dev for headers)
      zlib
      zlib.dev
      openssl
      openssl.dev
      readline
      readline.dev
      ncurses
      ncurses.dev
      curl
      curl.dev
      libxml2
      libxml2.dev
      libxslt
      libxslt.dev

      # Erlang
      gnum4
      wxGTK32
      mesa
      libGL
      libGLU
      unixODBC

      # General utilities
      git
      wget
      cacert
      which
      file
      mise
      bash
    ];

    profile = ''
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      export MISE_DATA_DIR="$HOME/.local/share/mise"
    '';
  };
in
{
  shell = fhsEnv.env;
  package = pkgs.writeShellScriptBin "mise-compile" ''
    exec ${fhsEnv}/bin/mise-compile -c "mise install && exit"
  '';
}
