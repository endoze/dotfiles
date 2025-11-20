{ config, pkgs, lib, ... }:

{
  imports = [
    ./dconf.nix
    ./gnome-keyring.nix
    ./hyprland.nix
    ./kitty.nix
    ./rofi.nix
    ./swaync.nix
    ./tokyonight-icon-theme.nix
    ./wallust.nix
    ./waybar.nix
  ];
}
