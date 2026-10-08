-- Update both release values together when publishing a new client build.
local arsenal = game.PlaceId == 286090429
local expectedBuild = arsenal
    and "20261008-rift-arsenal-hands-k270"
    or "20261007-rift-project-delta-spin-view-k301"
local sourceUrl = arsenal
    and "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/573250fd9cdae2a3201b2870519498084e3b097f/arsenal.lua"
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
