#!/usr/bin/env bash

# Toggle the cliamp music player: launch it if no window exists, otherwise
# show/hide its special workspace. Matching on the ghostty window class (rather
# than the process name) keeps "is it running" and "is it toggleable" in sync,
# since the class is exactly what the window rule and the toggle act on.

CLASS="com.endoze.cliamp"

if hyprctl clients -j | jq -e --arg c "$CLASS" 'any(.[]; .class == $c)' >/dev/null; then
  hyprctl dispatch 'hl.dsp.workspace.toggle_special("cliamp")'
else
  # gtk-single-instance defaults to `detect`, which can hand the window to an
  # existing ghostty instance and drop the custom class along with it.
  exec ghostty --class="$CLASS" --gtk-single-instance=false --font-size=16 -e cliamp
fi
