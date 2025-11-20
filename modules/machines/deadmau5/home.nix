{ config, pkgs, lib, userConfig, ... }:

{
  home.stateVersion = "24.05";

  imports = [
  ];

  home = {
    packages = with pkgs; [
      elixir
      elixir-ls
      gimp
      libnotify
      lyrebird
      lutris
      networkmanagerapplet
      playerctl
      r2modman
      slurp
      discord
      wf-recorder
      xdg-utils
      youtube-music
    ];
  };


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

  xdg = {
    userDirs = {
      enable = true;
      createDirectories = true;
      templates = null;
      publicShare = null;
    };
  };
}
