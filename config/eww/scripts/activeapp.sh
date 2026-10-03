#!/usr/bin/env bash
# Emit a friendly app name for the focused window (bar "app menu" title).

pretty() {
  local class="$1"
  case "$class" in
    "") echo "Desktop" ;;
    com.mitchellh.ghostty) echo "Ghostty" ;;
    firefox*) echo "Firefox" ;;
    org.gnome.Nautilus) echo "Files" ;;
    discord) echo "Discord" ;;
    steam) echo "Steam" ;;
    Slack|slack) echo "Slack" ;;
    *) echo "${class##*.}" | sed -E 's/^(.)/\U\1/' ;;
  esac
}

emit() {
  pretty "$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // ""')"
}

emit

SOCKET_PATH="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
socat -U - "UNIX-CONNECT:${SOCKET_PATH}" | while read -r line; do
  case "$line" in
    activewindow\>\>*|workspace*|closewindow*) emit ;;
  esac
done
