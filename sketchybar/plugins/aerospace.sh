#!/bin/bash

# Show the focused AeroSpace workspace with its label.

source "$HOME/.config/aerospace/workspace-labels.sh"

# On startup, FOCUSED_WORKSPACE is empty — query aerospace directly
WS="${FOCUSED_WORKSPACE:-$(aerospace list-workspaces --focused 2> /dev/null)}"
LABEL="$(ws_label "$WS")"

if [ -n "$LABEL" ]; then
  sketchybar --set "$NAME" label="$WS $LABEL"
else
  sketchybar --set "$NAME" label="${WS:-?}"
fi
