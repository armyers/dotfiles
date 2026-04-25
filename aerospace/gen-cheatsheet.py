#!/usr/bin/env python3
"""Generate cheatsheet.txt from aerospace.toml."""

import re
import tomllib
from pathlib import Path

DIR = Path(__file__).parent
CONFIG = DIR / "aerospace.toml"
OUTPUT = DIR / "cheatsheet.txt"

# aerospace key names → display symbols
KEY_DISPLAY = {
    "leftSquareBracket": "[",
    "rightSquareBracket": "]",
    "semicolon": ";",
    "slash": "/",
    "comma": ",",
    "minus": "-",
    "equal": "=",
    "tab": "tab",
    "backspace": "del",
    "return_or_enter": "enter",
}


def display_key(combo: str) -> str:
    """Convert 'alt-ctrl-leftSquareBracket' → 'caps + ctrl + ['."""
    parts = combo.split("-")
    out = []
    for p in parts:
        if p == "alt":
            out.append("caps")
        elif p == "cmd":
            out.append("cmd")
        elif p == "ctrl":
            out.append("ctrl")
        elif p == "shift":
            out.append("shift")
        elif p in KEY_DISPLAY:
            out.append(KEY_DISPLAY[p])
        else:
            out.append(p)
    return " + ".join(out)


def action_str(val) -> str:
    """Normalize action to string (could be string or list)."""
    if isinstance(val, list):
        return ", ".join(v for v in val if v != "mode main")
    return val


def extract_workspace(action: str) -> str | None:
    """Pull workspace letter from action string."""
    m = re.search(r"focus-workspace\.sh\s+(\S+)", action)
    if m:
        return m.group(1)
    m = re.search(r"workspace\s+(\S+)", action)
    if m:
        return m.group(1)
    return None


def parse_workspace_labels(config_text: str) -> dict[str, str]:
    """Parse workspace labels from comments above [workspace-to-monitor-force-assignment].

    Expects lines like:
        #   A = AWS Chrome
        #   S = Slack
    """
    labels = {}
    in_section = False
    for line in config_text.splitlines():
        stripped = line.strip()
        if "workspace-to-monitor-force-assignment" in stripped:
            break
        if re.match(r"^#\s+\w+ = .+", stripped):
            in_section = True
            m = re.match(r"^#\s+(\w+)\s*=\s*(.+)", stripped)
            if m:
                labels[m.group(1)] = m.group(2).strip()
        elif in_section and not stripped.startswith("#"):
            in_section = False
    return labels


