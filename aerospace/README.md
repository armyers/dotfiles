# AeroSpace Configuration

Tiling window manager config with Karabiner integration (`caps_lock` → `alt` for all keybindings).

## Files

| File                 | Purpose                                                         |
| -------------------- | --------------------------------------------------------------- |
| `aerospace.toml`     | AeroSpace config (keybindings, workspaces, monitor assignments) |
| `cheatsheet.swift`   | Native macOS popup cheatsheet (translucent, dismiss with esc/q) |
| `cheatsheet`         | Compiled binary (built from `cheatsheet.swift`)                 |
| `cheatsheet.txt`     | Cheatsheet content (auto-generated from `aerospace.toml`)       |
| `gen-cheatsheet.py`  | Generates `cheatsheet.txt` by parsing `aerospace.toml`          |
| `focus-workspace.sh` | Workspace switcher that force-focuses the correct window        |
| `Makefile`           | Builds the cheatsheet binary                                    |

## Cheatsheet

The popup cheatsheet is triggered by `caps + shift + ?` and auto-generates its content from the config on every invocation.

### How it works

1. AeroSpace keybinding calls `gen-cheatsheet.py` then launches the `cheatsheet` binary
2. `gen-cheatsheet.py` parses `aerospace.toml` (keybindings, workspace assignments, and comment labels) and writes `cheatsheet.txt`
3. The binary reads `cheatsheet.txt` and displays a transparent floating popup

### Updating content

Edit `aerospace.toml` — workspace labels come from the comments above `[workspace-to-monitor-force-assignment]`:

```toml
#   S = Slack
#   T = Terminal (Ghostty)
#   W = Work browser
```

Changes appear automatically the next time you press `caps + shift + ?`.

### Rebuilding the binary

Only needed if you edit `cheatsheet.swift` (appearance, colors, window size):

```sh
cd ~/.config/aerospace
make
```

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
| caps + shift + ?             | cheatsheet popup                 |
| caps + ctrl + ;              | service mode                     |

## macOS Permissions

> [!important]
> AeroSpace needs explicit macOS permissions to run certain tools via `exec-and-forget`. These fail silently — no error, no popup, nothing happens.

**Screen Recording** — required for `screencapture`. Add AeroSpace in:
System Settings > Privacy & Security > Screen Recording

Restart AeroSpace after granting the permission.
