#!/bin/bash
# Verify that the kanata binary the LaunchDaemons actually invoke still holds
# its two macOS TCC permissions.
#
# Why this exists: Homebrew's kanata is ad-hoc signed, so every `brew upgrade`
# produces a binary with a NEW cdhash. TCC pins each grant to the cdhash (see
# the csreq blob), so an upgrade silently revokes both permissions and kanata
# crash-loops under KeepAlive with "failed to open keyboard device(s)".
# No symlink or stable-path trick avoids this — TCC resolves symlinks to the
# real Cellar path and pins the hash regardless.
#
# Two permissions are needed, and missing either produces the same symptom:
#   kTCCServiceListenEvent    — Input Monitoring (read the physical keyboard)
#   kTCCServiceAccessibility  — Accessibility   (new requirement in 1.12.0,
#                               kanata issue #1211; 1.11.0 did not need it)
#
# Exit 0 = both granted, 1 = something is wrong, 2 = couldn't determine.

PLIST="/Library/LaunchDaemons/com.user.kanata-builtin.plist"
TCC_DB="/Library/Application Support/com.apple.TCC/TCC.db"
LOGS="/opt/homebrew/var/log/kanata-builtin.log /opt/homebrew/var/log/kanata-logitech.log"

# Resolve symlinks without depending on `realpath`/`readlink -f`, which are not
# portable across macOS versions. /opt/homebrew/opt/kanata is a symlinked DIR
# (-> ../Cellar/kanata/<version>), so the `pwd -P` step is what matters here.
resolve() {
  local p="$1" d b
  local i=0
  while [ -L "$p" ] && [ $i -lt 32 ]; do
    local t; t="$(readlink "$p")"
    case "$t" in
      /*) p="$t" ;;
      *)  p="$(dirname "$p")/$t" ;;
    esac
    i=$((i + 1))
  done
  d="$(dirname "$p")"; b="$(basename "$p")"
  printf '%s/%s\n' "$(cd "$d" && pwd -P)" "$b"
}

# The daemon's binary is whatever ProgramArguments[0] says — read it from the
# plist rather than hardcoding, so this keeps working if the path ever changes.
BIN_RAW="$(/usr/libexec/PlistBuddy -c 'Print :ProgramArguments:0' "$PLIST" 2>/dev/null)"
if [ -z "$BIN_RAW" ]; then
  echo "✗ could not read ProgramArguments[0] from $PLIST"
  exit 2
fi

BIN="$(resolve "$BIN_RAW")"
if [ ! -x "$BIN" ]; then
  echo "✗ daemon binary does not exist: $BIN"
  echo "  (plist says: $BIN_RAW)"
  exit 1
fi

CDHASH="$(codesign -d --verbose=4 "$BIN" 2>&1 | awk -F= '/^CDHash=/ { print toupper($2) }')"
if [ -z "$CDHASH" ]; then
  echo "✗ could not read cdhash from $BIN"
  exit 2
fi

echo "binary: $BIN"
[ "$BIN" != "$BIN_RAW" ] && echo "        (via $BIN_RAW)"
echo "cdhash: $CDHASH"
echo

# Reading the system TCC.db needs Full Disk Access for THIS process. Terminal
# usually has it; Hammerspoon usually does not — hence the log-based fallback.
if ! sqlite3 "$TCC_DB" 'select 1 from access limit 1;' > /dev/null 2>&1; then
  echo "⚠ can't read the TCC database (this process lacks Full Disk Access)."
  echo "  Falling back to daemon state + log inspection:"
  echo
  status=0
  if pgrep -f "kanata --no-wait" > /dev/null; then
    echo "  ✓ a kanata daemon is running"
  else
    echo "  ✗ no kanata daemon is running"
    status=1
  fi
  # A permission error in the last 50 lines means it is failing RIGHT NOW;
  # older hits are just history from a previous break that has since been fixed.
  if tail -n 50 $LOGS 2>/dev/null | grep -q "needs macOS .* permission"; then
    echo "  ✗ recent log shows a permission failure — re-grant both permissions"
    status=1
  else
    echo "  ✓ no recent permission errors in the logs"
  fi
  exit $status
fi

status=0
check() {
  local service="$1" label="$2" pane="$3"
  local row; row="$(sqlite3 "$TCC_DB" \
    "select auth_value || '|' || hex(csreq) from access
     where service='$service' and client='$BIN';" 2>/dev/null)"

  if [ -z "$row" ]; then
    # Distinguish "never granted" from "granted to a different/older binary" —
    # the stale-entry case is the one that needs a REMOVE before the re-add.
    local stale; stale="$(sqlite3 "$TCC_DB" \
      "select client from access where service='$service' and client like '%kanata%';" 2>/dev/null)"
    if [ -n "$stale" ]; then
      echo "✗ $label: no entry for the current binary; stale entry exists for:"
      echo "$stale" | sed 's/^/    /'
      echo "    → remove the stale one, then re-add the current binary"
    else
      echo "✗ $label: not granted (no entry at all)"
    fi
    echo "    open '$pane'"
    status=1
    return
  fi

  local auth="${row%%|*}" csreq="${row##*|}"
  if [ "$auth" != "2" ]; then
    echo "✗ $label: entry exists but is denied/unset (auth_value=$auth) — toggle it on"
    status=1
  elif [ "${csreq: -40}" != "$CDHASH" ]; then
    # Same path, different hash: the binary was upgraded or replaced in place.
    echo "✗ $label: granted, but pinned to a DIFFERENT binary hash"
    echo "    pinned: ${csreq: -40}"
    echo "    actual: $CDHASH"
    echo "    → remove the entry and re-add the current binary"
    status=1
  else
    echo "✓ $label: granted, cdhash matches"
  fi
}

check kTCCServiceListenEvent   "Input Monitoring" \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
check kTCCServiceAccessibility "Accessibility   " \
  "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"

echo
if [ $status -eq 0 ]; then
  echo "Both permissions OK."
else
  echo "Fix: open the pane above, remove any existing kanata entry, click +,"
  echo "     then ⌘⇧G and paste:"
  echo "     $BIN"
  echo "Then: sudo launchctl bootout system/com.user.kanata-builtin"
  echo "      sudo launchctl bootstrap system $PLIST"
fi
exit $status
