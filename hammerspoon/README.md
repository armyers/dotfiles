# Hammerspoon Configuration

[Hammerspoon](https://www.hammerspoon.org/) config. It exists for one job:
keyboard-driven mouse-wheel scrolling. Kanata can't emit scroll events on macOS
(`mwheel` is a no-op there), so Hammerspoon drives the wheel instead.

`~/.config/hammerspoon` is a symlink to this directory, and `~/.hammerspoon`
symlinks to `~/.config/hammerspoon` (see `../dotfile-links.txt`).

## Files

| File                | Purpose                                                |
| ------------------- | ------------------------------------------------------ |
| `init.lua`          | Hammerspoon config (scroll bindings)                   |
| `.luarc.json`       | lua-language-server settings for editing `init.lua`    |
| `gen-cheatsheet.py` | Generates `cheatsheet.txt` by parsing `init.lua`       |
| `cheatsheet.txt`    | Cheatsheet content (auto-generated; read by the popup) |

## Bindings

| Combo           | Action       |
| --------------- | ------------ |
| cmd + shift + h | scroll left  |
| cmd + shift + j | scroll down  |
| cmd + shift + k | scroll up    |
| cmd + shift + l | scroll right |

Hold to scroll continuously (timer-driven, smooth); release to stop. The
`cmd + shift` chord is produced by the Kanata home-row mods (left-hand `s + d`
or right-hand `k + l`). Tuning knobs (`TICK_INTERVAL`, `SCROLL_STEP`,
`SCROLL_UNIT`) live at the top of `init.lua`.

## Cheatsheet

`gen-cheatsheet.py` parses `init.lua` (the `SCROLL_MODS` chord and the `DIRS`
table, using each key's trailing `-- <direction>` comment) and writes
`cheatsheet.txt`, which is shown in the combined popup in
[`../cheatsheet/`](../cheatsheet/) alongside AeroSpace, Kanata, and skhd
(triggered by `ctrl + alt + k`). If you add other Hammerspoon bindings, extend
the parsing in `gen-cheatsheet.py`.

## Applying changes

Hammerspoon watches its config; reload from the menu-bar icon (or `hs.reload()`)
after editing `init.lua`. The cheatsheet regenerates on every `ctrl + alt + k`.
