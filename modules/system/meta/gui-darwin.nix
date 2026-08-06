{ config, pkgs, lib, ... }:

{
  imports = [
    ../darwin/chromium.nix
  ];

  homebrew.brews = [
    "libvips"
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
