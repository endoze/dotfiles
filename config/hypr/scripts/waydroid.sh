#!/usr/bin/env bash

# Toggle the Waydroid (Android) full UI: launch it if no window exists,
# otherwise show/hide its special workspace. Matching on the window class
# (rather than the process name) keeps "is it running" and "is it toggleable"
# in sync, since the class is exactly what the window rule and the toggle act
# on. Waydroid sets waydroid.active_apps to "Waydroid" for the full UI, which
# is where this class comes from.
#
# Hiding on the special workspace is the intended way to dismiss this window:
# the Android surface ignores ordinary close requests, so `closewindow` reports
# success without doing anything. `waydroid session stop` is what tears it down.

CLASS="Waydroid"

if hyprctl clients -j | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null; then
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("waydroid")'
else
  # No pre-flight needed: show-full-ui goes through maybeLaunchLater, which
  # starts a session when none is running. It also unfreezes a frozen
  # container, though waydroid-nvidia-setup sets suspend_action = none, so the
  # guest won't have frozen itself in the first place.
  exec waydroid show-full-ui
fi
