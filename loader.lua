-- Game support includes: Arsenal, BedWars, Rivals, Cold War, Project Delta, and Huss Valley (shared features).
-- Executor support includes: Potassium, Synapse Z, and Volt. Other executors are labeled NOT TESTED.
-- Contact z.y.n.x. on Discord for help, assistance, or suggestions.
-- You can also join the Discord at: https://discord.gg/4pj9cedscb

-- Route Arsenal and Rivals to the supplied client; retain the other dedicated clients.
local imported = game.PlaceId == 286090429 or game.PlaceId == 17625359962 or game.GameId == 6035872082
    or game.PlaceId == 107535308163741
local blox = game.PlaceId == 2753915549 or game.GameId == 994732206
local dedicated = game.PlaceId == 6872265039 or game.GameId == 2619619496
    or game.PlaceId == 13687899540 or game.GameId == 4750561026
    or game.PlaceId == 7336302630 or game.GameId == 2862098693
if not imported and not dedicated and not blox then
    warn("[RIFT] This game is unsupported. No client was downloaded or started.")
    return
end
local expectedBuild = blox and "20261011-rift-blox-movement-k376" or (imported and "20261011-rift-huss-speed-limit-k372" or "20261011-rift-car-fall-platform-k375")
local sourceUrl = blox and "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/40f8de3e97f369711db3c52ecf2aff68b06cffcf/blox-fruits.lua" or imported
    and "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/1268640d350078276fdd56bb49e05b928ef7ea27/arsenal-rivals.lua"
    or "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/42f3ec5279ad53bd6ed9391b71f96696aa3f5abf/alua"

local ok, source = pcall(game.HttpGet, game, sourceUrl)
assert(ok and type(source) == "string", "RIFT: current build download failed: " .. tostring(source))
local actualBuild = source:match('local SUNSET_BUILD = "([^"]+)"')
assert(actualBuild == expectedBuild, "RIFT: wrong build received (expected " .. expectedBuild
    .. ", got " .. tostring(actualBuild) .. "). Nothing was loaded.")
local chunk, err = loadstring(source, "=RIFT " .. expectedBuild)
assert(chunk, "RIFT: current build did not compile: " .. tostring(err))
local environment = (typeof(getgenv) == "function" and getgenv()) or _G
-- Start with saved gameplay modules paused unless explicitly overridden.
if environment.SunsetRecovery == nil then environment.SunsetRecovery = true end
environment.SunsetLoaderUrl = sourceUrl
print("[RIFT] Verified build " .. actualBuild)
chunk()
