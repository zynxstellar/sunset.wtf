-- The ready menu cannot depend on a task callback or a working tween service.
local ENV = {}
local Gui = {Parent = true}
local Window = {Visible = false}
local Settings = {GameBoards = {}}
local menuUpdates = 0
local function onMenuVisibility()
    assert(ENV.SunsetLoading == nil, "menu still thinks startup is loading")
    menuUpdates += 1
end
local task = setmetatable({}, {__index = function() error("loading handoff scheduled a task") end})
local TweenService = setmetatable({}, {__index = function() error("loading handoff needs a tween") end})
-- INSERT_LOADING_PRODUCTION

local function loadingInstance()
    local object = {Parent = true, Enabled = true, Destroy = function(self) self.Parent = nil end}
    return {Gui = object}
end
for _, name in ipairs({"Cold War", "Rivals", "BedWars"}) do
    local board = {Parent = true, Visible = false}
    Settings.GameBoards[name] = board
    local loading = loadingInstance()
    ENV.SunsetLoading = loading
    assert(Settings.CompleteStartup(loading, name))
    assert(board.Visible and not loading.Gui.Parent and not loading.Gui.Enabled)
    assert(ENV.SunsetLoading == nil, "RightShift remained blocked")
    assert(not Settings.CompleteStartup(loading, name), "completed startup ran twice")
end
assert(menuUpdates == 3)

-- Old startup and unload callbacks cannot reopen a menu or clear a newer load.
local old, current = loadingInstance(), loadingInstance()
ENV.SunsetLoading = current
assert(not Settings.CompleteStartup(old, "Cold War"))
assert(ENV.SunsetLoading == current and current.Gui.Parent and old.Gui.Parent)
Gui.Parent = nil
assert(not Settings.CompleteStartup(current, "Cold War"))
assert(ENV.SunsetLoading == current and menuUpdates == 3)
Gui.Parent = true

-- A missing overlay or failed destruction must not block access to the menu.
local loading = {Gui = {Enabled = true, Destroy = function() error("destroy failed") end}}
ENV.SunsetLoading = loading
Settings.GameBoards["Cold War"].Visible = false
assert(Settings.CompleteStartup(loading, "Cold War"))
assert(not loading.Gui.Enabled and Settings.GameBoards["Cold War"].Visible)
loading = {}
ENV.SunsetLoading = loading
assert(Settings.CompleteStartup(loading, "Unknown") and Window.Visible)

local game = {}
local typeof = type
local hookmetamethod, newcclosure, checkcaller = function() end, function() end, function() end
local function hookPolicy()
    -- INSERT_HOOK_POLICY
    return canHook
end
game.PlaceId, game.GameId = 13687899540, 0
assert(not hookPolicy(), "Cold War installed a global property hook")
game.PlaceId, game.GameId = 1, 4750561026
assert(not hookPolicy(), "Cold War subplace installed a global property hook")
game.PlaceId, game.GameId = 17625359962, 6035872082
assert(not hookPolicy(), "Rivals installed a global property hook")
game.PlaceId, game.GameId = 6872265039, 2619619496
assert(not hookPolicy(), "BedWars installed a global property hook")
print("PASS loading: synchronous handoff, no task/tween dependency, stale/unload ownership, cleanup failure, Cold War hook isolation")
