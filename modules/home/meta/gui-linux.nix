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
    ../linux/shirase.nix
    ../linux/swayosd.nix
    ../linux/tokyonight-icon-theme.nix
    ../linux/wallust.nix
    ../linux/eww.nix
    ../linux/hyprpaper.nix
    ../linux/cliphist.nix
    ../linux/nm-applet.nix
    ../linux/blueman-applet.nix
    ../linux/hypridle.nix
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
    mpv
    networkmanagerapplet
    playerctl
    r2modman
    slurp
    discord
    wf-recorder
    wtype
    xdg-utils
    youtube-tui
    pear-desktop
  ];

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-decoration-layout = "menu:";
    gtk4.extraConfig.gtk-decoration-layout = "menu:";

    gtk3.extraCss = ''
      scrollbar slider {
        min-width: 10px;
        min-height: 10px;
      }
    '';

    cursorTheme = {
      name = "Adwaita";
      size = 24;
    };

    font = {
      name = "Cantarell";
      size = 11;
    };

    iconTheme = {
      name = "Tokyonight-Light";
      package = pkgs.dracula-icon-theme;
    };

    theme = {
      name = "Tokyonight-Dark";
      package = pkgs.tokyonight-gtk-theme;
    };

    gtk4.theme = config.gtk.theme;
  };

  xdg.userDirs = {
    templates = null;
    publicShare = null;
  };
}
