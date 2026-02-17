# Hardware configuration for dosvec
#
# Disk Layout:
# ============
# nvme0n1 (ADATA SX6000LNP 476.9GB) - NixOS root filesystem
#   - Part 1 (1.5GB): EFI boot partition (NIXBOOT)
#   - Part 2 (475.4GB): ext4 root partition (nixos-root)
#
# sda (WL2000GSA6472 2TB) - Available for repurposing
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
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams = [
    "pcie_aspm=off"
    "zfs.zfs_arc_max=8589934592"  # 8 GB — limits ARC to reduce total ZFS memory footprint
  ];
  boot.extraModulePackages = [ ];

  # Root filesystem on nvme0n1
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/8df19d25-2171-4256-8eef-ef3fab4f4246";
      fsType = "ext4";
    };

  # EFI boot partition on nvme0n1
  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/DA5E-AC27";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  # Bridge network — enp5s0 bridged to br0 with static IP
  # Required for Plex (hardcodes 192.168.1.104:32400) and LAN-addressable VMs
  networking.useDHCP = false;
  networking.bridges.br0.interfaces = [ "enp5s0" ];
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
