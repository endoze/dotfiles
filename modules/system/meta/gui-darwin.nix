{ config, pkgs, lib, ... }:

{
  homebrew.casks = [
    "alfred"
    "claude"
    "ghostty"
    "karabiner-elements@beta"
    "orbstack"
    "postico"
    "sequel-ace"
    "sizeup"
    "tailscale-app"
  ];
}
