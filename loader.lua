-- Update both release values together when publishing a new client build.
local expectedBuild = "20261007-rift-coldwar-aim-fov-k294"
local sourceUrl = "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/8b7534d9cb33066c55dc28f8a3c23ac43b424837/alua"

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
