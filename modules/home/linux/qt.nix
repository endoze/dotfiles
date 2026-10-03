{ pkgs, ... }:

# Qt apps match the glass desktop: Kvantum's WhiteSurDark for widgets, qtct for
# fonts (Inter) and icons. QML-only apps (chiaki-ng, quickshell) draw their own
# UI and are unaffected beyond the default font.
#
# QT_QPA_PLATFORMTHEME and QT_PLUGIN_PATH are also set in
# config/hypr/configs/env.lua: home.sessionVariables does not reach apps
# launched from Hyprland.
let
  appearance = {
    style = "kvantum";
    icon_theme = "WhiteSur-dark";
    standard_dialogs = "default";
  };
in
{
  qt = {
    enable = true;
    platformTheme.name = "qtct";

    # Style is chosen in the qtct configs below rather than QT_STYLE_OVERRIDE,
    # so only the plugins need installing.
    style.package = [
      pkgs.kdePackages.qtstyleplugin-kvantum
      pkgs.libsForQt5.qtstyleplugin-kvantum
    ];

    kvantum = {
      enable = true;
      themes = [ pkgs.whitesur-kde ];
      settings.General.theme = "WhiteSurDark";
    };

    qt6ctSettings = {
      Appearance = appearance;
      Fonts = {
        general = ''"Inter,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"'';
        fixed = ''"JetBrainsMono Nerd Font,11,-1,5,400,0,0,0,0,0,0,0,0,0,0,1"'';
      };
    };

    qt5ctSettings = {
      Appearance = appearance;
      Fonts = {
        general = ''"Inter,11,-1,5,50,0,0,0,0,0"'';
        fixed = ''"JetBrainsMono Nerd Font,11,-1,5,50,0,0,0,0,0"'';
      };
    };
  };
}
