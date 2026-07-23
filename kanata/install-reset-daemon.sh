#!/bin/bash
# Install (or reinstall) the mouse-driven kanata reset LaunchDaemon.
#
# This is the ONLY step that needs sudo. Afterward, resetting the kanata daemons
# is password-free and keyboard-free: the Hammerspoon menu-bar item creates the
# request file, and this root daemon reacts to it via WatchPaths.
#
# Run:  sudo ~/.config/kanata/install-reset-daemon.sh
set -euo pipefail

LABEL="com.user.kanata-reset"
SRC="/Users/allenmyers/.config/kanata/${LABEL}.plist"
DST="/Library/LaunchDaemons/${LABEL}.plist"
USER_NAME="${SUDO_USER:-allenmyers}"
STATE_DIR="/Users/${USER_NAME}/.local/state/kanata"

if [[ $EUID -ne 0 ]]; then
  echo "run with sudo: sudo $0" >&2
  exit 1
fi

# Create the watched DIRECTORY (user-owned; the menu-bar item writes the request
# file into it). Do NOT create the request file — its absence keeps the daemon
# idle at install and boot; only a menu-bar click creates it and triggers a reset.
install -d -o "$USER_NAME" -g staff "$STATE_DIR"
rm -f "$STATE_DIR/reset.request"

cp "$SRC" "$DST"
chown root:wheel "$DST"
chmod 644 "$DST"

# Reload cleanly if a previous copy is already bootstrapped.
launchctl bootout system "$DST" 2> /dev/null || true
launchctl bootstrap system "$DST"

echo "installed $LABEL — watching $STATE_DIR"
echo "(idle until the Hammerspoon menu-bar item is clicked)"
