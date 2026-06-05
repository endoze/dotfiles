{ pkgs, ... }:

{
  systemd.user.services.nm-applet = {
    Unit = {
      Description = "NetworkManager applet";
      Documentation = "https://gitlab.gnome.org/GNOME/network-manager-applet";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "eww.service" ];
      # Wants (not Requires): order after the tray, but don't let an eww
      # restart/flap (e.g. during a home-manager switch) cascade-stop the applet.
      Wants = [ "eww.service" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
