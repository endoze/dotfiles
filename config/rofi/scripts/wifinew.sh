#!/usr/bin/env bash

theme_file="$HOME/.config/rofi/themes/wifi/style.rasi"

declare -A wifi_dict

wifi_list_output=$(nmcli device wifi list | tail -n +2 | awk '{print $1, $2}')

while IFS=' ' read -r bssid ssid; do
  wifi_dict["$ssid"]="$bssid"
done <<< "$wifi_list_output"

chosen_ssid=$(printf "%s\n" "${!wifi_dict[@]}" | rofi -dmenu -theme "${theme_file}" -p " " -lines 10)

[ -z "$chosen_ssid" ] && exit 1

chosen_bssid="${wifi_dict[$chosen_ssid]}"

pass=$(echo "" | rofi -dmenu -theme-str 'textbox-prompt-colon {str: "";}' -theme "${theme_file}" -p "Enter password")

[ -z "$pass" ] && notify-send "🔑 Password not entered" && exit 1

nmcli device wifi connect "$chosen_bssid" password "$pass"
notify-send "📶 New WiFi Connected"
