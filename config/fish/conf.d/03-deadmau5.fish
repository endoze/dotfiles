if test "$hostname" = deadmau5
  # Recover login after a session-lock crash. When monban-lock dies while the
  # session is locked, Hyprland refuses to hand the lock surface to a new client
  # unless misc.allow_session_lock_restore is on, and hyprland.lua leaves it off,
  # so the screen stays locked with nothing there to accept a password. Flip the
  # option on the live compositor, then hand the lock back to a fresh monban-lock.
  function fixlock -d "Recover Hyprland login after a session-lock crash"
    hyprctl --instance 0 eval 'hl.config({ misc = { allow_session_lock_restore = true } })'
    and systemctl --user restart monban-lock.service
  end
end
