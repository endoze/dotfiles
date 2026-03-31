{ config, pkgs, lib, ... }:

let
  policies = import ../common/chromium-policies.nix;
in
{
  system.defaults.CustomUserPreferences."org.chromium.Chromium" = policies;
}
