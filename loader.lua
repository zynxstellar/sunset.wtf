-- Update both release values together when publishing a new client build.
local dedicated = game.PlaceId == 6872265039 or game.GameId == 2619619496
    or game.PlaceId == 17625359962 or game.GameId == 6035872082
    or game.PlaceId == 13687899540 or game.GameId == 4750561026
    or game.PlaceId == 7336302630 or game.GameId == 2862098693
local expectedBuild = dedicated
    and "20261008-rift-coldwar-visuals-k304"
    or "20261008-rift-universal-esp-k272"
local sourceUrl = dedicated
    and "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/41e728545804dfdbdccf71a0eeaa522e4e6859b6/alua"
    or "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/20f996d10b33d06ab6a671921daebc06ce24fe16/universal.lua"

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
