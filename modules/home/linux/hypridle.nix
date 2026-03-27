{ pkgs, ... }:

{
  systemd.user.services.hypridle = {
    Unit = {
      Description = "Hypridle idle daemon";
      Documentation = "https://github.com/hyprwm/hypridle";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.hypridle}/bin/hypridle";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
