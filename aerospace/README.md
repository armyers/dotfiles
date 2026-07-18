# AeroSpace Configuration

Tiling window manager config with Karabiner integration (`caps_lock` → `alt` for all keybindings).

## Files

| File                 | Purpose                                                         |
| -------------------- | --------------------------------------------------------------- |
| `aerospace.toml`     | AeroSpace config (keybindings, workspaces, monitor assignments) |
| `cheatsheet.txt`     | Cheatsheet content (auto-generated from `aerospace.toml`)       |
| `gen-cheatsheet.py`  | Generates `cheatsheet.txt` and `workspace-labels.sh`            |
| `focus-workspace.sh` | Workspace switcher that force-focuses the correct window        |

## Cheatsheet

The AeroSpace keybindings are shown alongside the Kanata, skhd, and Hammerspoon
keybindings in the combined popup that lives in [`../cheatsheet/`](../cheatsheet/)
— a single multi-column, fuzzy-searchable window triggered by `ctrl + alt + k`.

### How it works

1. The `alt-ctrl-k` keybinding runs each source's `gen-cheatsheet.py` (this dir
   plus kanata, skhd, hammerspoon), then launches `~/.config/cheatsheet/cheatsheet`
2. `gen-cheatsheet.py` parses `aerospace.toml` (keybindings, workspace
   assignments, and comment labels) and writes `cheatsheet.txt`
3. The combined popup reads every source's `cheatsheet.txt` and displays them

### Updating content

Edit `aerospace.toml` — workspace labels come from the comments above `[workspace-to-monitor-force-assignment]`:

```toml
#   S = Slack
#   T = Terminal (Ghostty)
#   W = Work browser
```

Changes appear automatically the next time you press `ctrl + alt + k`. See
[`../cheatsheet/README.md`](../cheatsheet/README.md) for the popup itself
(appearance, rebuilding the binary).

## Keybinding Summary

> [!important]
> `caps` = `alt` via Karabiner. All keybindings use physical `caps_lock` as the modifier.

| Combo                        | Action                           |
| ---------------------------- | -------------------------------- |
| caps + letter/number         | switch to workspace              |
| caps + shift + letter/number | move window to workspace         |
| caps + h/j/k/l               | focus left/down/up/right         |
| caps + shift + h/j/k/l       | move window left/down/up/right   |
| caps + cmd + h/j/k/l         | join with left/down/up/right     |
| caps + cmd + f               | fullscreen                       |
| caps + - / =                 | resize -50 / +50                 |
| caps + /                     | toggle tiles layout              |
| caps + ,                     | toggle accordion layout          |
| caps + tab                   | workspace back-and-forth         |
| caps + ctrl + tab            | move workspace to next monitor   |
| ctrl + cmd + [ / ]           | focus prev/next monitor          |
| ctrl + cmd + shift + [ / ]   | move window to prev/next monitor |
| caps + cmd + s               | screenshot (interactive)         |
| ctrl + alt + k               | cheatsheet popup (combined)      |
| caps + ctrl + ;              | service mode                     |

## macOS Permissions

> [!important]
> AeroSpace needs explicit macOS permissions to run certain tools via `exec-and-forget`. These fail silently — no error, no popup, nothing happens.

**Screen Recording** — required for `screencapture`. Add AeroSpace in:
System Settings > Privacy & Security > Screen Recording

Restart AeroSpace after granting the permission.
