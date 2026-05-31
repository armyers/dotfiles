#!/bin/bash
# Kickstart both kanata launchd daemons. Run as root — via osascript
# (`do shell script ... with administrator privileges`) or `sudo`.

launchctl kickstart -k system/com.user.kanata-builtin || echo "builtin: kickstart failed"
launchctl kickstart -k system/com.user.kanata-logitech || echo "logitech: kickstart failed"
echo "kanata daemons restarted."
