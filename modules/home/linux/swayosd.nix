# vim: ft=nix
{ config, pkgs, lib, sourceRoot, userConfig, ... }:

{
  home.packages = with pkgs; [ swayosd ];

  systemd.user.services.swayosd = {
    Unit = {
      Description = "SwayOSD volume/brightness OSD";
      Documentation = "https://github.com/ErikReider/SwayOSD";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
      ConditionEnvironment = "WAYLAND_DISPLAY";
    };
    Service = {
      Type = "simple";
      ExecStart = "${pkgs.swayosd}/bin/swayosd-server";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "graphical-session.target" ];
    };
  };
}
