{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [ ];

  xdg.configFile = {
    "swaync".source = "${sourceRoot}/config/swaync";
  };

  # Override swaync systemd service to use GL renderer instead of Vulkan
  # Fixes hanging issue on Nvidia GPUs: https://github.com/ErikReider/SwayNotificationCenter/issues/621
  systemd.user.services.swaync = {
    Unit = {
      Description = "Swaync notification daemon";
      Documentation = "https://github.com/ErikReider/SwayNotificationCenter";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "dbus";
      BusName = "org.freedesktop.Notifications";
      Environment = [ "GSK_RENDERER=gl" ];
      ExecStart = "${pkgs.swaynotificationcenter}/bin/swaync";
      ExecReload = "${pkgs.swaynotificationcenter}/bin/swaync-client --reload-config ; ${pkgs.swaynotificationcenter}/bin/swaync-client --reload-css";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
