#!/usr/bin/env bash

output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

if echo "$output" | grep -q "MUTED"; then
  echo "󰝟"
  exit 0
fi

vol=$(echo "$output" | awk '{printf "%.0f", $2 * 100}')

if [ "$vol" -le 0 ]; then
  echo "󰝟"
elif [ "$vol" -le 30 ]; then
  echo "󰕿 ${vol}%"
elif [ "$vol" -le 70 ]; then
  echo "󰖀 ${vol}%"
else
  echo "󰕾 ${vol}%"
fi
