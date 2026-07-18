#!/usr/bin/env python3
"""Generate cheatsheet.txt from skhdrc.

Parses each `<mods> - <key> : <command>` binding. The action text is the key
name for `skhd -k "…"` synthetic bindings, otherwise the first comment line
above the binding (with any parenthetical HRM hints stripped). `# ─── … ───`
divider comments start a new section.
"""

import re
from pathlib import Path

DIR = Path(__file__).parent
CONFIG = DIR / "skhdrc"
OUTPUT = DIR / "cheatsheet.txt"

DIVIDER = re.compile(r"^#\s*─+\s*(.+?)\s*─+\s*$")
BINDING = re.compile(r"^([a-z0-9].*?)\s*:\s*(.+)$")
SYNTH_KEY = re.compile(r'skhd -k "(.+?)"')


def format_combo(lhs: str) -> str:
    """'cmd + ctrl + alt + shift - r' → 'cmd + ctrl + alt + shift + r'."""
    lhs = lhs.strip()
    if " - " in lhs:
        mods, key = lhs.rsplit(" - ", 1)
        parts = [m.strip() for m in mods.split("+")] + [key.strip()]
    else:
        parts = [lhs]
    return " + ".join(p for p in parts if p)


def action_for(cmd: str, comment: str | None) -> str:
    m = SYNTH_KEY.search(cmd)
    if m:
        return f"→ {m.group(1)}"
    if comment:
        c = comment.split(". ")[0]  # first sentence only
        c = re.sub(r"\(.*?\)", "", c)  # drop parenthetical HRM hints
        c = re.sub(r"\s{2,}", " ", c).strip().rstrip(" .")
        if c:
            return c
    return cmd[:40]


def main():
    section = "GENERAL"
    pending: str | None = None
    entries: list[tuple[str, str, str]] = []

    for line in CONFIG.read_text().splitlines():
        stripped = line.strip()
        if not stripped:
            pending = None
            continue
        m = DIVIDER.match(stripped)
        if m:
            section = m.group(1).upper()
            pending = None
            continue
        if stripped.startswith("#"):
            c = stripped.lstrip("#").strip()
            if pending is None and c:
                pending = c
            continue
        m = BINDING.match(stripped)
        if m:
            combo = format_combo(m.group(1))
            action = action_for(m.group(2), pending)
            entries.append((section, combo, action))

    # Group by section, preserving first-seen order.
    order: list[str] = []
    groups: dict[str, list[tuple[str, str]]] = {}
    for sec, combo, action in entries:
        if sec not in groups:
            groups[sec] = []
            order.append(sec)
        groups[sec].append((combo, action))

    lines = [" skhd Keybindings", ""]
    for sec in order:
        lines.append(" " + sec)
        for combo, action in groups[sec]:
            lines.append(f"   {combo:<33}{action}")
        lines.append("")

    OUTPUT.write_text("\n".join(lines).rstrip() + "\n")
    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    main()
