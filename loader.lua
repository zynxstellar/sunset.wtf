-- Update both release values together when publishing a new client build.
local rivals = game.PlaceId == 17625359962 or game.GameId == 6035872082
local expectedBuild = rivals
    and "20261008-rift-rivals-clean-ui-k269"
    or "20261007-rift-project-delta-spin-view-k301"
local sourceUrl = rivals
    and "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/17aa05efb132aa15557b76be386954beaac6f3cd/rivals.lua"
    or "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/f156d8bca8694e43bb3e4f3095a225a63d015311/alua"

local ok, source = pcall(game.HttpGet, game, sourceUrl)
assert(ok and type(source) == "string", "RIFT: current build download failed: " .. tostring(source))
local actualBuild = source:match('local SUNSET_BUILD = "([^"]+)"')
assert(actualBuild == expectedBuild, "RIFT: wrong build received (expected " .. expectedBuild
    .. ", got " .. tostring(actualBuild) .. "). Nothing was loaded.")
local chunk, err = loadstring(source, "=RIFT " .. expectedBuild)
assert(chunk, "RIFT: current build did not compile: " .. tostring(err))
local environment = (typeof(getgenv) == "function" and getgenv()) or _G
environment.SunsetLoaderUrl = sourceUrl
print("[RIFT] Verified build " .. actualBuild)
chunk()
