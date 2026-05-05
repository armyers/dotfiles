#!/opt/local/bin/bash
# Cycle audio output and input devices together.
# Dynamically discovers connected devices at runtime.
# Pairs input to output by matching the first word of the device name.
# Skips virtual devices (ZoomAudioDevice, etc).

SAS="/opt/homebrew/bin/SwitchAudioSource"

# Virtual/software devices to skip
SKIP_PATTERN="ZoomAudioDevice"

# Get real output devices
mapfile -t outputs < <("$SAS" -a -t output | grep -v "$SKIP_PATTERN")

if [[ ${#outputs[@]} -eq 0 ]]; then
  osascript -e 'display notification "No audio devices found" with title "Audio"'
  exit 1
fi

# Get current output device
current=$("$SAS" -c -t output)

# Find current index
current_idx=0
for i in "${!outputs[@]}"; do
  if [[ ${outputs[$i]} == "$current" ]]; then
    current_idx=$i
    break
  fi
done

# Advance to next (wrap around)
next_idx=$(((current_idx + 1) % ${#outputs[@]}))
next_device="${outputs[$next_idx]}"

# Switch output
"$SAS" -s "$next_device" -t output

# Find a matching input device by first word of the device name
first_word="${next_device%% *}"
matching_input=$("$SAS" -a -t input | grep -v "$SKIP_PATTERN" | grep -m1 "^${first_word}")

if [[ -n $matching_input ]]; then
  "$SAS" -s "$matching_input" -t input
fi

# Show notification with result
out=$("$SAS" -c -t output)
inp=$("$SAS" -c -t input)
osascript -e "display notification \"Out: ${out}\nIn: ${inp}\" with title \"🔊 Audio Switched\""
