#!/opt/local/bin/bash
# Watches for the Logitech MX MCHNCL keyboard. When it appears (absent → present),
# kickstarts the kanata-logitech daemon so kanata grabs it. Loaded by
# /Library/LaunchDaemons/com.user.kanata-logitech-watcher.plist
#
# Matches by device NAME, not hash: kanata's per-device hash drifts across
# reconnects/reboots (e.g. 0x332291CC… → 0x172DE50E…), which silently blinded
# this watcher and left the Logitech un-grabbed until a manual restart.

LIST_CMD="/opt/homebrew/opt/kanata/bin/kanata --list"
TARGET="MX MCHNCL" # product name from `kanata --list` (stable; Logitech vendor 1133)
SERVICE="system/com.user.kanata-logitech"
POLL_SECS=2

# Start as "absent" so a device already present when the watcher launches still
# triggers a kickstart. This recovers the boot race where kanata-logitech starts
# before the USB keyboard finishes enumerating and gives up ("doesn't match any
# connected device").
prev="absent"
while true; do
  if "$LIST_CMD" 2>&1 | grep -q "$TARGET"; then
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