def main():
    config_text = CONFIG.read_text()
    cfg = tomllib.loads(config_text)

    main_bind = cfg.get("mode", {}).get("main", {}).get("binding", {})
    svc_bind = cfg.get("mode", {}).get("service", {}).get("binding", {})
    monitors = cfg.get("workspace-to-monitor-force-assignment", {})

    # Build workspace → label map from comments in config
    ws_labels = parse_workspace_labels(config_text)

    # Categorize main bindings
    focus = {}  # h/j/k/l focus
    move = {}  # h/j/k/l move
    join = {}  # h/j/k/l join
    ws_switch = {}  # workspace switching (letters/numbers)
    ws_move = {}  # move-node-to-workspace
    layout = []  # layout commands
    resize = []  # resize commands
    monitor = []  # monitor commands
    other = []  # everything else

    for combo, action in sorted(main_bind.items()):
        act = action_str(action)
        dk = display_key(combo)

        if re.search(r"^alt-[hjkl]$", combo) and "focus" in act:
            focus[combo[-1]] = act.split()[-1]
        elif re.search(r"^alt-shift-[hjkl]$", combo) and "move" in act:
            move[combo.split("-")[-1]] = act.split()[-1]
        elif re.search(r"^alt-cmd-[hjkl]$", combo) and "join" in act:
            join[combo.split("-")[-1]] = act.split()[-1]
        elif "focus-workspace" in act or (
            re.search(r"^alt-[a-z0-9]$", combo) and "workspace" in act
        ):
            ws = extract_workspace(act)
            if ws:
                ws_switch[ws] = dk
        elif "move-node-to-workspace" in act and re.search(r"^alt-shift-", combo):
            ws = extract_workspace(act)
            if ws:
                ws_move[ws] = dk
        elif "layout" in act or "fullscreen" in act:
            layout.append((dk, act))
        elif "resize" in act:
            resize.append((dk, act))
        elif "monitor" in act:
            monitor.append((dk, act))
        else:
            other.append((dk, act))

    # Build workspace grid: letter → (app_name, monitor)
    # Combine assigned workspaces from ws_switch with monitor/app info
    assigned = sorted(ws_switch.keys())
    main_ws = [w for w in assigned if monitors.get(w) == "main"]
    builtin_ws = [w for w in assigned if monitors.get(w) == "built-in"]
    number_ws = [w for w in assigned if w.isdigit()]
    unassigned_ws = [w for w in assigned if w not in monitors and not w.isdigit()]

    def ws_line(ws_key: str) -> str:
        name = ws_labels.get(ws_key, "")
        return f"{ws_key} {name}" if name else ws_key

    def format_ws_grid(keys: list[str], cols: int = 3) -> list[str]:
        items = [ws_line(k) for k in keys]
        col_width = max(len(x) for x in items) + 3
        lines = []
        for i in range(0, len(items), cols):
            row = items[i : i + cols]
            lines.append("   " + "".join(f"{x:<{col_width}}" for x in row).rstrip())
        return lines

    # Build output
    lines = []
    lines.append(" AeroSpace Keybindings          (caps = alt via Karabiner)")
    lines.append("")

    # Workspaces
    lines.append(" WORKSPACES")
    lines.append("   caps + <key>                  switch to workspace")
    lines.append("   caps + shift + <key>          move window to workspace")
    for combo, act in other:
        if "back-and-forth" in act:
            lines.append(f"   {combo:<33}back-and-forth")
            break
    lines.append("")
    if main_ws:
        lines.append("   main monitor:")
        lines.extend(format_ws_grid(main_ws))
    if builtin_ws:
        lines.append("")
        lines.append("   built-in monitor:")
        lines.extend(format_ws_grid(builtin_ws))
    if number_ws:
        lines.append("")
        lo, hi = number_ws[0], number_ws[-1]
        lines.append(f"   {lo}–{hi} spare")
    if unassigned_ws:
        lines.append("")
        lines.append("   unassigned: " + " ".join(unassigned_ws))
    lines.append("")

    # Focus / Move / Join
    lines.append(" FOCUS / MOVE / JOIN")
    if focus:
        dirs = " ".join(focus.keys())
        vals = "/".join(focus.values())
        lines.append(f"   caps + {dirs:<24}focus {vals}")
    if move:
        dirs = " ".join(move.keys())
        vals = "/".join(move.values())
        lines.append(f"   caps + shift + {dirs:<16}move  {vals}")
    if join:
        dirs = " ".join(join.keys())
        vals = "/".join(join.values())
        lines.append(f"   caps + cmd + {dirs:<18}join  {vals}")
    lines.append("")

    # Layout
    lines.append(" LAYOUT")
    for dk, act in layout:
        lines.append(f"   {dk:<33}{act}")
    for dk, act in resize:
        lines.append(f"   {dk:<33}{act}")
    lines.append("")

    # Monitors
    lines.append(" MONITORS")
    for dk, act in monitor:
        # Shorten action for display
        short = act.replace("--wrap-around ", "")
        lines.append(f"   {dk:<33}{short}")
    lines.append("")

    # Other (non-workspace, non-cheatsheet, non-service-mode)
    misc = [
        (dk, act)
        for dk, act in other
        if "back-and-forth" not in act
        and "gen-cheatsheet" not in act
        and act != "mode service"
    ]
    if misc:
        lines.append(" OTHER")
        for dk, act in misc:
            # Clean up exec-and-forget prefix for display
            short = re.sub(r"^exec-and-forget\s+", "", act)
            lines.append(f"   {dk:<33}{short}")
        lines.append("")

    # Service mode
    lines.append(" SERVICE MODE                    caps + ctrl + ;")
    for combo, action in sorted(svc_bind.items()):
        act = action_str(action)
        dk = display_key(combo)
        if act in ("mode main",):
            continue
        lines.append(f"   {dk:<33}{act}")
    lines.append("")

    lines.append(" DISMISS                         esc  or  q")

    OUTPUT.write_text("\n".join(lines) + "\n")
    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    main()
