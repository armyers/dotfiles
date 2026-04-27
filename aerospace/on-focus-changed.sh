#!/bin/bash
# If the focused workspace is empty, switch to the previous workspace.
# Called by aerospace on-focus-changed callback.

WS=$(aerospace list-workspaces --focused 2> /dev/null)
COUNT=$(aerospace list-windows --workspace "$WS" --count 2> /dev/null)

if [ "$COUNT" = "0" ]; then
  aerospace workspace-back-and-forth
fi
