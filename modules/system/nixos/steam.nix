{ pkgs, ... }:

{
  programs = {
    gamemode = {
      enable = true;
      enableRenice = true;
      settings = {
        general = {
          renice = 10;
          softrealtime = "auto";
          ioprio = 0;
          inhibit_screensaver = 0;
          desiredgov = "performance";
        };
        gpu = {
          apply_gpu_optimisations = "accept-responsibility";
          gpu_device = 0;
          nv_powermizer_mode = 1;  # Force max GPU performance during gaming
        };
        custom = {
          start = "${pkgs.libnotify}/bin/notify-send 'GameMode activated'";
          end = "${pkgs.libnotify}/bin/notify-send 'GameMode deactivated'";
        };
      };
    };
    steam = {
      gamescopeSession.enable = true;
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };

  environment.systemPackages = with pkgs; [
    protonup-ng
  ];

  environment.sessionVariables = {
    STEAM_EXTRA_COMPAT_TOOLS_PATHS = "\${HOME}/.steam/root/compatibilitytools.d";
  };
}
