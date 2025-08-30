{ config, pkgs, lib, userConfig ? {}, systemConfig ? {}, ... }:

{
  # Machine-specific system configuration for Linux desktop
  networking.hostName = systemConfig.hostName or "linux-desktop";

  # Hardware configuration (you'll need to generate this with nixos-generate-config)
  imports = [
    # ./hardware-configuration.nix
  ];

  # Minimal filesystem configuration (replace with actual hardware config)
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  # Enable desktop environment
  services.xserver = {
    enable = true;

    # Configure keymap
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  # Display manager
  services.displayManager.gdm.enable = true;

  # Desktop environment
  services.desktopManager.gnome.enable = true;

  # Enable NVIDIA drivers if needed
  # hardware.nvidia = {
  #   modesetting.enable = true;
  #   powerManagement.enable = true;
  #   open = false;
  #   nvidiaSettings = true;
  #   package = config.boot.kernelPackages.nvidiaPackages.stable;
  # };

  # Enable Docker
  virtualisation.docker = {
    enable = true;
    enableOnBoot = true;
  };

  # Additional groups for desktop user
  users.users.${userConfig.username or "user"}.extraGroups = [ "docker" ];

  # Enable flatpak for additional apps
  services.flatpak.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;

  # Additional system packages
  environment.systemPackages = with pkgs; [
  ];
}
