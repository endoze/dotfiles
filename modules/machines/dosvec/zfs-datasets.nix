# Declarative ZFS dataset configuration for dosvec
# This module documents and can verify the expected ZFS dataset properties
#
# Pool: hermes (RAIDZ2 + SSD cache)
# ================================
# RAIDZ2 vdevs (5x 8TB WD Red Pro):
#   - ata-WDC_WD80EFZZ-68BTXN0_WD-CA3VJKLK (sdf)
#   - ata-WDC_WD80EFPX-68C4ZN0_WD-RD0R63AE (sdd)
#   - ata-WDC_WD80EFPX-68C4ZN0_WD-RD0P946E (sdg)
#   - ata-WDC_WD80EFZZ-68BTXN0_WD-CA3VT3LK (sdh)
#   - ata-WDC_WD80EFPX-68C4ZN0_WD-RD0RSLRE (sde)
#
# Cache vdevs (2x 4TB Samsung SSD 870 EVO):
#   - ata-Samsung_SSD_870_EVO_4TB_S6BBNG0R300883L (sdb)
#   - ata-Samsung_SSD_870_EVO_4TB_S6BBNG0R300885V (sdc)
#
# Total raw capacity: ~36.4TB, usable: ~21.8TB (RAIDZ2)
#
# IMPORTANT: Mount point migration
# ================================
# Current (Ubuntu): /home/Endoze/Hermes/
# Target (NixOS):   /mnt/hermes
#
# The mount points will be changed during migration by setting the
# mountpoint property on each dataset after import.

{ config, pkgs, lib, ... }:

let
  # Define expected dataset properties
  # These match the current production configuration
  datasets = {
    "hermes" = {
      mountpoint = "/mnt/hermes";
      compression = "lz4";
      atime = "off";
      recordsize = "128K";  # default
    };
    "hermes/Media" = {
      mountpoint = "/mnt/hermes/Media";
      compression = "lz4";
      atime = "off";
      recordsize = "1M";  # Optimized for large media files
    };
    "hermes/backups" = {
      mountpoint = "/mnt/hermes/backups";
      compression = "lz4";
      atime = "off";
      recordsize = "128K";  # default
    };
    "hermes/docker" = {
      mountpoint = "/mnt/hermes/docker";
      compression = "zstd";  # Better compression for container layers
      atime = "off";
      recordsize = "16K";  # Optimized for small container files
    };
    "hermes/vm_isos" = {
      mountpoint = "/mnt/hermes/vm_isos";
      compression = "lz4";
      atime = "off";
      recordsize = "1M";  # Optimized for large ISO files
    };
    "hermes/vm_storage" = {
      mountpoint = "/mnt/hermes/vm_storage";
      compression = "lz4";
      atime = "off";
      recordsize = "64K";  # Balanced for VM disk images
    };
  };

  # Script to verify dataset properties match expected values
  verifyScript = pkgs.writeShellScriptBin "verify-zfs-datasets" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "Verifying ZFS dataset properties..."
    ERRORS=0

    check_prop() {
      local dataset="$1"
      local prop="$2"
      local expected="$3"
      local actual=$(zfs get -H -o value "$prop" "$dataset" 2>/dev/null || echo "ERROR")

      if [[ "$actual" != "$expected" ]]; then
        echo "MISMATCH: $dataset $prop: expected '$expected', got '$actual'"
        ((ERRORS++)) || true
      else
        echo "OK: $dataset $prop = $expected"
      fi
    }

    # hermes
    check_prop "hermes" "compression" "lz4"
    check_prop "hermes" "atime" "off"

    # hermes/Media
    check_prop "hermes/Media" "compression" "lz4"
    check_prop "hermes/Media" "atime" "off"
    check_prop "hermes/Media" "recordsize" "1M"

    # hermes/backups
    check_prop "hermes/backups" "compression" "lz4"
    check_prop "hermes/backups" "atime" "off"

    # hermes/docker
    check_prop "hermes/docker" "compression" "zstd"
    check_prop "hermes/docker" "atime" "off"
    check_prop "hermes/docker" "recordsize" "16K"

    # hermes/vm_isos
    check_prop "hermes/vm_isos" "compression" "lz4"
    check_prop "hermes/vm_isos" "atime" "off"
    check_prop "hermes/vm_isos" "recordsize" "1M"

    # hermes/vm_storage
    check_prop "hermes/vm_storage" "compression" "lz4"
    check_prop "hermes/vm_storage" "atime" "off"
    check_prop "hermes/vm_storage" "recordsize" "64K"

    echo ""
    if [[ $ERRORS -gt 0 ]]; then
      echo "Found $ERRORS mismatches!"
      exit 1
    else
      echo "All dataset properties verified successfully!"
    fi
  '';

  # Script to set mount points after pool import (run once during migration)
  migrateMountpointsScript = pkgs.writeShellScriptBin "migrate-zfs-mountpoints" ''
    #!/usr/bin/env bash
    set -euo pipefail

    echo "This script will migrate ZFS mount points from /home/Endoze/Hermes/ to /mnt/hermes"
    echo "WARNING: This should only be run ONCE during initial NixOS migration!"
    echo ""
    read -p "Are you sure you want to continue? (yes/no): " confirm

    if [[ "$confirm" != "yes" ]]; then
      echo "Aborted."
      exit 1
    fi

    echo "Setting mount points..."

    # Set mount points (ZFS will remount automatically)
    zfs set mountpoint=/mnt/hermes hermes
    zfs set mountpoint=/mnt/hermes/Media hermes/Media
    zfs set mountpoint=/mnt/hermes/backups hermes/backups
    zfs set mountpoint=/mnt/hermes/docker hermes/docker
    zfs set mountpoint=/mnt/hermes/vm_isos hermes/vm_isos
    zfs set mountpoint=/mnt/hermes/vm_storage hermes/vm_storage

    echo ""
    echo "Mount points migrated successfully!"
    zfs list -o name,mountpoint
  '';

in
{
  environment.systemPackages = [
    verifyScript
    migrateMountpointsScript
  ];

  # Create mount point directories
  systemd.tmpfiles.rules = [
    "d /mnt/hermes 0755 root root -"
  ];
}
