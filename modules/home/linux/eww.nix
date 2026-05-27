{ config, pkgs, lib, sourceRoot, userConfig, ... }:

let
  # eww 0.6.0's StatusNotifierWatcher silently queues if another process claims
  # the org.kde.StatusNotifierWatcher dbus name first (watcher.rs:200 omits
  # DoNotQueue). When that happens, eww's host registration goes to the squatter's
  # watcher, and after the squatter dies eww owns the name but with empty internal
  # state -- tray icons never display. This start script proves eww won the race
  # before returning, so units ordered After=eww.service can rely on a working tray.
  eww-start = pkgs.writeShellScript "eww-start" ''
    set -euo pipefail

    # eww-daemon.service is Type=simple, so systemd marks it active the moment
    # the process is forked -- before the IPC socket is up. Ping the daemon
    # until it answers before trying to open the bar.
    for _ in $(seq 1 100); do
      if ${pkgs.eww}/bin/eww ping >/dev/null 2>&1; then break; fi
      sleep 0.1
    done

    ${pkgs.eww}/bin/eww open bar

    # Wait until eww owns both org.kde.StatusNotifierWatcher and a
    # StatusNotifierHost-* name on the same connection (== eww won the race).
    for _ in $(seq 1 100); do
      watcher_pid=$(${pkgs.systemd}/bin/busctl --user list 2>/dev/null \
        | ${pkgs.gawk}/bin/awk '$1 == "org.kde.StatusNotifierWatcher" { print $2; exit }')
      host_pid=$(${pkgs.systemd}/bin/busctl --user list 2>/dev/null \
        | ${pkgs.gawk}/bin/awk '/^org\.freedesktop\.StatusNotifierHost-/ { print $2; exit }')
      if [[ -n "$watcher_pid" ]] && [[ "$watcher_pid" = "$host_pid" ]]; then
        exit 0
      fi
      sleep 0.1
    done

    echo "eww-start: timeout waiting for eww to claim StatusNotifierWatcher" >&2
    exit 1
  '';
in
{
  home.packages = with pkgs; [
    eww
    jq
    socat
  ];

  xdg.configFile = {
    "eww".source = config.lib.file.mkOutOfStoreSymlink "${userConfig.dotfilesPath}/config/eww";
  };

  # Run the daemon in foreground so its stdout/stderr land in the journal
  # (journalctl --user -u eww-daemon). Without --no-daemonize, eww forks into
  # the background and systemd loses both lifecycle control and log visibility.
  #
  # Ordering: After=graphical-session.target so we don't force a target restart
  # at switch-to-configuration time. WantedBy+After is fine -- Wants= doesn't
  # block target activation, so the target reaches active first, then eww
  # starts. All SNI client units (nm-applet, blueman-applet, sunshine) are
  # likewise After=graphical-session.target, so there's no cycle.
  systemd.user.services.eww-daemon = {
    Unit = {
      Description = "ElKowar's wacky widgets - daemon";
      Documentation = "https://github.com/elkowar/eww";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.eww}/bin/eww --no-daemonize daemon";
      Restart = "on-failure";
      RestartSec = "1s";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };

  # Tray-ready gate. Opens the bar window then blocks until eww has won the
  # StatusNotifierWatcher race (see eww-start above). SNI clients depend on
  # this unit, not eww-daemon, so they only start once the tray is usable.
  systemd.user.services.eww = {
    Unit = {
      Description = "ElKowar's wacky widgets - bar window";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "eww-daemon.service" ];
      BindsTo = [ "eww-daemon.service" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "oneshot";
      RemainAfterExit = true;
      ExecStart = "${eww-start}";
      ExecStop = "${pkgs.eww}/bin/eww close bar";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
