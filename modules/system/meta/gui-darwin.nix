{ config, pkgs, lib, ... }:

{
  imports = [
    ../darwin/chromium.nix
  ];

  homebrew.casks = [
    "alfred"
    "claude"
    "eloston-chromium"
    "ghostty"
    "karabiner-elements"
    "orbstack"
    "postico"
    "sequel-ace"
    "sizeup"
    "tailscale-app"
  ];
}
