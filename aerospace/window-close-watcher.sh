#!/bin/bash
# Background watcher: detect when a window closes on the current workspace.
#   - Last window closed  → switch to previous workspace
#   - Other windows remain → refocus the first remaining window
# Started by aerospace after-startup-command.

PREV_COUNT=""
PREV_WS=""

while true; do
  sleep 0.5

  WS=$(aerospace list-workspaces --focused 2> /dev/null)
  COUNT=$(aerospace list-windows --workspace "$WS" --count 2> /dev/null)

  # Only act when a window disappeared from the SAME workspace
  if [ "$WS" = "$PREV_WS" ] && [ -n "$PREV_COUNT" ] \
    && [ "$PREV_COUNT" -gt "$COUNT" ] 2> /dev/null; then

    if [ "$COUNT" -eq 0 ]; then
      aerospace workspace-back-and-forth
    else
      sleep 0.2
      APP=$(aerospace list-windows --workspace "$WS" --format '%{app-name}' 2> /dev/null | head -1)
      if [ -n "$APP" ]; then
        osascript -e "tell application \"$APP\" to activate" &
      fi
      sleep 0.15
      WIN_ID=$(aerospace list-windows --workspace "$WS" --format '%{window-id}' 2> /dev/null | head -1)
      if [ -n "$WIN_ID" ]; then
        aerospace focus --window-id "$WIN_ID" 2> /dev/null
      fi
    fi
  fi

  PREV_COUNT="$COUNT"
  PREV_WS="$WS"
done
