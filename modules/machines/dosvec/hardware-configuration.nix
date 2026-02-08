# Hardware configuration for dosvec
#
# Disk Layout:
# ============
# sda (WL2000GSA6472 2TB) - NixOS root filesystem
#   - Part 1 (512MB): EFI boot partition
#   - Part 2 (1.8TB): ext4 root partition
#
# nvme0n1 (ADATA SX6000LNP) - Ubuntu (dual boot, will be removed later)
#
# ZFS Pool "hermes" (RAIDZ2 + SSD Cache):
#   RAIDZ2 vdevs (5x 8TB WD):
#     - sdf: ata-WDC_WD80EFZZ-68BTXN0_WD-CA3VJKLK
#     - sdd: ata-WDC_WD80EFPX-68C4ZN0_WD-RD0R63AE
#     - sdg: ata-WDC_WD80EFPX-68C4ZN0_WD-RD0P946E
#     - sdh: ata-WDC_WD80EFZZ-68BTXN0_WD-CA3VT3LK
#     - sde: ata-WDC_WD80EFPX-68C4ZN0_WD-RD0RSLRE
#   Cache vdevs (2x 4TB Samsung SSD):
#     - sdb: ata-Samsung_SSD_870_EVO_4TB_S6BBNG0R300883L
#     - sdc: ata-Samsung_SSD_870_EVO_4TB_S6BBNG0R300885V
#
# ZFS Pool Mounting:
# ==================
# The hermes pool is imported via boot.zfs.extraPools in zfs.nix
# ZFS handles mounting automatically using dataset mountpoint properties
# No fileSystems entries needed - avoids double-mount conflicts

{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  # Kernel modules for hardware support
  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usbhid" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams = [ "pcie_aspm=off" ];
  boot.extraModulePackages = [ ];

  # Root filesystem on sda
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/4c7bd085-72bc-42b3-9f86-0c9a296fe9cc";
      fsType = "ext4";
    };

  # EFI boot partition on sda
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/99A6-0294";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  # Bridge network — enp3s0 bridged to br0 with static IP
  # Required for Plex (hardcodes 192.168.1.104:32400) and LAN-addressable VMs
  networking.useDHCP = false;
  networking.bridges.br0.interfaces = [ "enp3s0" ];
  networking.interfaces.br0 = {
    ipv4.addresses = [{
      address = "192.168.1.104";
      prefixLength = 24;
    }];
  };
  networking.defaultGateway = "192.168.1.1";
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";

  # Intel CPU microcode updates
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
