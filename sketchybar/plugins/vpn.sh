#!/bin/bash

if pgrep -x "acvc-openvpn" > /dev/null 2>&1; then
  sketchybar --set "$NAME" icon=󰦝 label="ON" label.color=0xffa6e3a1
else
  sketchybar --set "$NAME" icon=󰦞 label="OFF" label.color=0xfff9e2af
fi
