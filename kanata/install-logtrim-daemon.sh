#!/bin/bash
# Install (or reinstall) the hourly kanata log-trimming LaunchDaemon.
#
# The kanata logs are launchd StandardOutPath targets owned by root, so trimming
# them has to happen as root — hence a daemon rather than a user cron/agent.
# See trim-kanata-logs.sh for why in-place truncation is used over newsyslog.
#
# Run:  sudo ~/.config/kanata/install-logtrim-daemon.sh
set -euo pipefail

LABEL="com.user.kanata-logtrim"
SRC="/Users/allenmyers/.config/kanata/${LABEL}.plist"
DST="/Library/LaunchDaemons/${LABEL}.plist"

if [[ $EUID -ne 0 ]]; then
  echo "run with sudo: sudo $0" >&2
  exit 1
fi

cp "$SRC" "$DST"
chown root:wheel "$DST"
chmod 644 "$DST"

# Reload cleanly if a previous copy is already bootstrapped.
launchctl bootout system "$DST" 2> /dev/null || true
launchctl bootstrap system "$DST"

echo "installed $LABEL — trims /opt/homebrew/var/log/kanata*.log hourly"
echo "(RunAtLoad means the first pass has already run; see kanata-logtrim.log)"
