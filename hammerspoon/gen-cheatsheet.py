#!/usr/bin/env python3
"""Generate cheatsheet.txt from init.lua.

The config binds one modifier chord (SCROLL_MODS) to a set of direction keys
defined in the DIRS table, each with a trailing `-- <direction>` comment. If
you add other Hammerspoon bindings, extend the parsing here.
"""

import re
from pathlib import Path

DIR = Path(__file__).parent
CONFIG = DIR / "init.lua"
OUTPUT = DIR / "cheatsheet.txt"

# Nicer left-to-right ordering for the scroll keys.
KEY_ORDER = {"h": 0, "j": 1, "k": 2, "l": 3}


def main():
    text = CONFIG.read_text()

    mods_m = re.search(r"SCROLL_MODS\s*=\s*\{([^}]*)\}", text)
    mods = re.findall(r'"(\w+)"', mods_m.group(1)) if mods_m else []

    # key = { ... }, -- direction  (inner braces only, so the outer DIRS = { … }
    # table declaration itself is not matched).
    dirs = re.findall(r"(\w+)\s*=\s*\{[^{}]*\}\s*,\s*--\s*(\w+)", text)
    dirs.sort(key=lambda kd: KEY_ORDER.get(kd[0], 99))

    lines = [" Hammerspoon Keybindings", ""]
    if dirs:
        lines.append(" SCROLL  (hold to repeat)")
        for key, direction in dirs:
            combo = " + ".join(mods + [key])
            lines.append(f"   {combo:<33}scroll {direction}")
        lines.append("")

    OUTPUT.write_text("\n".join(lines).rstrip() + "\n")
    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    main()
