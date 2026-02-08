# ZFS pool management module for NixOS
# Provides ZFS support with auto-scrub, snapshots, and SSD trim
{ config, pkgs, lib, ... }:

{
  boot = {
    # Enable ZFS filesystem support
    supportedFilesystems = [ "zfs" ];

    # Don't force import root - safer with cache devices
    # ZFS will use the cachefile for imports
    zfs.forceImportRoot = false;

    # Allow importing pools that were last used on different hostids
    # Useful for migration scenarios
    zfs.forceImportAll = false;

    # Explicitly import the hermes pool during boot
    # Required since root is not on ZFS
    zfs.extraPools = [ "hermes" ];
  };

  services.zfs = {
    # Enable automatic scrubbing (data integrity checks)
    autoScrub = {
      enable = true;
      # Monthly scrub schedule
      interval = "monthly";
    };

    # Enable automatic snapshots
    autoSnapshot = {
      enable = true;
      # Keep frequent snapshots for quick recovery
      frequent = 4;    # Every 15 minutes, keep 4
      hourly = 24;     # Keep 24 hourly snapshots
      daily = 7;       # Keep 7 daily snapshots
      weekly = 4;      # Keep 4 weekly snapshots
      monthly = 12;    # Keep 12 monthly snapshots
    };

    # Enable TRIM for SSDs (cache devices)
    trim = {
      enable = true;
      interval = "weekly";
    };
  };

  # ZFS-related packages
  environment.systemPackages = with pkgs; [
    zfs
    # Useful ZFS utilities
    smartmontools  # For monitoring disk health
    lsscsi         # List SCSI devices
  ];

  # Ensure ZFS services start properly
  systemd.services.zfs-import-cache = {
    after = [ "local-fs-pre.target" ];
    before = [ "local-fs.target" ];
  };
}
