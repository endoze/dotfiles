{ pkgs, lib, ... }:

{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # blueman ships its own user unit with ExecStart=; NixOS's drop-in adds another
  # ExecStart= which systemd rejects for non-oneshot services. Reset before re-setting.
  #
  # The upstream blueman-applet.service has no ordering relative to
  # graphical-session.target, so add it explicitly (After + PartOf) to match
  # nm-applet/sunshine/eww and avoid races during session start/stop.
  systemd.user.services.blueman-applet = {
    after = [ "graphical-session.target" "eww.service" ];
    requires = [ "eww.service" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.blueman}/bin/blueman-applet"
    ];
  };
}
