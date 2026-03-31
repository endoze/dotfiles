{ config, pkgs, lib, ... }:

let
  policies = import ../common/chromium-policies.nix;
in
{
  environment.etc."chromium/policies/managed/policies.json".text = builtins.toJSON policies;
}
