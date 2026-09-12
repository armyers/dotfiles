#!/bin/bash
# Bound the kanata logs. Run hourly by com.user.kanata-logtrim.
#
# WHY NOT newsyslog
# ------------------------------------------------------------------
# The usual macOS answer is /etc/newsyslog.d, but it rotates by RENAMING the
# file and creating a fresh one. These logs are launchd StandardOutPath targets:
# launchd holds an open fd on the original inode and keeps writing to it after
# the rename, so the "new" log stays empty forever while the rotated file grows
# without bound — and once it ages out and is unlinked, the space is still held
# by the running process. newsyslog has no copytruncate equivalent.
#
# Truncating IN PLACE works instead, because launchd opens these with O_APPEND:
# every write is positioned at the current end of file, so after a truncation
# the daemon's next write lands at offset 0 with no restart and no lost bytes.
# `cat tmp > "$f"` is what preserves the inode (O_TRUNC on the existing file)
# rather than replacing it — a `mv` here would reintroduce the newsyslog bug.
#
# WHAT FILLS THESE LOGS
# ------------------------------------------------------------------
# kanata-builtin.log grows ~2.7 MB/day even when everything is healthy: the
# Karabiner VirtualHIDDevice client library prints a bare "virtual_hid_keyboard_
# ready true" line on a timer, straight to stdout. It carries no kanata log
# prefix because it never passes through kanata's logger, so `--quiet` does not
# suppress it and there is no kanata flag that does. Bounding it is the fix.
#
# (kanata-logitech.log's much larger growth was a crash loop, fixed at the root
# in watch-logitech.sh — this only bounds what remains.)

LOG_GLOB="/opt/homebrew/var/log/kanata*.log"
MAX_BYTES=$((5 * 1024 * 1024)) # trim once a log exceeds ~5 MB
KEEP_LINES=2000                # recent history kept after a trim

for f in $LOG_GLOB; do
  [ -f "$f" ] || continue

  size=$(stat -f%z "$f" 2> /dev/null) || continue
  [ "$size" -gt "$MAX_BYTES" ] || continue

  tmp=$(mktemp -t kanata-logtrim) || continue
  if tail -n "$KEEP_LINES" "$f" > "$tmp" && cat "$tmp" > "$f"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') trimmed $(basename "$f"): $size bytes -> $(stat -f%z "$f") bytes"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') FAILED to trim $(basename "$f")" >&2
  fi
  rm -f "$tmp"
done
