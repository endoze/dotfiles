{ config, pkgs, lib, sourceRoot, ... }:

let
  # Single entry point for wallpaper -> palette. Both the waypaper post_command
  # and the elephant wallpaper provider call this, so the generate + reload
  # logic lives in exactly one place.
  #
  # Generated colors are transient and only ever written under ~/.cache/wallust.
  # The hot-reloaders differ per app:
  #   - Hyprland   self-reloads the file it `source`s     -> nothing to do
  #   - eww        watches its config dir, not the cache   -> `eww reload`
  #   - shirase    watches its config dir via gio FileMonitor and only reacts to
  #                ChangesDoneHint, so a bare `touch` (attribute change) is not
  #                enough -> rewrite style.css in place with identical content to
  #                emit a real CHANGED event. The temp file lives in the cache
  #                (outside the watched dir) so it neither dirties the repo nor
  #                triggers a mid-write reload.
  #   - walker     no CSS watcher                          -> restart the service
  # ghostty is intentionally NOT themed by wallust: the terminal stays on its
  # stable hand-picked theme so wallpaper-derived colors can never make text
  # unreadable.
  wallust-apply = pkgs.writeShellScriptBin "wallust-apply" ''
    set -uo pipefail

    wallpaper="''${1:-}"
    if [ -z "$wallpaper" ]; then
      echo "usage: wallust-apply <wallpaper>" >&2
      exit 1
    fi

    ${pkgs.wallust}/bin/wallust run --skip-sequences --quiet "$wallpaper" || true

    # eww: explicit reload (its watcher is on the config dir, not the cache).
    ${pkgs.eww}/bin/eww reload || true

    # shirase: nudge its config-dir FileMonitor with an in-place identical rewrite.
    shirase_css="$HOME/.config/shirase/style.css"
    if [ -f "$shirase_css" ]; then
      tmp="$HOME/.cache/wallust/.shirase-style.tmp"
      if ${pkgs.coreutils}/bin/cp -- "$shirase_css" "$tmp"; then
        ${pkgs.coreutils}/bin/cat -- "$tmp" > "$shirase_css" || true
        ${pkgs.coreutils}/bin/rm -f -- "$tmp" || true
      fi
    fi

    # walker: no CSS watcher, restart to re-read the @import'd cache colors.
    ${pkgs.systemd}/bin/systemctl --user restart walker.service || true
  '';
in
{
  home.packages = [
    pkgs.wallust
    wallust-apply
  ];

  xdg.configFile = {
    "wallust/wallust.toml".source = "${sourceRoot}/config/wallust/wallust.toml";
    "wallust/templates" = {
      source = "${sourceRoot}/config/wallust/templates";
      recursive = true;
    };
  };

  # Seed writable placeholders so consumers don't fail before the first wallpaper
  # switch. These must be real, writable files wallust can overwrite, so they are
  # created via an activation script rather than xdg.cacheFile (which would make
  # them read-only nix-store symlinks). Existing generated files are left as-is.
  #
  # GTK consumers (shirase, walker) reference @define-color names, so an empty
  # file would leave those undefined and break their stylesheets — seed them with
  # the committed One Dark fallback palettes instead. The others tolerate an empty
  # file because their committed config carries its own defaults (eww's $vars,
  # Hyprland's general{} block).
  home.activation.wallustPlaceholders =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      $DRY_RUN_CMD mkdir -p "$HOME/.cache/wallust"
      for f in shirase-colors.css walker-colors.css; do
        if [ ! -e "$HOME/.cache/wallust/$f" ]; then
          $DRY_RUN_CMD install -m 644 "${sourceRoot}/config/wallust/fallback/$f" "$HOME/.cache/wallust/$f"
        fi
      done
      for f in hyprland.conf eww-colors.scss; do
        if [ ! -e "$HOME/.cache/wallust/$f" ]; then
          $DRY_RUN_CMD touch "$HOME/.cache/wallust/$f"
        fi
      done
    '';
}
