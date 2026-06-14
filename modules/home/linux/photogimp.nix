{ config, pkgs, lib, ... }:

let
  # PhotoGIMP config patch for GIMP 3.x (Diolinux/PhotoGIMP, v3.0 release).
  # Photoshop-like keyboard shortcuts, tool layout, splash, theme and a desktop
  # launcher. Pinned to the v3.0 tag for reproducibility; to bump, update both
  # `rev` and `sha256` (prefetch with:
  #   nix-prefetch-url --unpack https://github.com/Diolinux/PhotoGIMP/archive/<rev>.tar.gz
  #   nix hash convert --to sri --hash-algo sha256 <hash>
  # ) and delete the sentinel below to re-seed.
  photogimp = pkgs.fetchFromGitHub {
    owner = "Diolinux";
    repo = "PhotoGIMP";
    rev = "078d83ad94130d69b31be3b6ec9f26d662c23911"; # tag 3.0 (March 2025)
    sha256 = "sha256-R9MMidsR2+QFX6tu+j5k2BejxZ+RGwzA0DR9GheO89M=";
  };

  # PhotoGIMP ships the GIMP config under the Flatpak path; for a native
  # (Nix-installed) GIMP it maps onto ~/.config/GIMP/3.0.
  photogimpConfig = "${photogimp}/.var/app/org.gimp.GIMP/config/GIMP/3.0";

  gimpConfigDir = "${config.home.homeDirectory}/.config/GIMP/3.0";
  localShareDir = "${config.home.homeDirectory}/.local/share";

  cp = "${pkgs.coreutils}/bin/cp";
  chmod = "${pkgs.coreutils}/bin/chmod";
  mkdir = "${pkgs.coreutils}/bin/mkdir";
in
{
  # Copy PhotoGIMP files into GIMP's live config dir as real, writable files.
  # GIMP rewrites sessionrc/preferences/etc. at runtime, so a read-only
  # nix-store symlink (xdg.configFile / home.file) would break it. nix-store
  # files are mode 444, so cp --no-preserve=mode + an explicit chmod u+w
  # guarantees GIMP can still save its own state.
  #
  # Seed-once: guarded by a sentinel so in-GIMP tweaks survive later rebuilds.
  # Re-seed after bumping the pinned commit by deleting the sentinel.
  home.activation.photogimpSeed =
    lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      sentinel="${gimpConfigDir}/.photogimp-applied"
      if [ ! -e "$sentinel" ]; then
        $DRY_RUN_CMD ${mkdir} -p "${gimpConfigDir}" "${localShareDir}"

        # GIMP config overlay (shortcutsrc, toolrc, sessionrc, theme, splash...).
        # -f so cp removes-and-retries on any pre-existing read-only files.
        $DRY_RUN_CMD ${cp} -rf --no-preserve=mode \
          "${photogimpConfig}/." "${gimpConfigDir}/"

        # Desktop launcher + icons (applications/, icons/)
        $DRY_RUN_CMD ${cp} -rf --no-preserve=mode \
          "${photogimp}/.local/share/." "${localShareDir}/"

        $DRY_RUN_CMD ${chmod} -R u+w "${gimpConfigDir}"
        $DRY_RUN_CMD touch "$sentinel"
      fi
    '';
}
