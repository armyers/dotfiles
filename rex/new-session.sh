#!/usr/bin/env bash
# Create a Rex session: prompt for a name, pick a starting directory with fzf
# over zoxide's list, pick a pane layout from layouts.json, then create it
# and switch the app to it. Run by the new_named_session action in init.lua,
# inside a floating pane.
#
# In the directory picker, Enter on an empty match uses what you typed:
# a path (~/x, /x) as-is, anything else as a zoxide query (like `z text`).

set -u

printf '\n  New Rex session\n\n'
read -r -p "  Name (empty = random): " name

query_and_pick=$(
  zoxide query --list \
    | sed "s|^$HOME|~|" \
    | fzf --print-query \
      --prompt 'dir> ' \
      --header 'Enter: pick   Esc: cancel   (no match: typed path or zoxide query)' \
      --layout reverse \
      --scheme path \
      --tiebreak index \
      --height 100% \
      --preview-window 'right,40%' \
      --preview 'p={}; p="${p/#\~/$HOME}"; eza -la --color=always --group-directories-first "$p" 2>/dev/null || ls -la "$p"'
)
status=$?
# 0 = picked, 1 = no match (query only), 130 = cancelled
if [ "$status" -eq 130 ] || [ "$status" -eq 2 ]; then
  exit 0
fi

query=$(printf '%s\n' "$query_and_pick" | sed -n 1p)
picked=$(printf '%s\n' "$query_and_pick" | sed -n 2p)

if [ -n "$picked" ]; then
  dir=$picked
elif [ -z "$query" ]; then
  dir=$HOME
else
  case "$query" in
    "~" | "~/"* | /*) dir=$query ;;
    *) dir=$(zoxide query -- "$query") || {
      printf '\n  zoxide has no match for "%s"\n' "$query"
      read -r -n 1 -s -p "  Press any key to close"
      exit 1
    } ;;
  esac
fi
dir="${dir/#\~/$HOME}"
tilde="~"

if [ ! -d "$dir" ]; then
  printf '\n  Not a directory: %s\n' "$dir"
  read -r -n 1 -s -p "  Press any key to close"
  exit 1
fi

# Pick a layout from layouts.json (first entry is the default). Each "pane"
# in a layout becomes a terminal starting in $dir.
LAYOUTS="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/layouts.json"
export LAYOUTS
layout_name=$(
  jq -r '.[].name' "$LAYOUTS" \
    | fzf --prompt 'layout> ' \
      --header 'Enter: pick   Esc: cancel' \
      --layout reverse \
      --no-sort \
      --height 100% \
      --preview-window 'right,60%' \
      --preview 'jq -r --arg n {} ".[] | select(.name == \$n) | .diagram[]" "$LAYOUTS"'
) || exit 0

request=$(
  jq -n --slurpfile L "$LAYOUTS" --arg layout "$layout_name" --arg label "$name" --arg dir "$dir" '
    ($L[0][] | select(.name == $layout) | .layout) as $tree
    | {
        initial_windows: [{
          layout: ($tree | walk(if . == "pane" then
            { block: { flavor: "com.superlogical.terminal.shell", options: { cwd: $dir } } }
          else . end))
        }]
      }
    + (if $label == "" then {} else { label: $label } end)'
)

out=$(rex api call session.create "$request" 2>&1)
rc=$?

if [ "$rc" -ne 0 ]; then
  printf '\n  Creating the session failed:\n%s\n' "$out"
  read -r -n 1 -s -p "  Press any key to close"
  exit 1
fi

sid=$(printf '%s' "$out" | jq -r '.session_id // empty' 2> /dev/null)

# Switch the Rex app to the new session. Needs Remote Control (Settings >
# General). The pane may not know its client, so fall back to the first
# connected Rex app.
client=${REX_CLIENT:-}
if [ -z "$client" ]; then
  client=$(rex client ls --json 2> /dev/null \
    | jq -r '[.clients[] | select(.info.kind == "app")][0].client_id // empty')
fi
if [ -n "$sid" ] && [ -n "$client" ] \
  && err=$(rex -C "$client" "do" session.select session_id="$sid" 2>&1); then
  exit 0
fi

printf '\n  Created session "%s" in %s\n' "$name" "${dir/#"$HOME"/$tilde}"
printf '  Could not switch to it automatically (%s).\n' "${err:-no Rex app found}"
printf '  Switch with cmd+shift+p.\n\n'
read -r -n 1 -s -p "  Press any key to close"
