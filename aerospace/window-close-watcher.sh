#!/bin/bash
# Background watcher: detect when a window closes on the current workspace.
#   - Last window closed  → switch to previous workspace
#   - Other windows remain → refocus the first remaining window
#   - Workspace drift      → macOS focused a window on a different workspace
#                            after a close; detect and switch back
# Started by aerospace after-startup-command.

# Prevent duplicate instances
pidfile="/tmp/window-close-watcher.pid"
if [ -f "$pidfile" ] && kill -0 "$(cat "$pidfile")" 2> /dev/null; then
  exit 0
fi
echo $$ > "$pidfile"

PREV_COUNT=""
PREV_WS=""

while true; do
  sleep 0.5

  WS=$(aerospace list-workspaces --focused 2> /dev/null)
  COUNT=$(aerospace list-windows --workspace "$WS" --count 2> /dev/null)

  # Case 1: window closed on the SAME workspace we're still on
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

  # Case 2: workspace switched unexpectedly — closing a window caused macOS
  # to focus a window on a different workspace. Check if the previous
  # workspace lost a window and still has windows; if so, switch back.
  elif [ "$WS" != "$PREV_WS" ] && [ -n "$PREV_WS" ] && [ -n "$PREV_COUNT" ] \
    && [ "$PREV_COUNT" -gt 0 ] 2> /dev/null; then

    PREV_WS_NOW=$(aerospace list-windows --workspace "$PREV_WS" --count 2> /dev/null)
    if [ -n "$PREV_WS_NOW" ] && [ "$PREV_WS_NOW" -lt "$PREV_COUNT" ] 2> /dev/null \
      && [ "$PREV_WS_NOW" -gt 0 ] 2> /dev/null; then

      sleep 0.2
      aerospace workspace "$PREV_WS" 2> /dev/null
      sleep 0.15
      APP=$(aerospace list-windows --workspace "$PREV_WS" --format '%{app-name}' 2> /dev/null | head -1)
      if [ -n "$APP" ]; then
        osascript -e "tell application \"$APP\" to activate" &
      fi
      sleep 0.15
      WIN_ID=$(aerospace list-windows --workspace "$PREV_WS" --format '%{window-id}' 2> /dev/null | head -1)
      if [ -n "$WIN_ID" ]; then
        aerospace focus --window-id "$WIN_ID" 2> /dev/null
      fi
      # Update WS/COUNT to reflect where we are now
      WS="$PREV_WS"
      COUNT="$PREV_WS_NOW"
    fi
  fi

  PREV_COUNT="$COUNT"
  PREV_WS="$WS"
done
