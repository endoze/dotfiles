#!/usr/bin/env bash

MONITOR_DESC="desc:Acer Technologies Acer X27 ##ASOSpDuqCRrd"
SDR="${MONITOR_DESC},3840x2160@144,0x0,1.5"
HDR="${MONITOR_DESC},3840x2160@144,0x0,1.5,bitdepth,10,cm,hdr,sdrbrightness,3.0"

CURRENT=$(hyprctl monitors -j | jq -r '.[] | select(.name == "DP-3") | .colorManagementPreset')

if [ "$CURRENT" = "hdr" ]; then
  hyprctl keyword monitor "$SDR" >/dev/null
  notify-send -a "HDR" -i display "HDR off" "Monitor back to SDR 8-bit"
else
  hyprctl keyword monitor "$HDR" >/dev/null
  notify-send -a "HDR" -i display "HDR on" "HDR10 + 10-bit, SDR brightness 3.0x"
fi
