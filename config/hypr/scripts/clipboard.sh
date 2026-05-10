#!/usr/bin/env bash
# Usage: clipboard.sh copy|paste|cut
#
# Defaults to sending XF86Copy/XF86Paste/XF86Cut for universal app support.
# Exceptions for apps that don't respond to XF86 keysyms on Wayland
# and require Ctrl+C/V/X instead.
#
# To find a window's class: hyprctl activewindow -j | jq '.class'

action="$1"
active_class=$(hyprctl activewindow -j | jq -r '.class // empty')

case "$active_class" in
  # firefox: XF86 keysyms are X11-only
  # Claude, discord, Slack, r2modman: Electron apps
  # steam: native app without XF86 support
  # google-chrome, chromium: Chromium browser
  firefox|Claude|discord|Slack|r2modman|steam|google-chrome|chromium)
    case "$action" in
      copy)  hyprctl dispatch sendshortcut "ctrl, c, activewindow" ;;
      paste) hyprctl dispatch sendshortcut "ctrl, v, activewindow" ;;
      cut)   hyprctl dispatch sendshortcut "ctrl, x, activewindow" ;;
    esac
    ;;
  # Default: use XF86 keysyms for all other apps (GTK, Qt, terminals, etc.)
  *)
    case "$action" in
      copy)  wtype -k XF86Copy ;;
      paste) wtype -k XF86Paste ;;
      cut)   wtype -k XF86Cut ;;
    esac
    ;;
esac
