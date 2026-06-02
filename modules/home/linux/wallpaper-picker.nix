{ config, pkgs, lib, userConfig, ... }:

let
  # Post-apply hook, invoked by the picker as `wallpaper-picker-reload <wallpaper>`.
  # Updates the symlink awww restores on login, then reuses the single wallust
  # entry point (which reloads eww/shirase and restarts walker).
  wallpaper-picker-reload = pkgs.writeShellScriptBin "wallpaper-picker-reload" ''
    set -uo pipefail
    wallpaper="''${1:-}"
    if [ -z "$wallpaper" ]; then
      echo "usage: wallpaper-picker-reload <wallpaper>" >&2
      exit 1
    fi
    ${pkgs.coreutils}/bin/ln -sf "$wallpaper" "$HOME/.config/hypr/current-wallpaper"
    exec wallust-apply "$wallpaper"
  '';

  # Launcher: the picker only displays pre-generated thumbnails (it does not
  # scan the wallpaper folder), so keep the thumbnail cache in sync, then open
  # the carousel. Regenerates missing/stale thumbs and prunes orphans.
  wallpaper-picker = pkgs.writeShellScriptBin "wallpaper-picker" ''
    set -uo pipefail
    src="$HOME/Pictures/Wallpapers"
    thumbs="$HOME/.cache/wallpaper_picker/thumbs"
    ${pkgs.coreutils}/bin/mkdir -p "$thumbs"

    ${pkgs.findutils}/bin/find "$src" -maxdepth 1 -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.gif' \) \
      -print0 | while IFS= read -r -d "" f; do
        t="$thumbs/$(${pkgs.coreutils}/bin/basename "$f")"
        if [ ! -s "$t" ] || [ "$f" -nt "$t" ]; then
          ${pkgs.imagemagick}/bin/magick "$f" -resize x420 -quality 70 "$t" || ${pkgs.coreutils}/bin/rm -f "$t"
        fi
      done

    ${pkgs.findutils}/bin/find "$thumbs" -maxdepth 1 -type f -print0 | while IFS= read -r -d "" t; do
      if [ ! -e "$src/$(${pkgs.coreutils}/bin/basename "$t")" ]; then
        ${pkgs.coreutils}/bin/rm -f "$t"
      fi
    done

    exec ${pkgs.quickshell}/bin/quickshell -p "$HOME/.config/quickshell/wallpaper-picker/Main.qml"
  '';
in
{
  home.packages = [
    pkgs.quickshell
    pkgs.imagemagick
    wallpaper-picker
    wallpaper-picker-reload
  ];

  # Live-editable (out-of-store symlink), same pattern as eww.nix.
  xdg.configFile."quickshell/wallpaper-picker".source =
    config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/quickshell/wallpaper-picker";
}
