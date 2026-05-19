{ pkgs, ... }:

{
  boot = {
    plymouth = {
      enable = true;
      themePackages = [ pkgs.adi1090x-plymouth-themes ];
      theme = "hud_space";
    };

    consoleLogLevel = 0;
    initrd.systemd.enable = true;
    initrd.verbose = false;

    # Wait for kernel modules (specifically nvidia-drm) before showing the
    # splash. Without this ordering, plymouth-start races systemd-modules-load
    # and opens simpledrm; nvidia-drm then takes the display ~2s later and
    # plymouth's surface goes to a stale framebuffer, falling back to text.
    initrd.systemd.services.plymouth-start = {
      after = [ "systemd-modules-load.service" ];
      wants = [ "systemd-modules-load.service" ];
    };
    kernelParams = [
      "quiet"
      "loglevel=3"
      "splash"
      "boot.shell_on_fail"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "systemd.show_status=false"
      "vt.global_cursor_default=0"
    ];
  };
}
