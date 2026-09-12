# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What's here

Three kanata keyboard remap configs and the supporting tooling:

- `kanata.kbd` — MacBook Pro built-in keyboard (macOS)
- `kanata-logitech.kbd` — Logitech MX MCHNCL via Bluetooth (macOS built-in, not a USB receiver)
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

# Verify both macOS TCC permissions still match the current binary
./check-permissions.sh

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
- `com.user.kanata-logitech.plist` — same, for the Logitech (`kanata-logitech.kbd` + `kanata-logitech-passthrough.kbd`). **`RunAtLoad` and `KeepAlive` are both `false`** — it is started only by the watcher below. See "Log growth" for why.
- `com.user.kanata-logitech-watcher.plist` — runs `watch-logitech.sh`, which polls `kanata --list` for the device (by name `MX MCHNCL`, since the hash drifts) and `launchctl kickstart`s kanata-logitech when it appears (kanata doesn't reattach to a hot-plugged device on its own). It owns that daemon's entire lifecycle and retry policy.
- `com.user.kanata-reset.plist` — mouse-only recovery. `QueueDirectories` on `~/.local/state/kanata`; when the Hammerspoon menu-bar item (or `reset-kanata.command`) drops a request file there, it runs `kanata-reset.sh` to clean-restart all three daemons. See "Mouse-only reset" below.
- `com.user.kanata-logtrim.plist` — hourly `trim-kanata-logs.sh`, which bounds `/opt/homebrew/var/log/kanata*.log`. Install with `sudo ~/.config/kanata/install-logtrim-daemon.sh`. See "Log growth".

Install these by copying into `/Library/LaunchDaemons/` and `launchctl bootstrap`-ing.

## Mouse-only reset

When a daemon jams, the keyboard(s) stop working, so the keyboard/`sudo` reset
paths (the skhd `cmd+ctrl+alt+shift+r` binding, or typing `sudo`) are
unreachable — the worst case was rebooting. The mouse-only path recovers without
a keyboard or a password:

1. Either entry point creates `~/.local/state/kanata/reset.request` — both are
   mouse-only and neither needs a password (the privileged work happens in the
   root daemon, not the trigger):
   - The Hammerspoon menu-bar item **⌨️ kanata → "Reset kanata daemons"** (`../hammerspoon/init.lua`).
   - `reset-kanata.command` — a double-clickable script (Finder runs `.command`
     files in Terminal). This is the fallback for when even the menu-bar icon is
     gone (e.g. Hammerspoon crashed, or the icon got garbage-collected). Keep a
     copy or alias on the Desktop or in the Dock for one-click access.
2. The root `com.user.kanata-reset` daemon watches that directory via `QueueDirectories`
   and runs `kanata-reset.sh` as root — no password, no keyboard.

Recovery layers, most to least dependent on a working keyboard: skhd
`cmd+ctrl+alt+shift+r` (needs a live keyboard) → Hammerspoon menu-bar icon (needs
Hammerspoon + its icon) → `reset-kanata.command` via Finder/Dock (mouse-only,
survives a dead keyboard _and_ a missing icon).

Install (the only step needing `sudo`):

```sh
sudo ~/.config/kanata/install-reset-daemon.sh
```

Two design choices matter, both learned the hard way:

- **`bootout` + `bootstrap`, never `kickstart -k`.** A `SIGKILL` can leave the
  device grab / Karabiner driver wedged and send kanata into a `SIGTRAP`
  crash-loop that only a reboot clears. `bootout` (graceful `SIGTERM`) lets
  kanata release cleanly.
- **No spurious reset at install/boot.** `QueueDirectories` only launches the job
  while the watched dir is non-empty. The installer creates the dir but not the
  request file, so it stays empty — and idle — until a menu-bar click drops the
  file in; `kanata-reset.sh` removes it first thing so launchd doesn't relaunch.
  (`WatchPaths`, tried first, does not fire reliably on directory _content_
  changes — hence `QueueDirectories`.)

The Homebrew formula's `homebrew.mxcl.kanata.plist` is **not** used — `com.user.kanata-builtin.plist` replaces it so the plist lives in dotfiles and survives `brew upgrade`. If you ever see it back (e.g. after a reinstall), `launchctl bootout` it before bootstrapping the user one.

## macOS permissions break on every kanata upgrade

kanata needs **two** TCC permissions on macOS, and missing either one produces
the identical symptom: `failed to open keyboard device(s)`, the process exits,
and `KeepAlive` restarts it every ~10s — a crash loop that leaves the keyboard
unremapped.

| TCC service | System Settings pane | Notes |
| --- | --- | --- |
| `kTCCServiceListenEvent` | Input Monitoring | Read the physical keyboard |
| `kTCCServiceAccessibility` | Accessibility | Added in kanata 1.12.0 ([#1211](https://github.com/jtroo/kanata/issues/1211)); 1.11.0 did not need it |

The trap: **TCC pins each grant to the binary's cdhash**, not to its path or
name. Homebrew's kanata is ad-hoc signed, so every `brew upgrade` yields a new
cdhash and silently revokes both grants. The stale entry still shows in System
Settings under the same name "kanata", toggled on, looking perfectly healthy.

There is no path trick that avoids this. `/opt/homebrew/opt/kanata/bin/kanata`
(what the plists invoke) is a symlink into the versioned Cellar directory, and
TCC resolves symlinks to the real path and pins the hash regardless. Copying the
binary to a fixed location doesn't help either — the copy's hash still changes on
each upgrade.

Mitigations in place:

- **`brew pin kanata`** — upgrades become deliberate instead of a surprise that
  eats your keyboard remaps. Run `brew unpin kanata` when you actually want one.
- **`check-permissions.sh`** — reads `ProgramArguments[0]` out of the builtin
  plist, resolves it, compares its `codesign` cdhash against the csreq blob in
  both TCC rows, and distinguishes "never granted" from "granted to a stale
  binary" (the latter needs a **remove** before the re-add). Also reachable from
  the Hammerspoon **⌨️ kanata → "Check permissions…"** menu item.

  Reading `TCC.db` requires Full Disk Access for the calling process. Terminal
  typically has it; Hammerspoon typically does not, so the script falls back to
  checking daemon liveness plus recent log errors. Run it from a terminal when
  you want the precise per-permission verdict.

### Re-granting after an upgrade

For **each** of the two panes — remove any existing kanata entry first, since a
stale one looks identical to a valid one:

```sh
./check-permissions.sh          # tells you which of the two are broken
open "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent"
open "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
# Reveal the binary in Finder (check-permissions.sh prints its exact path)
open -R /opt/homebrew/Cellar/kanata/<version>/bin/kanata
```

In each pane: `−` the stale entry, `+`, then drag the binary in or press `⌘⇧G`
and paste its full Cellar path. Then restart the daemons (`bootout` +
`bootstrap`, never `kickstart -k` — see above).

## Log growth

The kanata logs are unbounded by default and had been growing ~15 MB/day from
two unrelated causes. Both are handled now, but they needed different fixes —
one was a bug, the other is inherent.

**1. `kanata-logitech.log` — a crash loop (~12.6 MB/day). Fixed at the root.**

The daemon used to be `RunAtLoad=true` / `KeepAlive=true`. Whenever the Bluetooth
keyboard was disconnected, kanata exited with `Couldn't register any device` and
launchd relaunched it ~10s later, forever. 483 restarts were logged before this
was noticed, burying real errors under identical repeats.

launchd has no way to express "start when this device appears", but
`watch-logitech.sh` already polls for exactly that — so the daemon is now
`RunAtLoad=false` / `KeepAlive=false` and the watcher owns its lifecycle:

- **Level-triggered**, not edge-triggered. The old watcher fired on an
  absent→present transition, which misses a kanata crash while the keyboard
  stays connected (no transition ever occurs, so nothing restarts it) and misses
  a `bootout`+`bootstrap` from `kanata-reset.sh`. It now starts the daemon
  whenever _device present AND daemon not running_, which recovers from both.
- **Exponential backoff** (10s → 600s) so a persistently failing start — revoked
  TCC permissions after a `brew upgrade`, a bad config — degrades to occasional
  retries instead of hammering `launchctl` every 2s and re-creating the flood.
  The backoff only resets after the daemon survives ~30s, so a fast
  crash-start-crash cycle can't keep it pinned at the minimum.
- Plain `kickstart`, never `kickstart -k` (same SIGKILL reasoning as
  `kanata-reset.sh`).
- **The device probe is an array and validates that it ran.** `LIST_CMD` used
  to be a string invoked as `"$LIST_CMD"` — fully quoted, so bash searched for a
  command literally named `/opt/homebrew/opt/kanata/bin/kanata --list`. It never
  ran, the error was swallowed by the `2>&1 | grep` consuming it, and every poll
  silently concluded "keyboard absent". The watcher log sat at 0 bytes from May
  until September because of it.

  That was survivable only because `KeepAlive` was independently retrying every
  ~10s and grabbing the keyboard anyway — the watcher was decorative and nobody
  knew. Removing `KeepAlive` promoted it to load-bearing and the dormant bug
  became "the Logitech never works". **A probe that cannot run must never be
  indistinguishable from a negative result**, so `device_present` now checks
  exit status and the expected listing header before trusting an "absent", and
  logs loudly (rate-limited to 5 min) when the probe itself is broken.

**2. `kanata-builtin.log` — inherent chatter (~2.7 MB/day). Bounded, not fixed.**

A healthy builtin daemon still emits a bare `virtual_hid_keyboard_ready true`
line on a timer. It comes from the Karabiner VirtualHIDDevice client library
printing straight to stdout — note it carries no timestamp or log-level prefix,
because it never passes through kanata's logger. `--quiet` therefore does not
suppress it and no kanata flag does. It can only be bounded.

`trim-kanata-logs.sh` (hourly, via `com.user.kanata-logtrim`) truncates any
`kanata*.log` over 5 MB down to its last 2000 lines.

> [!IMPORTANT]
> It truncates **in place** and must keep doing so. `/etc/newsyslog.d` is the
> usual macOS answer, but newsyslog rotates by _renaming_ — and launchd holds an
> open fd on the original inode, so it would keep writing to the rotated file
> while the fresh log stayed empty forever. newsyslog has no `copytruncate`.
>
> In-place truncation works because launchd opens `StandardOutPath` with
> `O_APPEND`: every write is positioned at the current end of file, so after a
> truncation the daemon's next write lands at offset 0 — no restart, no lost
> bytes, no NUL padding. `cat tmp > "$f"` is what preserves the inode; a `mv`
> would reintroduce the newsyslog bug.

## Conventions

- Keep `kanata.kbd` and `kanata-logitech.kbd` structurally identical (same aliases, same timings, same `defvar`/`defalias`/`defchordsv2`/`deflayer` ordering). When you edit one, mirror to the other.
  - **Deliberate exception:** the function-row → media-key mappings (`f1 f2 f7-f12` → brightness/media/volume) live in `kanata.kbd` **only**. They exist because grabbing the Apple internal keyboard through the Karabiner virtual HID device bypasses macOS's built-in fn-row → media translation, leaving raw F-keys. The Logitech's fn row already emits media keys natively, so mirroring there is unnecessary and would only risk breaking what works. Do **not** copy them into `kanata-logitech.kbd`.
- After any HRM/alias change, regenerate `cheatsheet.txt` so the popup stays accurate.
- Validate every config change with `kanata --cfg <file> --check` before committing.
