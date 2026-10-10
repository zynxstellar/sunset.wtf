local Settings = {IsColdWar = true, StartupStage = function() end}
local BedWars = {Running = false}
-- This is the entire production setup definition, not a replacement. Running
-- it here would immediately touch unavailable game/UI APIs and fail the test.
-- INSERT_BEDWARS_RUNTIME
-- INSERT_GAME_RUNTIME_DISPATCH
BedWars.Stop()
assert(not BedWars.Running)
local runs = 0
Settings.SetupBedWarsRuntime = function() runs += 1 end
Settings.IsColdWar = false
local function initializeOtherGame()
    -- INSERT_GAME_RUNTIME_DISPATCH
end
initializeOtherGame()
initializeOtherGame()
assert(runs == 2, "other games lost their BedWars/shared runtime")

local scans, listeners, targets = 0, 0, 0
local workspace = {
    GetDescendants = function() scans += 1 return {"Head", "RootPart"} end,
    DescendantAdded = {Connect = function(_, fn) listeners += 1 return fn end},
}
local function registerTargetPart() targets += 1 end
local function track(value) return value end
local function initializeTargets()
    -- INSERT_TARGET_DISPATCH
end
Settings.IsColdWar = true
initializeTargets()
assert(scans == 0 and listeners == 0 and targets == 0, "Cold War scanned the entire map")
Settings.IsColdWar = false
initializeTargets()
assert(scans == 1 and listeners == 1 and targets == 2)

local ENV = {}
local SUNSET_BUILD = "test-build"
local typeof = type
local downloads, assets, writes, exists = 0, 0, 0, false
local game = {HttpGet = function() downloads += 1 return string.rep("data", 50) end}
local getcustomasset = function() assets += 1 return "cached-image" end
local isfile = function() return exists end
local writefile = function() writes += 1 end
local makefolder = function() end
-- INSERT_ASSET_PRODUCTION
Settings.IsColdWar = true
assert(riftAsset("missing.png") == nil)
assert(riftAsset("missing.png") == nil)
assert(downloads == 0 and assets == 0 and writes == 0, "Cold War blocked on optional artwork")
exists = true
assert(riftAsset("cached.png") == "cached-image" and assets == 1 and downloads == 0)
Settings.IsColdWar = false
exists = false
assert(riftAsset("other-game.png") == "cached-image")
assert(downloads == 1 and writes == 1 and assets == 2, "other games lost artwork loading")
print("PASS Cold War startup: production BedWars setup skipped, cleanup does not touch native state, no world scan, cached/drawn icons without network wait, other-game paths retained")
