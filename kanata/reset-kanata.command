#!/bin/bash
# Mouse-only kanata reset — double-clickable from Finder or the Dock.
#
# This is the same trick the Hammerspoon "⌨️ kanata" menu-bar item uses: it just
# creates the request file that the root com.user.kanata-reset LaunchDaemon
# watches (QueueDirectories on ~/.local/state/kanata). That daemon does the
# privileged clean-restart (bootout + bootstrap) of all three kanata daemons.
#
# Because it only touches a file, it needs NO password and NO working keyboard —
# so it recovers a jammed built-in keyboard even when the menu-bar icon is gone.
#
# Finder opens .command files by running them in Terminal on double-click. Keep a
# copy (or alias) on the Desktop or in the Dock for one-click emergency access.

REQ_DIR="$HOME/.local/state/kanata"
mkdir -p "$REQ_DIR"
touch "$REQ_DIR/reset.request"
echo "kanata reset requested — the root daemon will restart all three daemons."
echo "The built-in keyboard should come back within a couple of seconds."
