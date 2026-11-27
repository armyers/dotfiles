-- Rex configuration, migrated from tmux, zellij, Herdr, Ghostty, kitty, WezTerm and iTerm2.
-- tmux's ctrl+space prefix lost to zellij's ctrl+space (enter tmux mode), by choice.

-- zellij ---------------------------------------------------------------------
-- ~/.config/zellij/config.kdl (clear-defaults=true: only the file's bindings)

rex.action{
  name  = "then_normal",
  title = "Run an action and return to normal mode",
  args  = { action = "string", args = "object?" },
  run   = function(ctx, args)
    rex.client.queue(args.action, args.args or {})
    rex.client.queue("client.mode.exit_all")
  end,
}

rex.mode("pane", { exclusive = true })
rex.mode("tab", { exclusive = true })
rex.mode("resize", { exclusive = true })
rex.mode("move", { exclusive = true })
rex.mode("tmux", { exclusive = true })

-- normal
rex.bind("ctrl+space", "client.mode.enter", { name = "tmux" })
rex.bind("f12", "client.mode.enter", { name = "locked" })

-- locked
rex.bind("locked/f12", "client.mode.exit_all")
rex.bind("locked/ctrl+g", "client.mode.exit_all")

-- pane
rex.bind("pane/left", "pane.focus", { direction = "left" })
rex.bind("pane/down", "pane.focus", { direction = "down" })
rex.bind("pane/up", "pane.focus", { direction = "up" })
rex.bind("pane/right", "pane.focus", { direction = "right" })
rex.bind("pane/c", "then_normal", { action = "pane.rename" })
rex.bind("pane/d", "then_normal", { action = "pane.split", args = { direction = "down" } })
rex.bind("pane/f", "then_normal", { action = "pane.zoom" })
rex.bind("pane/h", "pane.focus", { direction = "left" })
rex.bind("pane/j", "pane.focus", { direction = "down" })
rex.bind("pane/k", "pane.focus", { direction = "up" })
rex.bind("pane/l", "pane.focus", { direction = "right" })
rex.bind("pane/n", "then_normal", { action = "pane.split", args = { direction = "auto" } })
rex.bind("pane/p", "pane.focus_next")
rex.bind("pane/ctrl+p", "client.mode.exit_all")
rex.bind("pane/r", "then_normal", { action = "pane.split", args = { direction = "right" } })

-- tab
rex.bind("tab/left", "client.tab.previous")
rex.bind("tab/down", "client.tab.next")
rex.bind("tab/up", "client.tab.previous")
rex.bind("tab/right", "client.tab.next")
for i = 1, 9 do
  rex.bind("tab/" .. i, "then_normal", { action = "client.tab.goto", args = { index = i } })
end
rex.bind("tab/b", "then_normal", { action = "pane.move_to_new_tab" })
rex.bind("tab/h", "client.tab.previous")
rex.bind("tab/j", "client.tab.next")
rex.bind("tab/k", "client.tab.previous")
rex.bind("tab/l", "client.tab.next")
rex.bind("tab/n", "then_normal", { action = "client.tab.new" })
rex.bind("tab/r", "then_normal", { action = "client.tab.rename" })
rex.bind("tab/ctrl+t", "client.mode.exit_all")
rex.bind("tab/shift+q", "then_normal", { action = "client.tab.close" })

-- resize
rex.bind("resize/left", "pane.resize", { direction = "left" })
rex.bind("resize/down", "pane.resize", { direction = "down" })
rex.bind("resize/up", "pane.resize", { direction = "up" })
rex.bind("resize/right", "pane.resize", { direction = "right" })
rex.bind("resize/h", "pane.resize", { direction = "left" })
rex.bind("resize/j", "pane.resize", { direction = "down" })
rex.bind("resize/k", "pane.resize", { direction = "up" })
rex.bind("resize/l", "pane.resize", { direction = "right" })
rex.bind("resize/ctrl+n", "client.mode.exit_all")

-- move
rex.bind("move/left", "pane.move", { direction = "left" })
rex.bind("move/down", "pane.move", { direction = "down" })
rex.bind("move/up", "pane.move", { direction = "up" })
rex.bind("move/right", "pane.move", { direction = "right" })
rex.bind("move/h", "pane.move", { direction = "left" })
rex.bind("move/ctrl+h", "client.mode.exit_all")
rex.bind("move/j", "pane.move", { direction = "down" })
rex.bind("move/k", "pane.move", { direction = "up" })
rex.bind("move/l", "pane.move", { direction = "right" })

-- tmux
rex.bind("tmux/left", "then_normal", { action = "pane.focus", args = { direction = "left" } })
rex.bind("tmux/down", "then_normal", { action = "pane.focus", args = { direction = "down" } })
rex.bind("tmux/up", "then_normal", { action = "pane.focus", args = { direction = "up" } })
rex.bind("tmux/right", "then_normal", { action = "pane.focus", args = { direction = "right" } })
rex.bind("tmux/ctrl+space", "then_normal", { action = "pane.send_key", args = { key = "ctrl+b" } })
rex.bind("tmux/,", "then_normal", { action = "client.tab.rename" })
rex.bind("tmux/-", "then_normal", { action = "pane.split", args = { direction = "down" } })
rex.bind("tmux/=", "client.mode.enter", { name = "resize" })
rex.bind("tmux/\\", "then_normal", { action = "pane.split", args = { direction = "right" } })
rex.bind("tmux/h", "then_normal", { action = "pane.focus", args = { direction = "left" } })
rex.bind("tmux/j", "then_normal", { action = "pane.focus", args = { direction = "down" } })
rex.bind("tmux/k", "then_normal", { action = "pane.focus", args = { direction = "up" } })
rex.bind("tmux/l", "then_normal", { action = "pane.focus", args = { direction = "right" } })
rex.bind("tmux/shift+h", "pane.move", { direction = "left" })
rex.bind("tmux/shift+j", "pane.move", { direction = "down" })
rex.bind("tmux/shift+k", "pane.move", { direction = "up" })
rex.bind("tmux/shift+l", "pane.move", { direction = "right" })
rex.bind("tmux/m", "client.mode.enter", { name = "move" })
rex.bind("tmux/o", "then_normal", { action = "pane.focus_next" })
rex.bind("tmux/p", "then_normal", { action = "pane.focus_previous" })
rex.bind("tmux/n", "pane.focus_next")
rex.bind("tmux/shift+q", "then_normal", { action = "client.tab.close" })
rex.bind("tmux/z", "then_normal", { action = "pane.zoom" })

-- shared_except / shared_among blocks, applied to each Rex mode they cover
local shared = { "pane", "tab", "resize", "move", "tmux" }
for _, m in ipairs(shared) do
  -- shared_except "locked"
  rex.bind(m .. "/f12", "client.mode.enter", { name = "locked" })
  -- shared_except "normal" "locked"
  rex.bind(m .. "/alt+left", "pane.focus", { direction = "left" })
  rex.bind(m .. "/alt+down", "pane.focus", { direction = "down" })
  rex.bind(m .. "/alt+up", "pane.focus", { direction = "up" })
  rex.bind(m .. "/alt+right", "pane.focus", { direction = "right" })
  rex.bind(m .. "/ctrl+g", "client.mode.enter", { name = "locked" })
  rex.bind(m .. "/alt+h", "pane.focus", { direction = "left" })
  rex.bind(m .. "/alt+i", "client.tab.move", { direction = "backward" })
  rex.bind(m .. "/alt+j", "pane.focus", { direction = "down" })
  rex.bind(m .. "/alt+k", "pane.focus", { direction = "up" })
  rex.bind(m .. "/alt+l", "pane.focus", { direction = "right" })
  rex.bind(m .. "/alt+n", "pane.split", { direction = "auto" })
  rex.bind(m .. "/alt+o", "client.tab.move", { direction = "forward" })
  -- shared_except "normal" "locked" "entersearch" (enter), and with renametab/renamepane (esc)
  rex.bind(m .. "/enter", "client.mode.exit_all")
  rex.bind(m .. "/esc", "client.mode.exit_all")
end
for _, m in ipairs({ "pane", "tab", "resize", "tmux" }) do
  rex.bind(m .. "/ctrl+h", "client.mode.enter", { name = "move" })
end
for _, m in ipairs({ "pane", "tab", "resize", "move" }) do
  rex.bind(m .. "/ctrl+b", "client.mode.enter", { name = "tmux" })
end
for _, m in ipairs({ "pane", "resize", "move", "tmux" }) do
  rex.bind(m .. "/ctrl+t", "client.mode.enter", { name = "tab" })
end
for _, m in ipairs({ "tab", "resize", "move", "tmux" }) do
  rex.bind(m .. "/ctrl+p", "client.mode.enter", { name = "pane" })
end
for _, m in ipairs({ "pane", "tab", "move", "tmux" }) do
  rex.bind(m .. "/ctrl+n", "client.mode.enter", { name = "resize" })
end
-- shared_among "pane" "tmux"
rex.bind("pane/shift+x", "then_normal", { action = "pane.close" })
rex.bind("tmux/shift+x", "then_normal", { action = "pane.close" })

-- WezTerm --------------------------------------------------------------------
-- ~/.config/wezterm/wezterm.lua (leader ctrl+b)

rex.bind("ctrl+b>ctrl+b", "pane.send_key", { key = "ctrl+b" })
rex.bind("ctrl+b>shift+p", "client.palette.toggle")
rex.bind("ctrl+b>ctrl+a", "pane.send_key", { key = "ctrl+a" })
rex.bind("ctrl+b>-", "pane.split", { direction = "down" })
rex.bind("ctrl+b>\\", "pane.split", { direction = "right" })
rex.bind("ctrl+b>z", "pane.zoom")
rex.bind("ctrl+b>c", "client.tab.new")
rex.bind("ctrl+b>shift+t", "client.tab.close")
rex.bind("ctrl+b>shift+h", "pane.resize", { amount = 5, direction = "left" })
rex.bind("ctrl+b>shift+j", "pane.resize", { amount = 5, direction = "down" })
rex.bind("ctrl+b>shift+k", "pane.resize", { amount = 5, direction = "up" })
rex.bind("ctrl+b>shift+l", "pane.resize", { amount = 5, direction = "right" })
rex.bind("ctrl+b>shift+x", "pane.close")
rex.bind("ctrl+b>h", "pane.focus", { direction = "left", wrap = true })
rex.bind("ctrl+b>l", "pane.focus", { direction = "right", wrap = true })
rex.bind("ctrl+b>k", "pane.focus", { direction = "up", wrap = true })
rex.bind("ctrl+b>j", "pane.focus", { direction = "down", wrap = true })
rex.bind("ctrl+b>n", "pane.focus_next")
rex.bind("ctrl+b>p", "pane.focus_previous")

-- Ghostty --------------------------------------------------------------------
-- ~/.config/ghostty/config:4 keybind = shift+enter=text:\n (LF is ctrl+j)

rex.bind("shift+enter", "pane.send_key", { key = "ctrl+j" })
