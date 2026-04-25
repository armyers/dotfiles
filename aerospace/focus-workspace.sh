#!/bin/bash
# Switch to workspace and force-focus a window in it.
# Usage: focus-workspace.sh <workspace>
# This works around macOS activating the wrong Chrome window
# when multiple Chrome windows exist across workspaces.

WS="$1"
aerospace workspace "$WS" 2>/dev/null

sleep 0.15

WIN_ID=$(aerospace list-windows --workspace "$WS" --format '%{window-id}' 2>/dev/null | head -1)
if [ -n "$WIN_ID" ]; then
  aerospace focus --window-id "$WIN_ID" 2>/dev/null
fi
