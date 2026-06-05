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
  #
  # wantedBy is required: PartOf only propagates stop/restart from the target,
  # it does NOT pull the unit in when the target starts. Without this the unit
  # is defined but orphaned (WantedBy=empty) and never autostarts -- which is
  # why the blueman tray icon never appeared. nm-applet/sunshine set this too.
  systemd.user.services.blueman-applet = {
    after = [ "graphical-session.target" "eww.service" ];
    # wants (not requires): order after the tray without letting an eww flap
    # cascade-stop the applet via Requires= stop-propagation.
    wants = [ "eww.service" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "graphical-session.target" ];
    serviceConfig.ExecStart = lib.mkForce [
      ""
      "${pkgs.blueman}/bin/blueman-applet"
    ];
  };
}
