{ pkgs, ... }:

# nixpkgs removed `tokyonight-gtk-theme` on 2026-07-22 along with 64 other
# themes, because they all propagated `gtk-engine-murrine` (unmaintained, GTK 2).
# Murrine is only referenced by the theme's gtk-2.0 subtree; gtk-3.0 and gtk-4.0
# are plain sassc-compiled CSS. So we build it here without murrine, which is
# what nixpkgs itself is doing upstream one theme at a time (see PR #544668).
let
  repoUrl = "https://github.com/Fausto-Korpsvart/Tokyonight-GTK-Theme";
  revision = "4dc45d60bf35f50ebd9ee41f16ab63783f80dd64";
in
{
  nixpkgs.overlays = [
    (final: prev: {
      tokyonight-gtk-theme = prev.stdenvNoCC.mkDerivation {
        pname = "tokyonight-gtk-theme";
        version = "0-unstable-2024-11-06";

        src = prev.fetchgit {
          url = repoUrl;
          rev = revision;
          sha256 = "sha256-AKZA+WCcfxDeNrNrq3XYw+SFoWd1VV2T9+CwK2y6+jA=";
        };

        nativeBuildInputs = [ prev.sassc ];

        # This revision draws the GTK4 switch as a 24px-wide rounded box with a
        # dark knob and a heavy focus glow, which reads badly in the notification
        # center. Restore the pill: full radius, light knob, subtle focus ring.
        # Patched in SCSS rather than the built CSS so sassc regenerates every
        # variant with that variant's own palette.
        postPatch = ''
          ${prev.gawk}/bin/awk '
            /^switch \{/ { skip = 1; while ((getline line < "${./tokyonight-switch.scss}") > 0) print line; next }
            skip && /^\}/ { skip = 0; next }
            !skip
          ' themes/src/sass/gtk/_common-4.0.scss > _common-4.0.patched \
            && mv _common-4.0.patched themes/src/sass/gtk/_common-4.0.scss
        '';

        dontConfigure = true;
        dontBuild = true;

        installPhase = ''
          runHook preInstall

          mkdir -p "$out/share/themes"
          cd themes
          patchShebangs install.sh
          HOME="$TMPDIR" ./install.sh --dest "$out/share/themes" --name Tokyonight

          # Fail the build rather than ship a boxy switch if the patch silently
          # stops matching after a revision bump.
          for css in "$out"/share/themes/*/gtk-4.0/gtk.css; do
            ${prev.gawk}/bin/awk '/^switch \{/,/^\}/' "$css" \
              | grep -q 'border-radius: 9999px' \
              || { echo "switch is not a pill in $css"; exit 1; }
          done

          runHook postInstall
        '';

        meta = {
          description = "Tokyonight GTK theme, built without gtk-engine-murrine";
          homepage = repoUrl;
          license = prev.lib.licenses.gpl3Only;
          platforms = prev.lib.platforms.linux;
        };
      };
    })
  ];
}
