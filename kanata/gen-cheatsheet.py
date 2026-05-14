#!/usr/bin/env python3
"""Generate cheatsheet.txt from kanata.kbd.

Parses the builtin-keyboard config. Both kbd files are kept in sync, so
parsing one is sufficient.
"""

import re
from pathlib import Path

DIR = Path(__file__).parent
CONFIG = DIR / "kanata.kbd"
OUTPUT = DIR / "cheatsheet.txt"

# Side-prefixed kanata mod → display name
MOD = {
    "lctl": "ctrl",
    "rctl": "ctrl",
    "lsft": "shift",
    "rsft": "shift",
    "lmet": "cmd",
    "rmet": "cmd",
    "lalt": "alt",
    "ralt": "alt",
}

# Chord-prefix letters used in (macro X-Y-z) expressions
CHORD_PREFIX = {"M": "cmd", "C": "ctrl", "S": "shift", "A": "alt"}

# Special keynames inside macros
KEY_DISPLAY = {"spc": "space", "ret": "enter", "bspc": "bspc", "tab": "tab"}


def strip_line_comments(text: str) -> str:
    """Drop ;;… line comments (kbd uses no string literals)."""
    out = []
    for line in text.splitlines():
        idx = line.find(";;")
        out.append(line if idx < 0 else line[:idx])
    return "\n".join(out)


def pretty(keyname: str) -> str:
    """Normalize a kanata key/mod name for display (lctl → ctrl, caps → caps lock)."""
    if keyname in MOD:
        return MOD[keyname]
    return {"caps": "caps lock", "esc": "esc"}.get(keyname, keyname)


def parse_macro(expr: str) -> str:
    """'M-c' → 'cmd+c'; 'C-S-v' → 'ctrl+shift+v'; 'C-spc' → 'ctrl+space'."""
    parts = expr.strip().split("-")
    mods = [CHORD_PREFIX[p] for p in parts[:-1] if p in CHORD_PREFIX]
    key = KEY_DISPLAY.get(parts[-1], parts[-1])
    return "+".join(mods + [key])


def find_hrms(text: str) -> list[tuple[str, str]]:
    """Aliases of the form `<key> (tap-hold-release-keys … <key> <mod> …)`."""
    out = []
    pattern = re.compile(
        r"^\s*(\w+)\s+\(tap-hold-release-keys\s+\$\S+\s+\$\S+\s+(\S+)\s+(lctl|lsft|lmet|lalt|rctl|rsft|rmet|ralt)\b",
        re.MULTILINE,
    )
    for m in pattern.finditer(text):
        alias, tap_key, hold_mod = m.group(1), m.group(2), m.group(3)
        # Use the alias name (e.g. `scln`) only if it differs from the tap key
        display_key = tap_key if tap_key != alias else alias
        out.append((display_key, MOD[hold_mod]))
    return out


def find_letter_shortcuts(text: str) -> list[tuple[str, str]]:
    """`<letter> (tap-dance-eager … (macro X-Y) …)` — hold action of tap-dance."""
    out = []
    for m in re.finditer(
        r"^\s*(\w+)\s+\(tap-dance-eager\s+\$\S+.*?\(macro\s+([^\)]+)\)",
        text,
        re.DOTALL | re.MULTILINE,
    ):
        out.append((m.group(1), parse_macro(m.group(2))))
    return out


def find_chords(text: str) -> list[tuple[list[str], list[str]]]:
    """Inside defchordsv2: `(k1 k2) (multi m1 m2) …`."""
    block_match = re.search(r"\(defchordsv2\b(.+?)^\)", text, re.DOTALL | re.MULTILINE)
    if not block_match:
        return []
    block = block_match.group(1)

    out = []
    line_pattern = re.compile(
        r"^\s*\(([\w\s;/]+)\)\s+\(multi\s+([^\)]+)\)\s+\d+",
        re.MULTILINE,
    )
    for m in line_pattern.finditer(block):
        keys = m.group(1).split()
        mods = [MOD[t] for t in m.group(2).split() if t in MOD]
        if mods:
            out.append((keys, mods))
    return out


def find_remaps(text: str) -> list[tuple[str, str]]:
    """defsrc keys whose deflayer entry is a literal (non-alias) different key.

    Also resolves single-keycode aliases like `cap esc` so users see the swap.
    """
    src_match = re.search(r"\(defsrc\s+([^)]+)\)", text)
    layer_match = re.search(r"\(deflayer\s+base\s+([^)]+)\)", text)
    if not src_match or not layer_match:
        return []
    src_keys = src_match.group(1).split()
    layer_actions = layer_match.group(1).split()

    # Build a map of simple `name keycode` aliases (skip multi-token expressions).
    simple_aliases: dict[str, str] = {}
    alias_block = re.search(r"\(defalias\b(.+?)^\)", text, re.DOTALL | re.MULTILINE)
    if alias_block:
        for m in re.finditer(
            r"^\s*(\w+)\s+(\w+)\s*$", alias_block.group(1), re.MULTILINE
        ):
            simple_aliases[m.group(1)] = m.group(2)

    out = []
    for src, action in zip(src_keys, layer_actions):
        if action.startswith("@"):
            alias = action[1:]
            if alias in simple_aliases:
                target = simple_aliases[alias]
                if target != src:
                    out.append((src, target))
            continue
        if action != src:
            out.append((src, action))
    return out


def render(remaps, hrms, shortcuts, chords) -> str:
    lines: list[str] = []
    lines.append(" Kanata Keybindings")
    lines.append("")

    if remaps:
        lines.append(" KEY REMAPS")
        for src, dst in remaps:
            lines.append(f"   {pretty(src):<33}{pretty(dst)}")
        lines.append("")

    if hrms:
        lines.append(" HOME ROW MODS  (tap = letter, hold = modifier)")
        for key, mod in hrms:
            lines.append(f"   {key:<33}{mod}")
        lines.append("")

    if shortcuts:
        lines.append(
            " LETTER TAP-HOLD  (tap = letter, hold = shortcut, tap-tap-hold = repeat)"
        )
        for key, action in shortcuts:
            lines.append(f"   {key:<33}{action}")
        lines.append("")

    if chords:
        lines.append(
            " CHORDS  (press both within 50ms → combo held while either is held)"
        )
        for keys, mods in chords:
            chord_str = " + ".join(keys)
            mod_str = "+".join(mods)
            lines.append(f"   {chord_str:<33}{mod_str}")
        lines.append("")

    lines.append(" DISMISS                          esc  or  q")
    return "\n".join(lines) + "\n"


def main():
    text = strip_line_comments(CONFIG.read_text())
    remaps = find_remaps(text)
    hrms = find_hrms(text)
    shortcuts = find_letter_shortcuts(text)
    chords = find_chords(text)
    OUTPUT.write_text(render(remaps, hrms, shortcuts, chords))
    print(f"wrote {OUTPUT}")


if __name__ == "__main__":
    main()
