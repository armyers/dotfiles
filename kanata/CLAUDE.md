# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What's here

Three kanata keyboard remap configs and the supporting tooling:

- `kanata.kbd` — MacBook Pro built-in keyboard (macOS)
- `kanata-logitech.kbd` — Logitech MX MCHNCL via USB receiver (macOS)
- `kanata-linux.kbd` — Logitech keyboard on Linux Mint XFCE + i3

The three `.kbd` files are deliberately near-duplicates and kept in sync. They all implement urob's "timeless" home-row-mod pattern (see "HRM architecture" below). Differences:

- The two macOS configs swap caps/esc, ctrl/cmd, and map physical Win↔Alt for Mac muscle memory. The Linux config does none of that — `lmet` stays as super so i3 can use it as `$mod`.
- The Logitech configs add `home`/`end` → `cmd+arrow` line nav and `c`/`x`/`v`/`t`/`u` tap-hold shortcuts. The Linux config has neither.
- Each config's `defcfg` pins to a specific device hash/name (`macos-dev-names-include` on Mac, `linux-dev-names-include` on Linux).

## Commands

```sh
# Validate any config without running it
kanata --cfg kanata.kbd --check

# Find the device hash to pin (run on the target machine)
kanata --list

# Regenerate cheatsheet.txt from kanata.kbd
python3 gen-cheatsheet.py

# The cheatsheet popup binary now lives in ../cheatsheet (build it there).
```

`~/.config/kanata` is a symlink to this directory, so the launchd plists and any kanata invocation that reads from `~/.config/kanata/*.kbd` end up here.

## HRM architecture (urob timeless pattern)

Every HRM key (a/s/d/f/j/k/l/;) uses the same shape:

```
(tap-hold-release-keys <tap-time> <hold-time>
  (tap-dance-eager <dance-timeout> ((multi <letter> @tap-streak) <letter>))
  <modifier>
  $<left-hand-keys|right-hand-keys>)
```

Three pieces work together:

1. **Bilateral positional** — `$left-hand-keys` / `$right-hand-keys` are the _force-tap_ trigger lists. Pressing a same-side key while the HRM is held resolves it as a tap.
2. **Typing-streak suppression** — the tap action runs `@tap-streak`, which switches to the `nomods` layer and queues an `on-idle-fakekey` that returns to base after `$idle-timeout` (150ms). The `nomods` layer rebinds a/s/d/f/j/k/l/; to plain letters so HRMs can't fire during a roll. This is the kanata equivalent of urob's `require-prior-idle-ms`.
3. **Double-tap-hold repeat** — `tap-dance-eager` wraps the tap action so press-release-press-hold within `$dance-timeout` yields OS auto-repeat.

A consequence of the streak shield: 2-key HRM chords in `defchordsv2` only fire from a cold start (no typing in the last 150ms). This is intentional.

The `c`/`x`/`v`/`t`/`u` aliases (macOS configs only) share the outer `tap-hold-release-keys` shape but their hold action is `(macro …)` and their release-keys list is `$typing-keys` (force-tap on _any_ typing key, not bilateral).

## Cheatsheet pipeline

`gen-cheatsheet.py` reads `kanata.kbd` only (both macOS configs are kept in sync, so parsing one suffices) and emits `cheatsheet.txt`. It detects:

- **HRMs** — tap-hold-release-keys aliases whose hold action is a bare modifier
- **Letter tap-holds** — tap-hold-release-keys aliases whose hold action is `(macro …)`
- **Chords** — entries inside `defchordsv2`
- **Key remaps** — defsrc/deflayer positions whose alias resolves to a single different keycode

Parsing uses a paren-balanced splitter in `iter_aliases()`. If you add a new HRM or shortcut style, the parser may need updating there (in particular, HRMs are distinguished from letter-shortcuts by whether the body contains `(macro …)`).

