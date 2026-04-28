#!/bin/bash

WARN=0xfff9e2af
TEXT=0xffcdd6f4
ACCENT=0xffaac8ff

PERCENTAGE="$(pmset -g batt | grep -Eo "\d+%" | cut -d% -f1)"
CHARGING="$(pmset -g batt | grep 'AC Power')"

if [ "$PERCENTAGE" = "" ]; then
  exit 0
fi

case "${PERCENTAGE}" in
  9[0-9] | 100) ICON="" ;;
  [6-8][0-9]) ICON="" ;;
  [3-5][0-9]) ICON="" ;;
  [1-2][0-9]) ICON="" ;;
  *) ICON="" ;;
esac

if [ -n "$CHARGING" ]; then
  ICON=""
fi

CRIT=0xfff38ba8

if [ -z "$CHARGING" ] && [ "$PERCENTAGE" -lt 5 ]; then
  sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" label.color=$CRIT icon.color=$CRIT
elif [ -z "$CHARGING" ] && [ "$PERCENTAGE" -lt 15 ]; then
  sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" label.color=$WARN icon.color=$WARN
else
  sketchybar --set "$NAME" icon="$ICON" label="${PERCENTAGE}%" label.color=$TEXT icon.color=$ACCENT
fi
