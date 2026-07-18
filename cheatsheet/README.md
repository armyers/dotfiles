# Combined Cheatsheet Popup

A single native macOS popup that shows the **AeroSpace**, **Kanata**, **skhd**,
and **Hammerspoon** keybindings side by side, with live fuzzy search. Triggered
by `ctrl + alt + k`.

## Files

| File               | Purpose                                                      |
| ------------------ | ------------------------------------------------------------ |
| `cheatsheet.swift` | Cocoa popup: one scrollable column per source + fuzzy search |
| `cheatsheet`       | Compiled binary (built from `cheatsheet.swift`, gitignored)  |
| `Makefile`         | Builds the binary                                            |

## How it works

The `alt-ctrl-k` binding in [`../aerospace/aerospace.toml`](../aerospace/aerospace.toml)
regenerates every source's cheatsheet, then launches this popup:

```
python3 ~/.config/aerospace/gen-cheatsheet.py \
  && python3 ~/.config/kanata/gen-cheatsheet.py \
  && python3 ~/.config/skhd/gen-cheatsheet.py \
  && python3 ~/.config/hammerspoon/gen-cheatsheet.py \
  && ~/.config/cheatsheet/cheatsheet
```

The binary reads each source's `cheatsheet.txt` (`aerospace`, `kanata`, `skhd`,
`hammerspoon` — resolved via its own path, with a `~/.config/<name>/cheatsheet.txt`
fallback), parses each into titled sections, and renders one column per source.
Columns are sized to their own content, and the window grows to fit them all
(capped at 95% of screen width).

- **Fuzzy search** — type to filter; matching is a case-insensitive subsequence
  test (spaces ignored, so `ctrl shift` matches `ctrl+shift`). Matched
  characters are highlighted; section headers are kept for context.
- **Dismiss** — `esc`, or click away (focus loss).

To add another source, drop a `gen-cheatsheet.py` in its config dir that writes
a `cheatsheet.txt`, add the dir name to the `files` list in `cheatsheet.swift`,
and add its generator to the `alt-ctrl-k` binding.

## Rebuilding the binary

Only needed if you edit `cheatsheet.swift` (appearance, colors, window size):

```sh
cd ~/.config/cheatsheet
make
```

Content changes need no rebuild — edit the source config and its
`gen-cheatsheet.py` regenerates the `.txt` on every invocation.
