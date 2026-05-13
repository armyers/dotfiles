#!/opt/local/bin/bash
# Watches for the Logitech USB Receiver. When it appears (absent → present),
# kickstarts the kanata-logitech daemon so kanata grabs the newly-connected
# keyboard. Loaded by /Library/LaunchDaemons/com.user.kanata-logitech-watcher.plist

LIST_CMD="/opt/homebrew/opt/kanata/bin/kanata --list"
TARGET_HASH="0x332291CC636E3094" # Logitech USB Receiver (vendor 1133 / product 50504)
SERVICE="system/com.user.kanata-logitech"
POLL_SECS=2

prev=""
while true; do
  if "$LIST_CMD" 2>&1 | grep -q "$TARGET_HASH"; then
    cur="present"
  else
    cur="absent"
  fi

  if [[ $prev == "absent" ]] && [[ $cur == "present" ]]; then
    /bin/launchctl kickstart -k "$SERVICE"
  fi

  prev="$cur"
  sleep "$POLL_SECS"
done
