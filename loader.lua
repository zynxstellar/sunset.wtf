-- Game support includes: Arsenal, BedWars (easy.gg; Full Support), Rivals, Cold War (Full Support).
-- Executor support includes: Potassium, Synapse Z, and Volt. Other executors are labeled NOT TESTED.
-- Contact z.y.n.x. on Discord for help, assistance, or suggestions.
-- You can also join the Discord at: https://discord.gg/4pj9cedscb

-- Route Arsenal and Rivals to the supplied client; retain the other dedicated clients.
local imported = game.PlaceId == 286090429 or game.PlaceId == 17625359962 or game.GameId == 6035872082
local dedicated = game.PlaceId == 6872265039 or game.GameId == 2619619496
    or game.PlaceId == 13687899540 or game.GameId == 4750561026
    or game.PlaceId == 7336302630 or game.GameId == 2862098693
if not imported and not dedicated then
    warn("[RIFT] This game is unsupported. No client was downloaded or started.")
    return
end
local expectedBuild = imported and "20261011-rift-imported-compact-ui-k366" or "20261011-rift-compact-ui-k366"
local sourceUrl = imported
    and "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/a1f6057f20c9290623f499a3d4e3b9e3d2a4c6cb/arsenal-rivals.lua"
    or "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/a1f6057f20c9290623f499a3d4e3b9e3d2a4c6cb/alua"

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
