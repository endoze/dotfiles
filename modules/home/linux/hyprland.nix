{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  xdg.configFile = {
    "hypr".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/hypr";

    # Disable XDG autostart so .desktop files in etc/xdg/autostart/ don't silently
    # race against our explicit systemd user services (notably the eww systray
    # watcher, which loses the dbus name race when blueman.desktop autostart fires
    # first). The bridge target (wayland-session-xdg-autostart@.target) isn't what
    # pulls in the per-app units -- xdg-desktop-autostart.target does via Wants=,
    # and the app-X@autostart.service instances also get pulled in directly. So
    # mask the template itself, which covers every generated instance.
    "systemd/user/app-@autostart.service.d/disable.conf".text = ''
      [Unit]
      ConditionPathExists=/nonexistent
    '';
  };
}
