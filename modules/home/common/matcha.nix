{ config, pkgs, lib, inputs, ... }:

let
  matcha = inputs.matcha.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (old: {
    goModules = old.goModules.overrideAttrs (_: {
      outputHash = "sha256-WSDtL16by/nDYdkmYbLrmNsWG3G5lvYe9IF6osi9U7E=";
    });
  });
in
{
  home.packages = [ matcha ];
}
