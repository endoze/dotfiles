if test "$hostname" = RVL-MBP-0103
  # The external 2TB disk's encrypted APFS volume. /etc/fstab mounts it on
  # ~/Projects by this UUID.
  set -g __projects_volume 2D41067C-0975-415A-A8B2-498616A0FC80

  function __projects_info -a key
    diskutil info -plist $__projects_volume 2>/dev/null | plutil -extract $key raw -o - - 2>/dev/null
  end

  function __herdr_running
    herdr status server 2>/dev/null | string match -q "status: running"
  end

  function undock -d "Stop OrbStack and the herdr server, then eject the Projects disk"
    if set -q HERDR_ENV
      echo "undock: run this outside herdr, stopping its server kills this shell" >&2
      return 1
    end

    set -l store (__projects_info APFSPhysicalStores.0.APFSPhysicalStore)
    or begin
      echo "undock: Projects disk is not attached" >&2
      return 1
    end
    set -l disk (diskutil info -plist $store | plutil -extract ParentWholeDisk raw -o - -)

    if test "$PWD" = "$HOME/Projects"; or string match -q -- "$HOME/Projects/*" $PWD
      cd ~
    end

    if __herdr_running
      herdr server stop; or return 1
      while __herdr_running
        sleep 0.5
      end
    end

    orbctl stop; or return 1
    diskutil eject $disk
  end

  function dock -d "Unlock and mount the Projects disk, then start OrbStack and the herdr server"
    if not __projects_info VolumeUUID >/dev/null
      echo "dock: Projects disk is not attached" >&2
      return 1
    end

    if test (__projects_info Locked) = true
      diskutil apfs unlockVolume $__projects_volume; or return 1
    end

    if test -z "$(__projects_info MountPoint)"
      diskutil mount $__projects_volume; or return 1
    end

    if test "$(__projects_info MountPoint)" != "$HOME/Projects"
      echo "dock: Projects disk is not mounted on ~/Projects" >&2
      return 1
    end

    orbctl start; or return 1

    if not __herdr_running
      herdr server </dev/null &>/dev/null &
      disown
      for i in (seq 20)
        __herdr_running; and break
        sleep 0.5
      end
      if not __herdr_running
        echo "dock: herdr server did not start" >&2
        return 1
      end
    end
  end
end
