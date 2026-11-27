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
	local ok, res = pcall(function()
		return rex.session.list({})
	end)
	if not ok or type(res) ~= "table" or type(res.sessions) ~= "table" then
		return true -- can't tell; let session.select try
	end
	for _, s in ipairs(res.sessions) do
		if s.session_id == id then
			return true
		end
	end
	return false
end

rex.action({
	name = "switch_session",
	title = "Change Session (remember current)",
	run = function(ctx)
		if ctx.session_id then
			last_session_id = ctx.session_id
		end
		rex.client.queue("session.switch")
	end,
})

rex.action({
	name = "last_session",
	title = "Go to Last Session",
	run = function(ctx)
		local cur = ctx.session_id
		local target = last_session_id
		if target and target ~= cur and session_exists(target) then
			rex.client.queue("session.select", { session_id = target })
		else
			rex.client.queue("session.previous")
		end
		if cur then
			last_session_id = cur
		end
	end,
})

rex.bind("cmd+p", "client.palette.toggle")
rex.bind("cmd+shift+p", "switch_session")
rex.bind("cmd+shift+o", "last_session")

-- panes ----------------------------------------------------------------------

-- Last-pane toggle, scoped to the current session (client.navigate.back also
-- crosses sessions, which made it overlap with cmd+shift+o). Rex keeps no
-- focus history and sends init.lua no focus events, so remember the focused
-- pane, per session, whenever these bindings move focus. Mouse clicks aren't
-- seen, but the pane focused at key-press time is always read fresh.
local last_block = {} -- session_id -> block_id

local function remember_block(ctx)
	if ctx.session_id and ctx.block_id then
		last_block[ctx.session_id] = ctx.block_id
	end
end

rex.action({
	name = "focus_dir",
	title = "Focus Pane (remember current)",
	args = { direction = "string" },
	run = function(ctx, args)
		remember_block(ctx)
		rex.client.queue("pane.focus", { direction = args.direction })
	end,
})

rex.action({
	name = "last_pane",
	title = "Go to Last Pane in Session",
	run = function(ctx)
		local cur = ctx.block_id
		local target = ctx.session_id and last_block[ctx.session_id]
		remember_block(ctx)
		if target and target ~= cur then
			local _, err = rex.session.focus_block({ session_id = ctx.session_id, block_id = target })
			if err == nil then
				return
			end
		end
		rex.client.queue("pane.focus_previous")
	end,
})

rex.bind("ctrl+cmd+h", "focus_dir", { direction = "left" })
rex.bind("ctrl+cmd+j", "focus_dir", { direction = "down" })
rex.bind("ctrl+cmd+k", "focus_dir", { direction = "up" })
rex.bind("ctrl+cmd+l", "focus_dir", { direction = "right" })
rex.bind("ctrl+cmd+o", "last_pane")

rex.bind("cmd+shift+h", "pane.resize", { direction = "left" })
rex.bind("cmd+shift+j", "pane.resize", { direction = "down" })
rex.bind("cmd+shift+k", "pane.resize", { direction = "up" })
rex.bind("cmd+shift+l", "pane.resize", { direction = "right" })

rex.bind("cmd+shift+enter", "pane.zoom")
rex.bind("cmd+w", "pane.close")

-- help -----------------------------------------------------------------------

-- Pop up a floating pane with this config's bindings (`rex keymap`) in less.
-- The pane closes when less exits (q). Only shows init.lua bindings, not the
-- app's built-in defaults.
local rex_bin_dir = "/Applications/Rex.app/Contents/Helpers/Rex Server.rex/Contents/MacOS"

rex.action({
	name = "show_keymap",
	title = "Show Keymap",
	run = function(ctx)
		local _, err = rex.session.new_layer({
			session_id = ctx.session_id,
			bounds = { 0.1, 0.1, 0.8, 0.8 },
			focus = true,
			layout = {
				block = {
					flavor = "com.superlogical.terminal.shell",
					label = "keymap",
					options = {
						path_prepend = { rex_bin_dir },
						command = { "sh", "-c", "rex --color always keymap | less -R" },
					},
				},
			},
		})
		if err ~= nil then
			error(err, 0)
		end
	end,
})

rex.bind("ctrl+shift+cmd+p", "show_keymap")

-- terminal -------------------------------------------------------------------

-- shift+enter inserts a newline (LF is ctrl+j), as in Ghostty
