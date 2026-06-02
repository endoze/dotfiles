{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../nixos/bluetooth.nix
    ../nixos/docker.nix
    ../nixos/hyprland.nix
    ../nixos/steam.nix
    ../nixos/tailscale.nix
    ../nixos/chromium.nix
    ../nixos/nix-ld.nix
  ];

  environment.systemPackages = with pkgs; [
    (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { pipewireSupport = true; }) { })
    cliphist
    adwaita-icon-theme
    file-roller
    gvfs
    kdePackages.gwenview
    awww
    mpvpaper
    hyprshot
    kitty
    nautilus
    nwg-look
    obs-studio
    slack
    sushi
    wl-clipboard
    protontricks
    crosspipe
  ];

  programs = {
    appimage = {
      enable = true;
      binfmt = true;
    };

    gamescope = {
      enable = true;
      capSysNice = true;
    };

    xfconf.enable = true;
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        # xdg-desktop-portal-hyprland is added automatically by programs.hyprland;
        # xdg-desktop-portal-wlr is removed — it claims the same interfaces
        # (screencopy/screencast) and causes Discord/Chrome/OBS to pick wrong portal.
        xdg-desktop-portal-gtk
      ];
      # Explicit routing prevents ambiguity when multiple portals are present.
      # hyprland handles screencopy/screencast; gtk handles everything else.
      config.common.default = "*";
      config.hyprland = {
        default = [ "hyprland" "gtk" ];
      };
    };
  };

  services.flatpak.enable = true;
  services.udisks2.enable = true;
}
