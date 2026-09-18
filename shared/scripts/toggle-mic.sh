#!/bin/bash
SOURCE="alsa_input.pci-0000_00_1b.0.analog-stereo"

CURRENT=$(pactl list sources | awk -v src="$SOURCE" '
    /^Source #/ { found=0 }
    $0 ~ "Name: " src { found=1 }
    found && /Active Port:/ { print $3; exit }
')

if [ "$CURRENT" = "analog-input-internal-mic" ]; then
  pactl set-source-port "$SOURCE" analog-input-headset-mic
  notify-send "Mic switched to Headset"
else
  pactl set-source-port "$SOURCE" analog-input-internal-mic
  notify-send "Mic switched to Internal"
fi
