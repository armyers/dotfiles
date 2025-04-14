-- Pull in the wezterm API
local wezterm = require("wezterm")
--
-- This will hold the configuration.
local config = wezterm.config_builder()

-- INFO: use as needed
-- config.debug_key_events = true

config.default_cwd = wezterm.home_dir
config.default_workspace = "adhoc"

config.enable_kitty_graphics = true

-- increase fps for display speed
config.max_fps = 120

-- set the color scheme:
-- config.color_scheme = "Catppuccin Mocha (Gogh)"

-- define word boundaries
config.selection_word_boundary = "-<>{}[]()\"'`.,;:$/= "

-- buffer scrollback
-- How many lines of scrollback you want to retain per tab
config.scrollback_lines = 100000

-- Enable the scrollbar.
-- It will occupy the right window padding space.
-- If right padding is set to 0 then it will be increased
-- to a single cell width
config.enable_scroll_bar = true

-- make sure this is true
config.unzoom_on_switch_pane = true

-- bump the font size
config.font_size = 15

config.unix_domains = {
  {
    name = "unix",
  },
}

---@diagnostic disable-next-line: unused-local
wezterm.on("update-right-status", function(window, pane)
  window:set_left_status(window:active_workspace())
  window:set_right_status("")
end)

config.use_fancy_tab_bar = false
config.show_tabs_in_tab_bar = true
-- config.show_new_tab_button_in_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false

config.inactive_pane_hsb = {
  saturation = 1,
  brightness = 0.35,
}

config.leader = {
  key = " ",
  mods = "CTRL",
  timeout_milliseconds = 3000,
}

-- Helper function for wrap around pane navigation
local function wrap_activate_pane(window, target_direction, opposite_direction)
  local original_pane = window:active_pane()
  local original_tab = window:active_tab()

  if not original_pane or not original_tab then
    return
  end

  -- Attempt to activate the next pane in the direction
  window:perform_action(wezterm.action.ActivatePaneDirection(target_direction), original_pane)

  -- If the pane doesn't change, we must be at the edge, so wrap to the opposite pane
  local new_active_pane = window:active_pane()
  if new_active_pane:pane_id() == original_pane:pane_id() then
    repeat
      local current_pane_id = new_active_pane:pane_id()
      -- switch to window in opposite direction
      window:perform_action(wezterm.action.ActivatePaneDirection(opposite_direction), new_active_pane)
      -- get new active pane
      new_active_pane = window:active_pane()
    -- once new pane and old pane stop being different, we are at the other edge
    until new_active_pane:pane_id() == current_pane_id
  end
end

wezterm.on("wrap-activate-pane-left", function(window, pane)
  wrap_activate_pane(window, "Left", "Right")
end)

wezterm.on("wrap-activate-pane-right", function(window, pane)
  wrap_activate_pane(window, "Right", "Left")
end)

wezterm.on("wrap-activate-pane-up", function(window, pane)
  wrap_activate_pane(window, "Up", "Down")
end)

wezterm.on("wrap-activate-pane-down", function(window, pane)
  wrap_activate_pane(window, "Down", "Up")
end)

