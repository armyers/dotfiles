# skhd Configuration

[skhd](https://github.com/koekeishiya/skhd) hotkey daemon config. Most bindings
are `ctrl + shift + …` chords produced by the Kanata home-row mods (or physical
`fn`), used to fill gaps that AeroSpace and Kanata don't cover.

`~/.config/skhd` is a symlink to this directory (see `../dotfile-links.txt`).

## Files

| File                | Purpose                                                |
| ------------------- | ------------------------------------------------------ |
| `skhdrc`            | skhd hotkey definitions                                |
| `gen-cheatsheet.py` | Generates `cheatsheet.txt` by parsing `skhdrc`         |
| `cheatsheet.txt`    | Cheatsheet content (auto-generated; read by the popup) |

## Bindings

| Combo                        | Action                        |
| ---------------------------- | ----------------------------- |
| cmd + ctrl + alt + shift + r | restart both Kanata daemons   |
| ctrl + alt + t               | Tomahawk56 cheatsheet popup   |
| ctrl + shift + h/j/k/l       | arrow keys ← ↓ ↑ →            |
| ctrl + shift + g             | Gemini in a new Chrome window |
| ctrl + shift + s             | toggle AeroSpace              |
| ctrl + shift + d             | cycle audio output devices    |

The `ctrl + shift + …` chords are meant to be triggered through the Kanata
home-row mods (`s` = ctrl, `a` = shift) or physical `fn`, not by reaching for
the physical modifier keys.

## Cheatsheet

`gen-cheatsheet.py` parses `skhdrc` and writes `cheatsheet.txt`, which is shown
in the combined popup in [`../cheatsheet/`](../cheatsheet/) alongside AeroSpace,
Kanata, and Hammerspoon (triggered by `ctrl + alt + k`). The `alt-ctrl-k`
binding in `../aerospace/aerospace.toml` regenerates every source before opening
the popup, so edits to `skhdrc` appear automatically.

Action text comes from the `skhd -k "…"` key for synthetic bindings, otherwise
from the first comment line above the binding (parenthetical HRM hints stripped).
A `# ─── … ───` divider comment starts a new section.
