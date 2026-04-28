#!/bin/bash

CPU=$(ps -A -o %cpu | awk '{s+=$1} END {printf "%.0f", s}')
RAM=$(memory_pressure 2> /dev/null | awk '/percentage used/{print $NF}')

sketchybar --set "$NAME" label="${CPU}% ${RAM}"
