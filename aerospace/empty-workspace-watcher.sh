#!/bin/bash
# Background watcher: if the focused workspace becomes empty
# (window count drops from >0 to 0), switch to previous workspace.
# Started by aerospace after-startup-command.

PREV_COUNT=1
PREV_WS=""

while true; do
  sleep 0.5

  WS=$(aerospace list-workspaces --focused 2> /dev/null)
  COUNT=$(aerospace list-windows --workspace "$WS" --count 2> /dev/null)

  # Only bounce if count dropped to 0 on the SAME workspace (window closed)
  # Not when we just arrived at an already-empty workspace
  if [ "$COUNT" = "0" ] && [ "$PREV_COUNT" != "0" ] && [ "$WS" = "$PREV_WS" ]; then
    aerospace workspace-back-and-forth
  fi

  PREV_COUNT="$COUNT"
  PREV_WS="$WS"
done
