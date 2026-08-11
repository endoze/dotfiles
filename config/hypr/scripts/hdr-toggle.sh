#!/usr/bin/env bash

# The SDR call spells out bitdepth/cm/sdrbrightness explicitly: re-issuing a
# monitor rule merges into the existing one, so the HDR values have to be reset
# by hand rather than dropped.
MONITOR_DESC="desc:Acer Technologies Acer X27 #ASOSpDuqCRrd"
BASE='output = "'"${MONITOR_DESC}"'", mode = "3840x2160@144", position = "0x0", scale = 1.33'
SDR="hl.monitor({ ${BASE}, bitdepth = 8, cm = \"srgb\", sdrbrightness = 1.0 })"
HDR="hl.monitor({ ${BASE}, bitdepth = 10, cm = \"hdr\", sdrbrightness = 3.0 })"

CURRENT=$(hyprctl monitors -j | jq -r '.[] | select(.name == "DP-3") | .colorManagementPreset')

if [ "$CURRENT" = "hdr" ]; then
  hyprctl eval "$SDR" >/dev/null
  notify-send -a "HDR" -i display "HDR off" "Monitor back to SDR 8-bit"
else
  hyprctl eval "$HDR" >/dev/null
  notify-send -a "HDR" -i display "HDR on" "HDR10 + 10-bit, SDR brightness 3.0x"
fi
