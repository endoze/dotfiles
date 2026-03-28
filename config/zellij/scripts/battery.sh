#!/usr/bin/env bash
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/zjstatus"
mkdir -p "$CACHE_DIR"

PCT=$(pmset -g batt | grep -o '[0-9]*%' | head -1 | tr -d '%')
if [ -z "$PCT" ]; then
  echo "N/A" > "$CACHE_DIR/battery_data"
  echo "N/A"
  exit 0
fi
if [ "$PCT" -ge 90 ]; then ICON=$'\U000F0079'    # 󰁹
elif [ "$PCT" -ge 80 ]; then ICON=$'\U000F0082'   # 󰂂
elif [ "$PCT" -ge 70 ]; then ICON=$'\U000F0081'   # 󰂁
elif [ "$PCT" -ge 60 ]; then ICON=$'\U000F0080'   # 󰂀
elif [ "$PCT" -ge 50 ]; then ICON=$'\U000F007F'   # 󰁿
elif [ "$PCT" -ge 40 ]; then ICON=$'\U000F007E'   # 󰁾
elif [ "$PCT" -ge 30 ]; then ICON=$'\U000F007D'   # 󰁽
elif [ "$PCT" -ge 20 ]; then ICON=$'\U000F007C'   # 󰁼
elif [ "$PCT" -ge 10 ]; then ICON=$'\U000F007B'   # 󰁻
else ICON=$'\U000F007A'                            # 󰁺
fi
echo "$PCT%" > "$CACHE_DIR/battery_data"
echo "$ICON"
