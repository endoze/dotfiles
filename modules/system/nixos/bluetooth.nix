{ pkgs, lib, ... }:

{
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # blueman ships its own user unit with ExecStart=; NixOS's drop-in adds another
  # ExecStart= which systemd rejects for non-oneshot services. Reset before re-setting.
  systemd.user.services.blueman-applet.serviceConfig.ExecStart = lib.mkForce [
    ""
    "${pkgs.blueman}/bin/blueman-applet"
  ];
}
