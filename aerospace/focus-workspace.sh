#!/bin/bash
# Switch to workspace and force-focus a window in it.
# Usage: focus-workspace.sh <workspace>
# This works around macOS activating the wrong Chrome window
# when multiple Chrome windows exist across workspaces,
# and also handles the case where closing a window leaves
# no focused window on the current workspace.

WS="$1"
CURRENT_WS=$(aerospace list-workspaces --focused 2> /dev/null)

if [ "$CURRENT_WS" = "$WS" ]; then
  # Already on target workspace — macOS may have lost focus.
  # Activate the app directly via osascript to bypass the race condition.
  APP=$(aerospace list-windows --workspace "$WS" --format '%{app-name}' 2> /dev/null | head -1)
  if [ -n "$APP" ]; then
    osascript -e "tell application \"$APP\" to activate" &
    sleep 0.15
  fi
fi

aerospace workspace "$WS" 2> /dev/null
sleep 0.15

WIN_ID=$(aerospace list-windows --workspace "$WS" --format '%{window-id}' 2> /dev/null | head -1)
if [ -n "$WIN_ID" ]; then
  aerospace focus --window-id "$WIN_ID" 2> /dev/null
fi
