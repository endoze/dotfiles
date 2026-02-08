{ config, pkgs, lib, ... }:

{
  imports = [
    ../nixos/bluetooth.nix
    ../nixos/docker.nix
    ../nixos/hyprland.nix
    ../nixos/steam.nix
    ../nixos/tailscale.nix
  ];

  environment.systemPackages = with pkgs; [
    (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
    (pkgs.callPackage ../nixos/sddm-theme.nix { })
    cliphist
    adwaita-icon-theme
    file-roller
    gvfs
    kdePackages.gwenview
    hyprpaper
    hyprshot
    kitty
    nautilus
    nwg-look
    obs-studio
    qt5.qtwayland
    qt6.qtwayland
    qt6.qt5compat
    qt6.qtdeclarative
    rofi
    slack
    sushi
    swaynotificationcenter
    waybar
    wl-clipboard
    protontricks
  ];

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };

    xfconf.enable = true;

    nix-ld = {
      enable = true;
      libraries = with pkgs; [
        stdenv.cc.cc.lib
        zlib
        readline.dev
        readline
        ncurses.dev
        ncurses
        icu
        openssl
        krb5
        curl
      ];
    };
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-wlr
        xdg-desktop-portal-gtk
      ];
    };
  };

  services.flatpak.enable = true;
  services.udisks2.enable = true;
}
