{ config, pkgs, lib, ... }:

{
  imports = [
    ../darwin/chromium.nix
  ];

  homebrew.casks = [
    "alfred"
    "chromedriver"
    "claude"
    "ungoogled-chromium"
    "ghostty"
    "karabiner-elements"
    "orbstack"
    "postico"
    "sequel-ace"
    "sizeup"
    "tailscale-app"
  ];
}