config.keys = {
  -- NOTE: I'll just leave these right here, just in case...
  { key = "D", mods = "LEADER|SHIFT", action = wezterm.action.ShowDebugOverlay },
  { key = "P", mods = "LEADER|SHIFT", action = wezterm.action.ActivateCommandPalette },

  -- NOTE: That's the way, uh-huh, uh-huh, I like it, uh-huh,
  { key = "a", mods = "LEADER|CTRL", action = wezterm.action({ SendString = "\x01" }) },
  { key = "-", mods = "LEADER", action = wezterm.action({ SplitVertical = { domain = "CurrentPaneDomain" } }) },
  { key = "\\", mods = "LEADER", action = wezterm.action({ SplitHorizontal = { domain = "CurrentPaneDomain" } }) },
  { key = "z", mods = "LEADER", action = "TogglePaneZoomState" },
  { key = "c", mods = "LEADER", action = wezterm.action({ SpawnTab = "CurrentPaneDomain" }) },
  { key = "t", mods = "LEADER", action = wezterm.action.ShowTabNavigator },
  { key = "T", mods = "LEADER", action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  { key = "H", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Left", 5 } }) },
  { key = "J", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Down", 5 } }) },
  { key = "K", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Up", 5 } }) },
  { key = "L", mods = "LEADER|SHIFT", action = wezterm.action({ AdjustPaneSize = { "Right", 5 } }) },
  { key = "X", mods = "LEADER", action = wezterm.action({ CloseCurrentPane = { confirm = true } }) },
  { key = "w", mods = "LEADER", action = wezterm.action.SwitchWorkspaceRelative(1) },
  { key = "W", mods = "LEADER|SHIFT", action = wezterm.action.SwitchWorkspaceRelative(-1) },

  { key = "h", mods = "LEADER", action = wezterm.action.EmitEvent("wrap-activate-pane-left") },
  { key = "l", mods = "LEADER", action = wezterm.action.EmitEvent("wrap-activate-pane-right") },
  { key = "k", mods = "LEADER", action = wezterm.action.EmitEvent("wrap-activate-pane-up") },
  { key = "j", mods = "LEADER", action = wezterm.action.EmitEvent("wrap-activate-pane-down") },
  { key = "n", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Next") },
  { key = "p", mods = "LEADER", action = wezterm.action.ActivatePaneDirection("Prev") },
  { key = "x", mods = "LEADER", action = wezterm.action.ActivateCopyMode },

  {
    -- Show the launcher in fuzzy selection mode and have it list all workspaces
    -- and allow activating one.
    key = "s",
    mods = "LEADER",
    action = wezterm.action.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }),
  },
  {
    -- create a new workspace
    key = "N",
    mods = "LEADER|SHIFT",
    action = wezterm.action.PromptInputLine({
      description = wezterm.format({
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { AnsiColor = "Fuchsia" } },
        { Text = "Enter name for new workspace: " },
      }),
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:perform_action(
            wezterm.action.SwitchToWorkspace({
              name = line,
              spawn = { cwd = wezterm.home_dir },
            }),
            pane
          )
        end
      end),
    }),
  },
  {
    -- rename the current workspace
    key = "R",
    mods = "LEADER",
    action = wezterm.action.PromptInputLine({
      description = wezterm.format({
        { Attribute = { Intensity = "Bold" } },
        { Foreground = { AnsiColor = "Fuchsia" } },
        { Text = "Enter new name for current workspace: " },
      }),
      action = wezterm.action_callback(function(window, pane, line)
        -- line will be `nil` if they hit escape without entering anything
        -- An empty string if they just hit enter
        -- Or the actual line of text they wrote
        if line then
          window:perform_action(wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line), pane)
        end
      end),
    }),
  },
}

-- Colors adapted to approximate the Neovim "Vague" colorscheme
config.colors = {
  -- The default text colors
  foreground = "#c5c8c6", -- a light gray used for text
  background = "#1d1f21", -- a nearly black/dark background

  -- Cursor colors
  cursor_bg = "#aeafad",
  cursor_border = "#aeafad",
  cursor_fg = "#1d1f21",

  -- Selection colors
  selection_bg = "#373b41",
  selection_fg = "#c5c8c6",

  -- ANSI 16-color palette
  ansi = {
    "#1d1f21", -- black
    "#cc6666", -- red
    "#b5bd68", -- green
    "#f0c674", -- yellow
    "#81a2be", -- blue
    "#b294bb", -- magenta
    "#8abeb7", -- cyan
    "#c5c8c6", -- white
  },
  brights = {
    "#969896", -- bright black
    "#cc6666", -- bright red
    "#b5bd68", -- bright green
    "#f0c674", -- bright yellow
    "#81a2be", -- bright blue
    "#b294bb", -- bright magenta
    "#8abeb7", -- bright cyan
    "#ffffff", -- bright white
  },

  -- Tab bar styling (optional)
  tab_bar = {
    background = "#282a2e",
    active_tab = {
      bg_color = "#1d1f21",
      fg_color = "#c5c8c6",
      intensity = "Bold",
      underline = "None",
      italic = false,
    },
    inactive_tab = {
      bg_color = "#282a2e",
      fg_color = "#5f5a60",
    },
    inactive_tab_hover = {
      bg_color = "#373b41",
      fg_color = "#c5c8c6",
    },
  },
}

return config
