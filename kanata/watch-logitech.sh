#!/opt/local/bin/bash
# Owns the lifecycle of the kanata-logitech daemon: starts it when the Logitech
# MX MCHNCL is present, leaves it stopped when it isn't. Loaded by
# /Library/LaunchDaemons/com.user.kanata-logitech-watcher.plist
#
# Matches by device NAME, not hash: kanata's per-device hash drifts across
# reconnects/reboots (e.g. 0x332291CC… → 0x172DE50E…), which silently blinded
# this watcher and left the Logitech un-grabbed until a manual restart.
#
# WHY THE DAEMON HAS NO KeepAlive
# ------------------------------------------------------------------
# com.user.kanata-logitech is RunAtLoad=false / KeepAlive=false and is started
# ONLY from here. Under KeepAlive, every moment the Bluetooth keyboard was
# disconnected launchd relaunched kanata, it failed with "Couldn't register any
# device", and launchd relaunched it ~10s later — forever. That burned ~12 MB of
# log per day and buried real errors under hundreds of identical stack-ups.
#
# The condition that should start kanata is "the device is here", which launchd
# cannot see but this loop can. So the retry policy lives here instead.
#
# This check is LEVEL-triggered (device present AND daemon not running), not
# edge-triggered on absent→present as it used to be. That matters: an edge
# trigger misses a kanata crash while the keyboard stays connected (the device
# never re-transitions, so no restart ever fires) and misses a bootout+bootstrap
# from kanata-reset.sh. Level-triggering recovers from both.

LIST_CMD="/opt/homebrew/opt/kanata/bin/kanata --list"
TARGET="MX MCHNCL" # product name from `kanata --list` (stable; Logitech vendor 1133)
SERVICE="system/com.user.kanata-logitech"
CFG_MATCH="kanata-logitech.kbd" # unique to this daemon's command line
POLL_SECS=2

# Exponential backoff so a PERSISTENTLY failing start (revoked TCC permissions
# after a `brew upgrade`, a bad config) degrades to occasional retries instead
# of hammering launchctl every POLL_SECS and re-creating the log flood this
# rewrite exists to kill. See check-permissions.sh for the permissions case.
BACKOFF_MIN=10
BACKOFF_MAX=600

# Only treat the daemon as healthy once it has survived this many consecutive
# polls (~30s). kanata sleeps 2s at startup before grabbing the device, so a
# process that is merely mid-launch must not be allowed to reset the backoff —
# otherwise a fast crash-start-crash cycle never backs off at all.
HEALTHY_POLLS=15

device_present() { "$LIST_CMD" 2>&1 | grep -q "$TARGET"; }
daemon_running() { pgrep -f "$CFG_MATCH" > /dev/null 2>&1; }

backoff=$BACKOFF_MIN
next_attempt=0
running_streak=0

while true; do
  if device_present; then
    if daemon_running; then
      running_streak=$((running_streak + 1))
      if [[ $running_streak -ge $HEALTHY_POLLS ]]; then
        backoff=$BACKOFF_MIN
        next_attempt=0
      fi
    else
      running_streak=0
      now=$(date +%s)
      if [[ $now -ge $next_attempt ]]; then
        # Plain kickstart, never `kickstart -k`: SIGKILL can leave the device
        # grab / Karabiner driver wedged and send kanata into a SIGTRAP
        # crash-loop that only a reboot clears (same reason kanata-reset.sh
        # uses bootout). The daemon is not running here anyway.
        echo "$(date '+%Y-%m-%d %H:%M:%S') starting kanata-logitech (retry in ${backoff}s if it fails)"
        /bin/launchctl kickstart "$SERVICE"
        next_attempt=$((now + backoff))
        backoff=$((backoff * 2))
        [[ $backoff -gt $BACKOFF_MAX ]] && backoff=$BACKOFF_MAX
      fi
    fi
  else
    # Keyboard is away: stay quiet and reset the retry policy so the next
    # connect gets an immediate start rather than an inherited long backoff.
    running_streak=0
    backoff=$BACKOFF_MIN
    next_attempt=0
  fi

  sleep "$POLL_SECS"
done
