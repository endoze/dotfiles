{ pkgs, config, lib, ... }:

{
  boot = {
    initrd = {
      kernelModules = [ "nvidia" ];
    };
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        vaapiVdpau
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    };

    nvidia-container-toolkit.enable = true;

    nvidia = {
      package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
        version = "580.76.05";
        sha256_64bit = "sha256-IZvmNrYJMbAhsujB4O/4hzY8cx+KlAyqh7zAVNBdl/0=";
        sha256_aarch64 = lib.fakeHash;
        openSha256 = "sha256-xEPJ9nskN1kISnSbfBigVaO6Mw03wyHebqQOQmUg/eQ=";
        settingsSha256 = lib.fakeHash;
        persistencedSha256 = lib.fakeHash;
      };

      # The nvidia-settings build is currently broken due to a missing
      # vulkan header; re-enable whenever
      # 0384602eac8bc57add3227688ec242667df3ffe3the hits stable.
      nvidiaSettings = false;

      modesetting.enable = true;
      # Power management is required to get nvidia GPUs to behave on
      # suspend, due to firmware bugs. Aren't nvidia great?
      powerManagement.enable = true;
      open = true;
    };
  };

  environment.variables = {
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    WLR_NO_HARDWARE_CURSORS = "1";
  };
}
