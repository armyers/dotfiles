-- Rex configuration
--
-- cmd-based, mode-less bindings (no tmux/zellij prefix keys or key modes),
-- matching CYOTE-arm's default shortcuts.
--
-- Apply with: rex config reload   (check first with: rex config check)
-- Inspect with: rex keymap / rex -C <client> actions

-- palette & sessions ---------------------------------------------------------

-- Remember the session we were in whenever we start switching sessions, so
-- cmd+shift+o can jump back to it (MRU toggle). Rex sends init.lua no
-- focus/session events, so switches made with the mouse or sidebar aren't
-- seen; in that case cmd+shift+o falls back to "Previous Session".
local last_session_id = nil

local function session_exists(id)
  local ok, res = pcall(function() return rex.session.list{} end)
  if not ok or type(res) ~= "table" or type(res.sessions) ~= "table" then
    return true -- can't tell; let session.select try
  end
  for _, s in ipairs(res.sessions) do
    if s.session_id == id then return true end
  end
  return false
end

rex.action{
  name  = "switch_session",
  title = "Change Session (remember current)",
  run   = function(ctx)
    if ctx.session_id then last_session_id = ctx.session_id end
    rex.client.queue("session.switch")
  end,
}

rex.action{
  name  = "last_session",
  title = "Go to Last Session",
  run   = function(ctx)
    local cur = ctx.session_id
    local target = last_session_id
    if target and target ~= cur and session_exists(target) then
      rex.client.queue("session.select", { session_id = target })
    else
      rex.client.queue("session.previous")
    end
    if cur then last_session_id = cur end
  end,
}

rex.bind("cmd+p", "client.palette.toggle")
rex.bind("cmd+shift+p", "switch_session")
rex.bind("cmd+shift+o", "last_session")

-- panes ----------------------------------------------------------------------

rex.bind("ctrl+cmd+h", "pane.focus", { direction = "left" })
rex.bind("ctrl+cmd+j", "pane.focus", { direction = "down" })
rex.bind("ctrl+cmd+k", "pane.focus", { direction = "up" })
rex.bind("ctrl+cmd+l", "pane.focus", { direction = "right" })

-- "the pane you were in before this one, in any tab or session"
rex.bind("ctrl+cmd+o", "client.navigate.back")

rex.bind("cmd+shift+h", "pane.resize", { direction = "left" })
rex.bind("cmd+shift+j", "pane.resize", { direction = "down" })
rex.bind("cmd+shift+k", "pane.resize", { direction = "up" })
rex.bind("cmd+shift+l", "pane.resize", { direction = "right" })

rex.bind("cmd+shift+enter", "pane.zoom")
rex.bind("cmd+w", "pane.close")

-- terminal -------------------------------------------------------------------

-- shift+enter inserts a newline (LF is ctrl+j), as in Ghostty
rex.bind("shift+enter", "pane.send_key", { key = "ctrl+j" })
