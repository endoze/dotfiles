#!/usr/bin/env bash

get_workspaces() {
  active=$(hyprctl activeworkspace -j | jq '.id')
  occupied=$(hyprctl workspaces -j | jq '[.[].id]')

  result="["
  for i in 1 2 3 4 5; do
    is_active=$( [ "$i" = "$active" ] && echo "true" || echo "false" )
    is_occupied=$(echo "$occupied" | jq "any(. == $i)")
    [ "$i" -gt 1 ] && result+=","
    result+="{\"id\":$i,\"active\":$is_active,\"occupied\":$is_occupied}"
  done
  result+="]"
  echo "$result"
}

# Initial state
get_workspaces

# Listen for workspace events and re-emit
SOCKET_PATH="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
socat -U - "UNIX-CONNECT:${SOCKET_PATH}" | while read -r line; do
  case "$line" in
    workspace*|focusedmon*|createworkspace*|destroyworkspace*|moveworkspace*)
      get_workspaces
      ;;
  esac
done
