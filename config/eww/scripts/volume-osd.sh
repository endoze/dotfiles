#!/usr/bin/env bash

# Single OSD for audio: speaker volume/mute and microphone mute. Shows a glass
# capsule under the menu bar (widgets/volume-osd.yuck) for two seconds.
#
# Usage: volume-osd.sh raise|lower|mute|micmute|noop

TIMER_PID_FILE="/tmp/eww-vol-osd-timer.pid"

action="$1"
kind="vol"

case "$action" in
  raise)   wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+ ;;
  lower)   wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%- ;;
  mute)    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  micmute) wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle; kind="mic" ;;
  noop)    ;; # just refresh the OSD (used by the slider's onchange)
esac

if [ "$kind" = "mic" ]; then
  target=@DEFAULT_AUDIO_SOURCE@
else
  target=@DEFAULT_AUDIO_SINK@
fi
output=$(wpctl get-volume "$target" 2>/dev/null)
device=$(wpctl inspect "$target" 2>/dev/null | awk -F'"' '/node.description/ { print $2; exit }')
muted=false
echo "$output" | grep -q "MUTED" && muted=true
vol=$(echo "$output" | awk '{printf "%.0f", $2 * 100}')

if [ "$kind" = "mic" ]; then
  if [ "$muted" = true ]; then icon="󰍭"; else icon="󰍬"; fi
elif [ "$muted" = true ] || [ "$vol" -le 0 ]; then
  icon="󰝟"
elif [ "$vol" -le 30 ]; then
  icon="󰕿"
elif [ "$vol" -le 70 ]; then
  icon="󰖀"
else
  icon="󰕾"
fi

shown="$vol"; [ "$muted" = true ] && shown=0
eww update vol_osd_icon="$icon" vol_osd_value="$shown" vol_osd_muted="$muted" vol_osd_kind="$kind" vol_osd_device="$device" vol_osd_open=true

# Only open if not already visible (re-opening causes a flash)
if ! eww active-windows | grep -q "volume-osd"; then
  eww open volume-osd
fi

if [ -f "$TIMER_PID_FILE" ]; then
  kill "$(cat "$TIMER_PID_FILE")" 2>/dev/null
fi
(sleep 2 && eww close volume-osd 2>/dev/null && eww update vol_osd_open=false && rm -f "$TIMER_PID_FILE") &
echo $! > "$TIMER_PID_FILE"
