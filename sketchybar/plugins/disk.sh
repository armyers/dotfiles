#!/bin/bash

WARN=0xfff9e2af

FREE=$(df -H / | awk 'NR==2{print $4}')
PCT_USED=$(df / | awk 'NR==2{gsub(/%/,""); print $5}')
PCT_FREE=$((100 - PCT_USED))

if [ "$PCT_FREE" -lt 5 ]; then
  sketchybar --set "$NAME" label="${FREE} free" label.color=$WARN icon.color=$WARN
else
  sketchybar --set "$NAME" label="${FREE} free" label.color=0xffcdd6f4 icon.color=0xffaac8ff
fi
