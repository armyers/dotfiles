------------------------------------------------------------
-- Keyboard mouse-wheel scrolling
-- cmd+shift + h/j/k/l -> scroll left/down/up/right.
-- Hold to scroll continuously (timer-driven, smooth); release to stop.
--
-- The cmd+shift chord is produced by the kanata home-row mods
-- (left-hand s+d or right-hand k+l). kanata cannot emit scroll events
-- on macOS (mwheel is a no-op there), so Hammerspoon drives the wheel.
------------------------------------------------------------

local SCROLL_MODS   = { "cmd", "shift" }
local TICK_INTERVAL = 0.015   -- seconds between ticks while held (~66/s)
local SCROLL_STEP   = 28      -- units per tick (raise = faster)
local SCROLL_UNIT   = "pixel" -- "pixel" = smooth, "line" = notched

-- hs.eventtap.scrollWheel({horizontal, vertical}, mods, unit)
-- vertical:   positive = up,   negative = down
-- horizontal: positive = left, negative = right
-- (If a direction feels reversed, flip its sign below or toggle
--  System Settings > Trackpad > "Natural scrolling".)
local DIRS = {
  h = {  SCROLL_STEP,  0 },  -- left
  l = { -SCROLL_STEP,  0 },  -- right
  k = {  0, -SCROLL_STEP },  -- up
  j = {  0,  SCROLL_STEP },  -- down
}

local scrollTimer = nil

local function stopScroll()
  if scrollTimer then
    scrollTimer:stop()
    scrollTimer = nil
  end
end

local function startScroll(dx, dy)
  stopScroll()
  -- One immediate tick so the first press feels instant, then repeat.
  hs.eventtap.scrollWheel({ dx, dy }, {}, SCROLL_UNIT)
  scrollTimer = hs.timer.doEvery(TICK_INTERVAL, function()
    hs.eventtap.scrollWheel({ dx, dy }, {}, SCROLL_UNIT)
  end)
end

for key, d in pairs(DIRS) do
  hs.hotkey.bind(SCROLL_MODS, key,
    function() startScroll(d[1], d[2]) end,  -- pressed
    function() stopScroll() end)             -- released
end

hs.alert.show("Scroll bindings loaded")

------------------------------------------------------------
-- Kanata reset menu-bar item (mouse-only, keyboard-independent)
--
-- When a kanata daemon jams, the keyboard stops working — so the usual
-- keyboard/sudo reset is unreachable. Clicking this menu-bar item instead
-- creates a request file that a root LaunchDaemon (com.user.kanata-reset)
-- watches; that daemon clean-restarts all three kanata daemons (bootout +
-- bootstrap, no SIGKILL) with no password. See ../kanata/CLAUDE.md.
------------------------------------------------------------

local RESET_DIR = os.getenv("HOME") .. "/.local/state/kanata"
local RESET_REQ = RESET_DIR .. "/reset.request"

local function requestKanataReset()
  -- Create the request file; the root daemon reacts to the directory change.
  os.execute(string.format("/bin/mkdir -p %q && /usr/bin/touch %q", RESET_DIR, RESET_REQ))
  hs.alert.show("Resetting kanata daemons…")
end

local kanataMenu = hs.menubar.new()
if kanataMenu then
  kanataMenu:setTitle("⌨️ kanata")
  kanataMenu:setTooltip("Reset kanata daemons")
  kanataMenu:setMenu({
    { title = "Reset kanata daemons", fn = requestKanataReset },
  })
end
