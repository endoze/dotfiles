{ config, pkgs, lib, ... }:

{
  imports = [
    ../nixos/bluetooth.nix
    ../nixos/docker.nix
    ../nixos/hyprland.nix
    ../nixos/nvidia.nix
    ../nixos/pipewire.nix
    ../nixos/steam.nix
  ];

  environment.systemPackages = with pkgs; [
    (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
    (pkgs.callPackage ../nixos/sddm-theme.nix { })
    cliphist
    adwaita-icon-theme
    file-roller
    kdePackages.gwenview
    hyprpaper
    hyprshot
    kitty
    nwg-look
    obs-studio
    qt5.qtwayland
    qt6.qtwayland
    qt6.qt5compat
    qt6.qtdeclarative
    rofi
    slack
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

    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-volman
      ];
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
}
