# Google Coral USB TPU driver support for NixOS
# Provides kernel modules and udev rules for Coral USB Accelerator
{ config, pkgs, lib, userConfig, ... }:

{
  # Load required kernel modules for Coral USB TPU
  boot.extraModulePackages = with config.boot.kernelPackages; [
    # gasket-dkms provides the gasket driver for Coral devices
    # Note: If gasket is not available in nixpkgs, you may need to use
    # the apex kernel module or build gasket from source
  ];

  boot.kernelModules = [
    # "gasket"  # Gasket driver for Coral PCIe/M.2
    # "apex"    # Apex driver for Coral USB
  ];

  # udev rules for USB Coral devices
  # Allows non-root users in the 'coral' group to access the device
  services.udev.extraRules = ''
    # Google Coral USB Accelerator (runtime mode)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", ATTRS{idProduct}=="089a", MODE="0664", GROUP="coral"

    # Google Coral USB Accelerator (DFU/bootloader mode)
    SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", ATTRS{idProduct}=="9302", MODE="0664", GROUP="coral"

    # Additional Coral device IDs
    SUBSYSTEM=="usb", ATTRS{idVendor}=="1a6e", MODE="0664", GROUP="coral"
    SUBSYSTEM=="usb", ATTRS{idVendor}=="18d1", MODE="0664", GROUP="coral"
  '';

  # Create coral group for device access
  users.groups.coral = { };

  # Add user to coral group
  users.users.${userConfig.username}.extraGroups = [ "coral" ];

  # Install libedgetpu for Coral support
  # Note: libedgetpu may need to be packaged or use a community overlay
  environment.systemPackages = with pkgs; [
    # libedgetpu  # Edge TPU runtime library (if available in nixpkgs)
    usbutils      # lsusb for debugging
  ];

  # For Frigate and other ML workloads using Coral:
  # The container will need privileged access to /dev/bus/usb
  # or specific device mounts for the Coral USB device
}
