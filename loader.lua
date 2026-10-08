-- Update both release values together when publishing a new client build.
local dedicated = game.PlaceId == 6872265039 or game.GameId == 2619619496
    or game.PlaceId == 17625359962 or game.GameId == 6035872082
    or game.PlaceId == 13687899540 or game.GameId == 4750561026
    or game.PlaceId == 7336302630 or game.GameId == 2862098693
local expectedBuild = dedicated
    and "20261007-rift-project-delta-spin-view-k301"
    or "20261008-rift-universal-hands-k271"
local sourceUrl = dedicated
    and "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/f156d8bca8694e43bb3e4f3095a225a63d015311/alua"
    or "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/a7b2dae40f25861e8219d15efafcf2f061bab86a/universal.lua"

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
