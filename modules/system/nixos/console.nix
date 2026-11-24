# Userspace console on tty2-6: kmscon built on Ghostty's terminal engine
# (ghostcon), styled from config/ghostty so the console matches Ghostty.
#
# Shared with Ghostty: font-family, theme palette/background/foreground,
# cursor-color, cursor-style, cursor-style-blink. Ghostty settings in
# config/ghostty/config override the theme, same as Ghostty does.
#
# Not shared: font-size. Ghostty sizes in points under Hyprland's scaling;
# kmscon sizes in raw pixels on the 4K panel, so it needs its own value.
{ pkgs, lib, inputs, ... }:

let
  ghosttyDir = ../../../config/ghostty;

  parseGhostty = path:
    lib.pipe (builtins.readFile path) [
      (lib.splitString "\n")
      (map (builtins.match "[[:space:]]*([a-z0-9-]+)[[:space:]]*=[[:space:]]*(.*[^[:space:]])[[:space:]]*"))
      (lib.filter (m: m != null))
      (map (m: {
        key = builtins.elemAt m 0;
        value = lib.removeSuffix "\"" (lib.removePrefix "\"" (builtins.elemAt m 1));
      }))
    ];

  ghosttyConfig = parseGhostty (ghosttyDir + "/config");

  valuesOf = key: entries: map (e: e.value) (lib.filter (e: e.key == key) entries);
  lastOf = key: entries: lib.findFirst (_: true) null (lib.reverseList (valuesOf key entries));

  themeName = lastOf "theme" ghosttyConfig;
  themeFile = ghosttyDir + "/themes/${themeName}";

  # Theme first, then config: later entries win, matching Ghostty.
  settings =
    assert lib.assertMsg (themeName != null && builtins.pathExists themeFile)
      "console.nix: Ghostty theme '${toString themeName}' must exist in config/ghostty/themes";
    parseGhostty themeFile ++ ghosttyConfig;

  hex = lib.removePrefix "#";

  ansiColorNames = [
    "black" "red" "green" "yellow" "blue" "magenta" "cyan" "light-grey"
    "dark-grey" "light-red" "light-green" "light-yellow" "light-blue" "light-magenta" "light-cyan" "white"
  ];

  palette = lib.foldl'
    (acc: value:
      let
        m = builtins.match "([0-9]+)=#?([0-9a-fA-F]{6})" value;
        index = lib.toInt (builtins.elemAt m 0);
      in
      if m == null || index > 15 then acc
      else acc // { "palette-${builtins.elemAt ansiColorNames index}" = builtins.elemAt m 1; })
    { }
    (valuesOf "palette" settings);

  optionalSetting = key: f:
    let v = lastOf key settings; in lib.optionalAttrs (v != null) (f v);

  cursorStyles = { block = "block"; block_hollow = "block"; bar = "bar"; underline = "underline"; };
in
{
  services.kmscon = {
    enable = true;
    package = inputs.ghostcon.packages.${pkgs.stdenv.hostPlatform.system}.kmscon;
    useXkbConfig = true;
    config = {
      hwaccel = true;
      font-engine = "freetype";
      font-name = lib.head (valuesOf "font-family" ghosttyConfig);
      font-size = 32;
      palette = "custom";
    }
    // palette
    // optionalSetting "background" (v: { palette-background = hex v; })
    // optionalSetting "foreground" (v: { palette-foreground = hex v; })
    // optionalSetting "cursor-color" (v: { cursor-color = hex v; })
    // optionalSetting "cursor-style" (v: { cursor-style = cursorStyles.${v} or "block"; })
    // optionalSetting "cursor-style-blink" (v: { cursor-blink = v == "true"; });
  };

  # kmscon runs as root and only sees system fonts; home-manager's copy of
  # Monaspace is invisible to it.
  fonts.packages = [ pkgs.monaspace ];
}
