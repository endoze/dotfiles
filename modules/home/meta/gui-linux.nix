{ config, pkgs, lib, ... }:

{
  # openldap test017-syncreplication-refresh fails deterministically on this
  # nixpkgs revision; pulled in transitively by lutris.
  nixpkgs.overlays = [
    (final: prev: {
      openldap = prev.openldap.overrideAttrs (_: { doCheck = false; });

      # Discord's voice-state tray icons are green (speaking) and red-slashed
      # (muted/deafened) pixmaps that bypass the icon theme; swap in all-white
      # copies to match the rest of the eww tray. Discord is unfree, so it is
      # always repackaged locally anyway; this adds one cp.
      discord = prev.discord.override {
        unwrappedDiscord = prev.discord.passthru.unwrappedDiscord.overrideAttrs (old: {
          postInstall = (old.postInstall or "") + ''
            cp ${../linux/discord-tray}/*.png \
              $out/opt/Discord/modules/discord_desktop_core/app/images/systemtray/linux/
          '';
        });
      };
    })
  ];

  imports = [
    ../common/firefox.nix
    ../common/ghostty.nix
    ../linux/dconf.nix
    ../linux/gnome-keyring.nix
    ../linux/hyprland.nix
    ../linux/kitty.nix
    ../linux/shirase.nix
    ../linux/tokyonight-gtk-theme.nix
    ../linux/tokyonight-icon-theme.nix
    ../linux/eww.nix
    ../linux/awww.nix
    ../linux/wallpaper-picker.nix
    ../linux/cliphist.nix
    ../linux/nm-applet.nix
    ../linux/photogimp.nix
    ../linux/chromium.nix
    ../linux/hypridle.nix
    ../linux/fontconfig.nix
    ../linux/qt.nix
  ];

  home.packages = with pkgs; [
    nerd-fonts.inconsolata-go
    nerd-fonts.jetbrains-mono
    monaspace
    ghostty
    gimp
    libnotify
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
    quickemu
    quickgui
  ];

  gtk = {
    enable = true;
    gtk3.extraConfig.gtk-decoration-layout = "menu:";
    gtk3.extraConfig.gtk-overlay-scrolling = false;
    gtk4.extraConfig.gtk-decoration-layout = "menu:";
    gtk4.extraConfig.gtk-overlay-scrolling = false;

    gtk3.extraCss = ''
      scrollbar slider {
        min-width: 10px;
        min-height: 10px;
      }
    '';

    gtk4.extraCss = ''
      scrollbar > range > trough > slider,
      scrollbar.overlay-indicator:not(.dragging):not(.hovering) > range > trough > slider {
        min-width: 10px;
        min-height: 10px;
      }
    '';

    cursorTheme = {
      name = "WhiteSur-cursors";
      package = pkgs.whitesur-cursors;
      size = 24;
    };

    font = {
      name = "Inter";
      package = pkgs.inter;
      size = 11;
    };

    iconTheme = {
      name = "WhiteSur-dark";
      # WhiteSur's 1px panel icons vanish on the transparent eww bar. Bold panel
      # icons (1.5px) everywhere, plus solid MDI glyphs (matching the bar's Nerd
      # Font glyphs) for the always-visible tray icons. Every non-symbolic
      # copy is replaced since GTK may pick apps/scalable over status/22 at 20px.
      # WhiteSur-dark's size dirs are symlinks into the base WhiteSur theme, so
      # find -L follows them (WhiteSur-light has its own dirs and is untouched).
      # --remove-destination replaces per-icon symlinks instead of writing
      # through them into their shared targets.
      package = (pkgs.whitesur-icon-theme.override { boldPanelIcons = true; }).overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          replace() {
            find -L $out/share/icons/WhiteSur-dark -name "$1.svg" -not -path '*/symbolic/*' \
              -exec cp --remove-destination ${../linux/tray-icons}/$2.svg {} \;
          }
          replace blueman-tray bluetooth
          replace blueman-active bluetooth-connect
          replace blueman-disabled bluetooth-off
          replace nm-device-wired ethernet
          replace nm-no-connection ethernet-off
          replace nm-signal-00 wifi-strength-outline
          replace nm-signal-25 wifi-strength-1
          replace nm-signal-50 wifi-strength-2
          replace nm-signal-75 wifi-strength-3
          replace nm-signal-100 wifi-strength-4
          replace nm-signal-00-secure wifi-strength-lock-outline
          replace nm-signal-25-secure wifi-strength-1-lock
          replace nm-signal-50-secure wifi-strength-2-lock
          replace nm-signal-75-secure wifi-strength-3-lock
          replace nm-signal-100-secure wifi-strength-4-lock
        '';
      });
    };

    theme = {
      name = "WhiteSur-Dark";
      package = pkgs.whitesur-gtk-theme;
    };

    gtk4.theme = config.gtk.theme;
  };

  xdg.userDirs = {
    templates = null;
    publicShare = null;
  };
}
