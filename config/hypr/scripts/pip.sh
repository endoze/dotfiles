#!/usr/bin/env bash

PIP_WIDTH=640
PIP_HEIGHT=360
GAP=20

# Get active monitor name from current workspace
MONITOR=$(hyprctl activeworkspace -j | jq -r '.monitor')

# Get monitor info: logical resolution and reserved space (accounts for eww bar)
MONITOR_INFO=$(hyprctl monitors -j | jq --arg m "$MONITOR" '.[] | select(.name == $m)')
WIDTH=$(echo "$MONITOR_INFO" | jq -r '(.width / .scale) | floor')
RESERVED_TOP=$(echo "$MONITOR_INFO" | jq -r '.reserved[1]')

# Top-right position
X=$((WIDTH - PIP_WIDTH - GAP))
Y=$((RESERVED_TOP + GAP))

FLOATING=$(hyprctl activewindow -j | jq -r '.floating')

if [ "$FLOATING" = "true" ]; then
  hyprctl dispatch pin
  hyprctl dispatch togglefloating
else
  hyprctl dispatch togglefloating
  hyprctl dispatch pin
  hyprctl dispatch resizeactive exact $PIP_WIDTH $PIP_HEIGHT
  hyprctl dispatch moveactive exact $X $Y
fi
