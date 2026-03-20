{ pkgs, ... }:

{
  systemd.user.services.blueman-applet = {
    Unit = {
      Description = "Blueman Bluetooth applet";
      Documentation = "https://github.com/blueman-project/blueman";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.blueman}/bin/blueman-applet";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
