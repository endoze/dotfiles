#!/usr/bin/env bash

# Usage: volume-osd.sh raise|lower|mute|noop

TIMER_PID_FILE="/tmp/eww-vol-osd-timer.pid"

action="$1"

case "$action" in
  raise) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  lower) wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute)  wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  noop)  ;; # just refresh the OSD (used by slider onchange)
esac

# Read current state
output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)
muted=false
if echo "$output" | grep -q "MUTED"; then
  muted=true
fi
vol=$(echo "$output" | awk '{printf "%.0f", $2 * 100}')

# Pick icon
if [ "$muted" = true ] || [ "$vol" -le 0 ]; then
  icon="󰝟"
elif [ "$vol" -le 30 ]; then
  icon="󰕿"
elif [ "$vol" -le 70 ]; then
  icon="󰖀"
else
  icon="󰕾"
fi

# Update eww variables and show the OSD
eww update vol_osd_icon="$icon" vol_osd_value="$vol" vol_osd_muted="$muted"

# Only open if not already visible (re-opening causes a flash)
if ! eww active-windows | grep -q "volume-osd"; then
  eww open volume-osd
fi

# Cancel any previous auto-close timer
if [ -f "$TIMER_PID_FILE" ]; then
  kill "$(cat "$TIMER_PID_FILE")" 2>/dev/null
fi

# Start a new auto-close timer
(sleep 2 && eww close volume-osd 2>/dev/null && rm -f "$TIMER_PID_FILE") &
echo $! > "$TIMER_PID_FILE"
