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

  # Inter is the UI face for the eww bar, shirase and monban. The greeter runs
  # as its own user before login, so it only sees system fonts; home-manager
  # installing Inter for endoze is not enough for the login screen.
  fonts.packages = [ pkgs.inter ];

  environment.systemPackages = with pkgs; [
    (pkgs.wrapFirefox (pkgs.firefox-unwrapped.override { withPipewire = true; }) { })
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
