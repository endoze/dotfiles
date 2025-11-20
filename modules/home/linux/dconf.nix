# Generated via dconf2nix: https://github.com/gvolpe/dconf2nix
{ lib, ... }:

with lib.hm.gvariant;

{
  dconf.settings = {
    "org/blueman/general" = {
      window-properties = [ 2516 1354 0 0 ];
    };

    "org/erikreider/swaync" = {
      dnd-state = false;
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
      cursor-size = 24;
      cursor-theme = "Adwaita";
      font-antialiasing = "grayscale";
      font-hinting = "slight";
      font-name = "Cantarell 11";
      font-rgba-order = "rgb";
      gtk-theme = "Tokyonight-Dark";
      icon-theme = "Tokyonight-Light";
      text-scaling-factor = 1.5;
      toolbar-icons-size = "large";
      toolbar-style = "both-horiz";
    };

    "org/gnome/desktop/sound" = {
      event-sounds = true;
      input-feedback-sounds = false;
    };

    "org/gnome/file-roller/dialogs/extract" = {
      height = 800;
      width = 1000;
    };

    "org/gnome/file-roller/dialogs/new" = {
      default-extension = ".zip";
      encrypt-header = false;
      volume-size = 104857;
    };

    "org/gnome/file-roller/file-selector" = {
      show-hidden = false;
      sidebar-size = 300;
      window-size = mkTuple [ (-1) (-1) ];
    };

    "org/gnome/file-roller/listing" = {
      list-mode = "as-folder";
      name-column-width = 71;
      show-path = false;
      sort-method = "name";
      sort-type = "ascending";
    };

    "org/gnome/file-roller/ui" = {
      sidebar-width = 200;
      window-height = 480;
      window-width = 600;
    };

    "org/gtk/settings/file-chooser" = {
      date-format = "regular";
      location-mode = "path-bar";
      show-hidden = false;
      show-size-column = true;
      show-type-column = true;
      sidebar-width = 179;
      sort-column = "name";
      sort-directories-first = false;
      sort-order = "descending";
      type-format = "category";
      window-position = mkTuple [ 0 0 ];
      window-size = mkTuple [ 2516 1306 ];
    };
  };
}
