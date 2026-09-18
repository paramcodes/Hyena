#!/bin/bash
# Audio setup script for Realtek ALC3234 on Fedora/Hyprland

# Microphone setup
amixer -c 1 sset 'Internal Mic Boost' 3
amixer -c 1 sset 'Internal Mic' on
amixer -c 1 sset 'Capture' 100% on

# Speaker setup  
amixer -c 1 sset 'Speaker' 100% on
amixer -c 1 sset 'Master' 100% on
amixer -c 1 sset 'PCM' 100%
amixer -c 1 sset 'Auto-Mute Mode' Disabled

# PipeWire settings
pactl set-card-profile alsa_card.pci-0000_00_1b.0 output:analog-stereo+input:analog-stereo
pactl set-sink-volume alsa_output.pci-0000_00_1b.0.analog-stereo 65536
pactl set-source-volume alsa_input.pci-0000_00_1b.0.analog-stereo 65536
pactl set-sink-port alsa_output.pci-0000_00_1b.0.analog-stereo analog-output-speaker
pactl set-source-port alsa_input.pci-0000_00_1b.0.analog-stereo analog-input-internal-mic
pactl set-default-sink alsa_output.pci-0000_00_1b.0.analog-stereo
pactl set-default-source alsa_input.pci-0000_00_1b.0.analog-stereo

echo "Audio configuration complete"

