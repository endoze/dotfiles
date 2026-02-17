# NVIDIA drivers for headless server (no GUI)
# GPU passthrough to k3s via CDI (Container Device Interface)
{ config, pkgs, lib, ... }:

{
  boot = {
    initrd.kernelModules = [ "nvidia" ];
    extraModulePackages = [ config.boot.kernelPackages.nvidia_x11 ];
  };

  hardware.nvidia = {
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaSettings = false;  # headless
    modesetting.enable = true;
    powerManagement.enable = false;
    # Keep GPU driver loaded at all times (eliminates cold-start latency for CUDA containers)
    nvidiaPersistenced = true;
  };

  boot.extraModprobeConfig = ''
    options nvidia NVreg_UsePageAttributeTable=1
  '';

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = false;
    extraPackages = with pkgs; [ libva-vdpau-driver libvdpau-va-gl ];
  };

  # CDI spec generated at /var/run/cdi/nvidia-container-toolkit.json
  hardware.nvidia-container-toolkit = {
    enable = true;
    mount-nvidia-executables = true;
  };

  environment.systemPackages = with pkgs; [
    nvidia-container-toolkit
  ];
}
