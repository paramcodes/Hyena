
# Internal microphone boost settings
amixer -c 1 sset 'Internal Mic Boost' 3
pactl set-source-volume alsa_input.pci-0000_00_1b.0.analog-stereo 65536
pactl set-source-port alsa_input.pci-0000_00_1b.0.analog-stereo analog-input-internal-mic
pactl set-default-source alsa_input.pci-0000_00_1b.0.analog-stereo

