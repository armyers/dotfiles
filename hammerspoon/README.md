# Hammerspoon Configuration

[Hammerspoon](https://www.hammerspoon.org/) config. Two jobs:

1. **Keyboard-driven mouse-wheel scrolling.** Kanata can't emit scroll events on
   macOS (`mwheel` is a no-op there), so Hammerspoon drives the wheel instead.
2. **Mouse-only kanata reset** — a menu-bar item to recover a jammed kanata
   daemon when the keyboard is dead (see below).

`~/.config/hammerspoon` is a symlink to this directory, and `~/.hammerspoon`
symlinks to `~/.config/hammerspoon` (see `../dotfile-links.txt`).

## Files

| File                | Purpose                                                |
| ------------------- | ------------------------------------------------------ |
| `init.lua`          | Hammerspoon config (scroll bindings + kanata reset)    |
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

## Kanata reset (menu-bar ⌨️ kanata)

When a kanata daemon jams, the keyboard stops working — so the keyboard/`sudo`
reset paths are unreachable. The **⌨️ kanata** menu-bar item's **"Reset kanata daemons"**
is the mouse-only recovery: clicking it creates `~/.local/state/kanata/reset.request`,
which a root `LaunchDaemon` (`com.user.kanata-reset`) watches and reacts to by
clean-restarting all three kanata daemons (`bootout`+`bootstrap`, no `SIGKILL`) —
no password, no keyboard.

It lives here in Hammerspoon (an always-running GUI process, independent of
kanata) rather than in kanata itself, so it works even when both keyboards are
dead. Setup and mechanics: [`../kanata/CLAUDE.md`](../kanata/CLAUDE.md)
("Mouse-only reset").

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
