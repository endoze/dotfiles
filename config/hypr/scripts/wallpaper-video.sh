#!/usr/bin/env bash

pgrep -f mpvpaper && pkill -f mpvpaper && exit 0

VIDEO_DIR="$HOME/Videos/Wallpapers"
VIDEO=$(find "$VIDEO_DIR" -type f | shuf -n 1)

if [[ -z "$VIDEO" ]]; then
  notify-send "Video Wallpaper" "No videos found in $VIDEO_DIR"
  exit 1
fi

mpvpaper -f -o "no-audio loop" '*' "$VIDEO"
