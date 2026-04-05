{ pkgs, config, lib, ... }:

{
  boot = {
    initrd = {
      kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_drm" ];
    };
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        # Direct VA-API path for NVIDIA — enables hardware video decode in
        # Firefox/MPV/OBS. Replaces the old libva-vdpau-driver bridge approach.
        nvidia-vaapi-driver
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    };

    nvidia-container-toolkit = {
      enable = true;
      mount-nvidia-executables = true;
    };

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.stable;

      modesetting.enable = true;
      # Power management is required to get nvidia GPUs to behave on
      # suspend, due to firmware bugs. Aren't nvidia great?
      powerManagement.enable = true;
      open = true;
      # Keep GPU driver loaded at all times (eliminates cold-start latency for CUDA/gaming)
      nvidiaPersistenced = true;
    };
  };

  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    # WLR_NO_HARDWARE_CURSORS was needed for old proprietary NVIDIA on wlroots;
    # open drivers + Hyprland support hardware cursors natively — removed.
    # Direct VA-API driver selection for hardware video decode
    LIBVA_DRIVER_NAME = "nvidia";
    # G-Sync / VRR
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
    # Reduce input lag (limit pre-rendered frames to 1)
    __GL_MaxFramesAllowed = "1";
    # Better yield behavior for lower latency
    __GL_YIELD = "USLEEP";
  };
}
