#!/usr/bin/env bash

pgrep -x "wf-recorder" && pkill -INT -x wf-recorder && notify-send -h string:wf-recorder:record -t 3000 "Finished Recording" && exit 0

dateTime=$(date +%Y-%m-%d-%H:%M:%S)

if [ "$1" == "slurp" ]; then
  region="$(slurp)"
else
  notify-send -h string:wf-recorder:record -t 1000 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>3</b></i></span>"

  sleep 1

  notify-send -h string:wf-recorder:record -t 1000 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>2</b></i></span>"

  sleep 1

  notify-send -h string:wf-recorder:record -t 950 "Recording in:" "<span color='#90a4f4' font='26px'><i><b>1</b></i></span>"

  sleep 1
fi

if [ "$1" == "slurp" ]; then
  wf-recorder --bframes max_b_frames -g "$region" -f "$HOME/Pictures/screenshots/${dateTime}_wf-recorder.mp4"
else 
  wf-recorder --bframes max_b_frames -f "$HOME/Pictures/screenshots/${dateTime}_wf-recorder.mp4"
fi
