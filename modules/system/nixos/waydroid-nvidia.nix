# GPU-accelerated Waydroid (Android in an LXC container) on the NVIDIA driver.
#
# Stock Waydroid can't render on NVIDIA: Android gets its acceleration through
# Mesa/GBM and NVIDIA's userspace isn't in Mesa, so you get a live container
# behind a black window. This stack proxies the guest's Vulkan (Mesa Venus)
# over a unix socket to a host-side renderer that issues the real calls, so
# buffers are allocated as native NVIDIA dmabufs and GL runs through ANGLE.
#
# Requires the open kernel modules (nvidia.nix sets open = true) -- the closed
# module has no DMA-BUF support and every displayed buffer here is one.
#
# This REPLACES stock Waydroid rather than layering on it: the upstream module
# ships its own waydroid-container.service against a patched waydroid, so
# virtualisation.waydroid stays off. waydroid-nvidia-full wraps waydroid and
# waydroid-net.sh with lxc/kmod/iptables/nftables/iproute2/dnsmasq on PATH, so
# virtualisation.lxc.enable isn't needed either.
#
# One-time setup after this lands (state under /var/lib/waydroid is mutable
# and outside the store, so it isn't declarative):
#
#   sudo waydroid init
#   sudo waydroid-nvidia-setup --refresh 144
#
# Verify the guest is actually accelerated rather than silently fallen back:
#
#   sudo waydroid shell dumpsys SurfaceFlinger | grep -i GLES
#   # want ANGLE + Venus + the real GPU name, e.g.
#   # ANGLE (NVIDIA, Vulkan 1.3.341 (NVIDIA Virtio-GPU Venus (NVIDIA GeForce RTX 4090)))
{ inputs, pkgs, ... }:

let
  waydroid-nvidia = inputs.waydroid-nvidia-nix.packages.x86_64-linux.waydroid-nvidia-full;

  # Marker so resume only restores what suspend actually took down. Without it
  # a suspend/resume cycle would spontaneously start the container even if it
  # had been stopped on purpose.
  restoreFlag = "/run/waydroid-nvidia-restore-on-resume";
in
{
  # waydroid-nvidia-setup is a bash script that shells out to readelf and
  # python3, but waydroid-nvidia-full only wraps `waydroid` and
  # `waydroid-net.sh`. readelf otherwise comes from the user nix-profile and
  # python3 from mise shims, neither of which is on root's PATH, so
  # `sudo waydroid-nvidia-setup` dies at its readelf guard and again at the
  # waydroid.cfg writer. Put both in the system profile.
  environment.systemPackages = [ pkgs.binutils pkgs.python3 ];

  services.waydroid-nvidia = {
    enable = true;

    # Set explicitly rather than letting mkPackageOption resolve
    # pkgs.waydroid-nvidia-full, which would mean applying the flake's overlay
    # system-wide just to get one package.
    package = waydroid-nvidia;

    # DP-3 runs 3840x2160@144 (Acer X27). Feeds persist.waydroid.refresh_rate.
    refreshRate = 144;
  };

  # Both of the following are provided by the stock nixpkgs waydroid module but
  # omitted by the waydroid-nvidia one. Without them Android networking breaks:
  # the firewall drops traffic on waydroid0, and dnsmasq has nowhere to write
  # its DHCP leases.
  networking.firewall.trustedInterfaces = [ "waydroid0" ];
  systemd.tmpfiles.rules = [ "d /var/lib/misc 0755 root root -" ];

  # Resuming with the container still running hangs it: neither the LXC
  # container nor its GPU state survives a host suspend. Quit the Android
  # session and stop the container before sleep, then bring the container back
  # on resume. The session is deliberately NOT restarted -- run
  # `waydroid session start` when you next want Android.
  #
  # before+wantedBy sleep.target is the standard shape: the unit is pulled in
  # and ordered ahead of sleep.target, so ExecStart runs before suspending;
  # RemainAfterExit keeps it active while asleep, so sleep.target going down on
  # resume stops it and fires ExecStop.
  systemd.services.waydroid-nvidia-sleep = {
    description = "Stop Waydroid across suspend, restore the container on resume";
    before = [ "sleep.target" ];
    wantedBy = [ "sleep.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      # A wedged container must not block suspend indefinitely.
      TimeoutStartSec = "30s";

      # `waydroid session stop` talks to the session manager on the user's
      # SessionBus, which a system unit cannot reach. That call raises
      # DBusException and waydroid falls back to id.waydro.Container.Stop(True)
      # on the SystemBus, which is reachable here and is the graceful path we
      # want, so running it as root does the right thing.
      ExecStart = pkgs.writeShellScript "waydroid-nvidia-sleep-pre" ''
        if ${pkgs.systemd}/bin/systemctl is-active --quiet waydroid-container.service; then
          ${pkgs.coreutils}/bin/touch ${restoreFlag}
          ${waydroid-nvidia}/bin/waydroid session stop || true
          ${pkgs.systemd}/bin/systemctl stop waydroid-container.service || true
        else
          ${pkgs.coreutils}/bin/rm -f ${restoreFlag}
        fi
      '';

      # --no-block: starting a unit from inside a stopping one would otherwise
      # risk waiting on the same job queue.
      ExecStop = pkgs.writeShellScript "waydroid-nvidia-sleep-post" ''
        if [ -e ${restoreFlag} ]; then
          ${pkgs.coreutils}/bin/rm -f ${restoreFlag}
          ${pkgs.systemd}/bin/systemctl --no-block start waydroid-container.service
        fi
      '';
    };
  };
}
