{ config, pkgs, lib, ... }:

let
  version = "0.28.2";

  sources = {
    aarch64-darwin = {
      url = "https://github.com/max-sixty/worktrunk/releases/download/v${version}/worktrunk-aarch64-apple-darwin.tar.xz";
      hash = "sha256-AV+SrBwzkXVigVCElKha3dP/VmQ+zsuzAtqY9l0e/0g=";
    };
    x86_64-linux = {
      url = "https://github.com/max-sixty/worktrunk/releases/download/v${version}/worktrunk-x86_64-unknown-linux-musl.tar.xz";
      hash = "sha256-DCLwV1jRzBwdJKzpN0yz5IPE2bODCD2Y1x6HxuVb5E0=";
    };
  };

  src = sources.${pkgs.stdenv.hostPlatform.system};

  worktrunk = pkgs.stdenv.mkDerivation {
    pname = "worktrunk";
    inherit version;

    src = pkgs.fetchurl {
      inherit (src) url hash;
    };

    nativeBuildInputs = [ pkgs.xz ];
    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/bin
      cp worktrunk-*/wt $out/bin/
    '';
  };
in
{
  home.packages = [ worktrunk ];
}
