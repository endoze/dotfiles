{ pkgs, ... }:

{
  boot = {
    plymouth = {
      enable = true;
      themePackages = [ pkgs.adi1090x-plymouth-themes ];
      theme = "hud_space";
    };

    consoleLogLevel = 0;
    initrd.verbose = false;
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
