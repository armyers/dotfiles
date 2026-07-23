#!/bin/bash
# Clean-restart all three kanata daemons. Triggered by the com.user.kanata-reset
# LaunchDaemon (QueueDirectories on ~/.local/state/kanata), which the Hammerspoon
# menu-bar item pokes by creating the request file below.
#
# Uses bootout + bootstrap (graceful SIGTERM, then relaunch), NOT `kickstart -k`
# (SIGKILL): a hard kill can leave the device grab / Karabiner driver wedged and
# send kanata into a SIGTRAP crash-loop. bootout lets kanata release cleanly.

REQ="/Users/allenmyers/.local/state/kanata/reset.request"

# QueueDirectories launches this job whenever the watched dir is non-empty and
# keeps launching until it's emptied — so remove the request file up front to
# stop a relaunch loop, and no-op if it's already gone (the dir is empty at
# install/boot, which is what keeps those from triggering a spurious reset).
[ -e "$REQ" ] || exit 0
rm -f "$REQ"

SERVICES="com.user.kanata-builtin com.user.kanata-logitech com.user.kanata-logitech-watcher"

for svc in $SERVICES; do
  /bin/launchctl bootout "system/$svc" 2> /dev/null
done
sleep 1
for svc in $SERVICES; do
  if /bin/launchctl bootstrap system "/Library/LaunchDaemons/$svc.plist" 2> /dev/null; then
    echo "$svc: reset"
  else
    echo "$svc: bootstrap failed"
  fi
done
echo "kanata daemons reset (clean bootout+bootstrap)"
