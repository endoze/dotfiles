{ config, pkgs, lib, inputs, ... }:

{
  home.packages = [
    inputs.matcha.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