`cheatsheet.txt` is rendered by the combined popup in `../cheatsheet/` (a
multi-column, fuzzy-searchable Cocoa window showing Kanata alongside AeroSpace,
skhd, and Hammerspoon), bound to `Ctrl+Alt+K` and dismissed on focus loss or
Esc. This dir no longer has its own popup binary — see `../cheatsheet/README.md`.

## Toggle remapping on/off (live-reload pairs)

Each main config has a paired `*-passthrough.kbd` file with matching device specs, an empty defsrc beyond `caps`, and the same caps-toggle binding. Holding `caps` for 3 seconds fires `lrnx` (live-reload-next), cycling between the configs in the kanata process's `--cfg` list. Tap caps still emits esc as before. (The hold is intentionally long — caps gets bumped by accident during normal typing, and a shorter hold caused unwanted toggles.)

To enable, the launchd plist (or whatever invokes kanata) must pass both files:

```
--cfg /Users/.../kanata-logitech.kbd
--cfg /Users/.../kanata-logitech-passthrough.kbd
```

Forcefully exiting kanata is still available out-of-band: `Left Control + Space + Escape` held together (kanata-builtin, operates on raw input before any remap).

### Beyond two configs

Nothing requires the chain to stop at two. kanata accepts arbitrarily many `--cfg` flags; `lrnx`/`lrpv` cycle through them, and `(lrld-num N)` jumps to the Nth (1-indexed). Reasons to add a third (or more):

- **Gaming mode** — HRMs off, faster (or no) tap-hold timings, no streak shield. Treating "WASD held forever" as a tap-hold is wrong for games.
- **Per-app profiles** — e.g., a "vim-heavy" config that disables redundant shortcuts vs. a "browser/email" config. Pair with a watcher that calls `(lrld-num N)` via a signal when the focused app changes.
- **Tiered remap depth** — full HRMs ↔ just key-swaps (caps/esc, ctrl/cmd) ↔ raw passthrough. The middle tier is useful for A/B-ing which feature misbehaves when something breaks.
- **Alternate layouts** — qwerty ↔ colemak/dvorak at the kanata level (less common; usually OS-level).
- **Experimentation** — keep the stable config first, an experimental one second, passthrough third. `lrnx` to flip in and out without editing files.

Mechanics worth knowing:

- Per-config `defcfg` is **ignored** after the first load (device grab is fixed at startup). All configs in the chain share the device set from the first one — there's no point in giving them divergent `linux-dev` / `macos-dev-names-include` lists.
- For direct jumps, bind specific keys to `(lrld-num N)` rather than cycling — much faster than tapping caps three times to reach the third config.

## macOS daemons

- `com.user.kanata-builtin.plist` — keeps kanata running with the MBP builtin config (`kanata.kbd` + `kanata-passthrough.kbd`)
- `com.user.kanata-logitech.plist` — same, for the Logitech (`kanata-logitech.kbd` + `kanata-logitech-passthrough.kbd`)
- `com.user.kanata-logitech-watcher.plist` — runs `watch-logitech.sh`, which polls `kanata --list` for the device hash and `launchctl kickstart`s kanata-logitech when the device reappears (kanata doesn't reattach to a hot-plugged device on its own)

Install these by copying into `/Library/LaunchDaemons/` and `launchctl bootstrap`-ing.

The Homebrew formula's `homebrew.mxcl.kanata.plist` is **not** used — `com.user.kanata-builtin.plist` replaces it so the plist lives in dotfiles and survives `brew upgrade`. If you ever see it back (e.g. after a reinstall), `launchctl bootout` it before bootstrapping the user one.

## Conventions

- Keep `kanata.kbd` and `kanata-logitech.kbd` structurally identical (same aliases, same timings, same `defvar`/`defalias`/`defchordsv2`/`deflayer` ordering). When you edit one, mirror to the other.
- After any HRM/alias change, regenerate `cheatsheet.txt` so the popup stays accurate.
- Validate every config change with `kanata --cfg <file> --check` before committing.
