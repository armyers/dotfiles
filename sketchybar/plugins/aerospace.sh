#!/bin/bash

# Show the AeroSpace workspace for a given monitor.
# Usage: aerospace.sh <monitor_number>
# Highlights the focused monitor's workspace brighter.

source "$HOME/.config/aerospace/workspace-labels.sh"

MONITOR="${1:-1}"
ACCENT=0xffaac8ff
DIM=0x80aac8ff
WS_ACTIVE_BG=0xff45475a
WS_BG=0xff313244

WS=$(aerospace list-workspaces --monitor "$MONITOR" --visible 2> /dev/null)
FOCUSED_MON=$(aerospace list-monitors --focused 2> /dev/null | awk '{print $1}')
LABEL="$(ws_label "$WS")"

if [ -n "$LABEL" ]; then
  DISPLAY="$WS $LABEL"
else
  DISPLAY="${WS:-?}"
fi

if [ "$MONITOR" = "$FOCUSED_MON" ]; then
  sketchybar --set "$NAME" label="$DISPLAY" label.color=$ACCENT background.color=$WS_ACTIVE_BG
else
  sketchybar --set "$NAME" label="$DISPLAY" label.color=$DIM background.color=$WS_BG
fi
