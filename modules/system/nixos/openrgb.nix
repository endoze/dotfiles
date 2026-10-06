{ config, pkgs, lib, ... }:

let
  openrgb = config.services.hardware.openrgb.package;

  # Black out the RAM, GPU and motherboard. A bare `openrgb --color 000000`
  # applies to every device OpenRGB detects (keyboards, mice), so select
  # devices by the "Type:" line in --list-detailed. Devices are addressed by
  # index rather than name because both sticks of a kit usually share a name
  # and --device "<name>" only matches the first. DIMMs get painted black;
  # the GPU has a native Off mode, which is cleaner than holding Direct mode
  # at black. The board has no Off mode, so it gets Static black, which also
  # covers fans on its ARGB headers. Bail out when nothing matches, since an
  # openrgb call with no --device would hit everything.
  lightsOff = pkgs.writeShellApplication {
    name = "openrgb-lights-off";
    runtimeInputs = [ openrgb pkgs.gawk ];
    text = ''
      mapfile -t devices < <(openrgb "$@" --list-detailed | awk '
        /^[0-9]+: / { idx = $1; sub(":", "", idx) }
        /^  Type: +DRAM$/ { print idx, "dram" }
        /^  Type: +GPU$/ { print idx, "gpu" }
        /^  Type: +Motherboard$/ { print idx, "motherboard" }
      ')

      if [ "''${#devices[@]}" -eq 0 ]; then
        echo "no DRAM, GPU or motherboard RGB controllers detected" >&2
        exit 1
      fi

      args=()
      for device in "''${devices[@]}"; do
        read -r idx type <<< "$device"
        case "$type" in
          dram) args+=(--device "$idx" --color 000000) ;;
          gpu) args+=(--device "$idx" --mode Off) ;;
          motherboard) args+=(--device "$idx" --mode Static --color 000000) ;;
        esac
      done
      openrgb "$@" "''${args[@]}"
    '';
  };

  lightsOffService = {
    Type = "oneshot";
    # --config must name an existing directory or openrgb prints usage and
    # exits; StateDirectory creates it.
    StateDirectory = "OpenRGB";
    # systemd-modules-load only runs in the initrd and isn't rerun after
    # switch-root, so boot.kernelModules (including i2c-dev) never get loaded.
    # Without /dev/i2c-* OpenRGB only finds HID devices.
    ExecStartPre = "${pkgs.kmod}/bin/modprobe i2c-dev";
    ExecStart = "${lib.getExe lightsOff} --noautoconnect --config /var/lib/OpenRGB";
  };

  sleepTargets = [
    "suspend.target"
    "hibernate.target"
    "hybrid-sleep.target"
    "suspend-then-hibernate.target"
  ];
in
{
  # Kernel modules (i2c-dev + i2c-i801/piix4 by CPU vendor), udev rules and the
  # openrgb CLI/GUI.
  services.hardware.openrgb.enable = true;

  # The module's always-on SDK server isn't needed just to set the lights once,
  # and it would contend with the oneshot below for the SMBus.
  systemd.services.openrgb.enable = false;

  # DIMM, GPU and motherboard controllers reset to their rainbow default on
  # every power cycle, so reapply at boot.
  systemd.services.openrgb-lights-off = {
    description = "Turn off RAM, GPU and motherboard RGB lighting";
    wantedBy = [ "multi-user.target" ];
    after = [ "systemd-modules-load.service" ];
    serviceConfig = lightsOffService // { RemainAfterExit = true; };
  };

  # Suspend cuts power to the controllers too, so they come back in rainbow.
  # The sleep targets are only reached once systemd-suspend.service returns,
  # i.e. after wake, so ordering after them runs this on resume. No
  # RemainAfterExit, so it goes inactive again and re-runs on every resume.
  systemd.services.openrgb-lights-off-resume = {
    description = "Turn off RAM, GPU and motherboard RGB lighting after resume";
    wantedBy = sleepTargets;
    after = sleepTargets;
    serviceConfig = lightsOffService;
  };
}
