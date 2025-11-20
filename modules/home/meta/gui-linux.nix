{ config, pkgs, lib, ... }:

{
  imports = [
    ../common/firefox.nix
    ../common/ghostty.nix
    ../common/databases.nix
    ../linux/dconf.nix
    ../linux/gnome-keyring.nix
    ../linux/hyprland.nix
    ../linux/kitty.nix
    ../linux/rofi.nix
    ../linux/swaync.nix
    ../linux/tokyonight-icon-theme.nix
    ../linux/wallust.nix
    ../linux/waybar.nix
  ];

  home.packages = with pkgs; [
    nerd-fonts.inconsolata-go
    nerd-fonts.jetbrains-mono
    ghostty
    gimp
    libnotify
    lyrebird
    lutris
    montserrat
    networkmanagerapplet
    playerctl
    r2modman
    slurp
    discord
    wf-recorder
    xdg-utils
    youtube-music
  ];

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-decoration-layout = "menu:";
    gtk4.extraConfig.gtk-decoration-layout = "menu:";

    iconTheme = {
      name = "Tokyonight-Light";
      package = pkgs.dracula-icon-theme;
    };

    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };
  };

  xdg.userDirs = {
    templates = null;
    publicShare = null;
  };
}
