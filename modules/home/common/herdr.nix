{ config, pkgs, lib, inputs, ... }:

{
  home.packages = [
    inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];
}
