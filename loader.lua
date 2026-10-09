-- Game support includes: BedWars (easy.gg; Full Support), Rivals, Cold War (Full Support).
-- Executor support includes: Potassium, Synapse Z, and Volt. Other executors are labeled NOT TESTED.
-- Contact z.y.n.x. on Discord for help, assistance, or suggestions.
-- You can also join the Discord at: https://discord.gg/4pj9cedscb

-- Update both release values together when publishing a new client build.
local dedicated = game.PlaceId == 6872265039 or game.GameId == 2619619496
    or game.PlaceId == 17625359962 or game.GameId == 6035872082
    or game.PlaceId == 13687899540 or game.GameId == 4750561026
    or game.PlaceId == 7336302630 or game.GameId == 2862098693
local expectedBuild = dedicated
    and "20261009-rift-startup-stability-k311"
    or "20261009-rift-universal-menu-stability-k275"
local sourceUrl = dedicated
    and "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/f64232e1af423c413313cfb59618286e1e536040/alua"
    or "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/f64232e1af423c413313cfb59618286e1e536040/universal.lua"

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
