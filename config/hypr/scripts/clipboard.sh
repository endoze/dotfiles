#!/usr/bin/env bash
# Usage: clipboard.sh copy|paste
#
# Defaults to sending XF86Copy/XF86Paste for universal app support.
# Exceptions for apps that don't respond to XF86 keysyms on Wayland
# and require Ctrl+C/V instead.
#
# To find a window's class: hyprctl activewindow -j | jq '.class'

action="$1"
active_class=$(hyprctl activewindow -j | jq -r '.class // empty')

case "$active_class" in
  # Firefox: XF86Copy/Paste support is X11-only, not Wayland
  # Claude: Electron app, requires Ctrl+C/V
  # Discord: Electron app, requires Ctrl+C/V
  # Slack: Electron app, requires Ctrl+C/V
  # r2modman: Electron app, requires Ctrl+C/V
  # Steam: requires Ctrl+C/V
  firefox|Claude|discord|Slack|r2modman|steam)
    if [[ "$action" == "copy" ]]; then
      hyprctl dispatch sendshortcut ctrl, c,
    else
      hyprctl dispatch sendshortcut ctrl, v,
    fi
    ;;
  # Default: use XF86Copy/Paste for all other apps (GTK, Qt, terminals, etc.)
  *)
    if [[ "$action" == "copy" ]]; then
      wtype -k XF86Copy
    else
      wtype -k XF86Paste
    fi
    ;;
esac
