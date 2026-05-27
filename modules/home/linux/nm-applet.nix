{ pkgs, ... }:

{
  systemd.user.services.nm-applet = {
    Unit = {
      Description = "NetworkManager applet";
      Documentation = "https://gitlab.gnome.org/GNOME/network-manager-applet";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" "eww.service" ];
      Requires = [ "eww.service" ];
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
