-- INSERT_CURRENT_RELEASE
-- INSERT_UNIVERSAL_RELEASE
-- INSERT_IMPORTED_RELEASE
-- INSERT_BLOX_RELEASE
local suppliedSource, downloadFailure, compileFailure
local executions, requests, compilations = 0, 0, 0
local environment = {}
local game = { PlaceId = 6872265039 }
function game:HttpGet(url)
    requests += 1
    local imported = game.PlaceId == 286090429 or game.PlaceId == 17625359962 or game.GameId == 6035872082
        or game.PlaceId == 107535308163741
    local blox = game.PlaceId == 2753915549 or game.GameId == 994732206
    local expectedFile = blox and "blox%-fruits%.lua" or imported and "arsenal%-rivals%.lua" or "alua"
    assert(url:match("/[%da-f]+/" .. expectedFile .. "$") and not url:find("/main/"), "release URL is not pinned")
    if downloadFailure then error("offline") end
    return suppliedSource
end
local function getgenv() return environment end
local function print() end
local function warn() end
local function loadstring(source, name)
    compilations += 1
    assert(source == suppliedSource and name:find("RIFT", 1, true))
    if compileFailure then return nil, "compile failure" end
    return function() executions += 1 end
end
local function run()
    -- INSERT_LOADER_PRODUCTION
end
suppliedSource = releaseSource
run()
assert(executions == 1 and requests == 1 and compilations == 1)
assert(environment.SunsetRecovery == true, "loader restored saved modules by default")
local pinnedUrl = environment.SunsetLoaderUrl
assert(pinnedUrl and pinnedUrl:match("/[%da-f]+/alua$"), "reinject source was not pinned")
for _, badSource in ipairs({ releaseSource:gsub("k%d+", "k1"), "-- no build declaration" }) do
    suppliedSource = badSource
    local ok, err = pcall(run)
    assert(not ok and tostring(err):find("wrong build received"), "stale/unversioned source executed")
end
suppliedSource = releaseSource
downloadFailure = true
assert(not pcall(run), "failed download was accepted")
downloadFailure = false
compileFailure = true
assert(not pcall(run), "failed compilation was accepted")
assert(executions == 1 and environment.SunsetLoaderUrl == pinnedUrl, "failed load changed running release")
compileFailure = false
run()
assert(executions == 2, "loader did not recover after a failed request")
game.PlaceId = 999999999
suppliedSource = universalReleaseSource
local beforeRequests, beforeCompilations = requests, compilations
run()
assert(executions == 2 and requests == beforeRequests and compilations == beforeCompilations,
    "an unsupported game downloaded or started a client")
suppliedSource = releaseSource
assert(pcall(run), "unsupported games should stop cleanly")
for _, location in ipairs({{286090429,nil},{17625359962,nil},{999999,6035872082},{107535308163741,nil}}) do
    game.PlaceId,game.GameId=location[1],location[2]
    suppliedSource=importedReleaseSource
    local before=executions
    run()
    assert(executions==before+1 and environment.SunsetLoaderUrl:match("/arsenal%-rivals%.lua$"),
        "Arsenal/Rivals did not route to the supplied client")
    suppliedSource=releaseSource
    assert(not pcall(run),"dedicated source accepted for imported game")
end
for _, place in ipairs({13687899540,7336302630}) do
    game.PlaceId,game.GameId=place,nil
    suppliedSource=releaseSource
    local before=executions
    run()
    assert(executions==before+1 and environment.SunsetLoaderUrl:match("/alua$"),"existing game route changed")
end
for _, location in ipairs({{2753915549, nil}, {999999, 994732206}}) do
    game.PlaceId,game.GameId=location[1],location[2]
    suppliedSource=bloxReleaseSource
    local before=executions
    run()
    assert(executions==before+1 and environment.SunsetLoaderUrl:match("/blox%-fruits%.lua$"), "Blox Fruits route missing")
    suppliedSource=importedReleaseSource
    assert(not pcall(run), "other client accepted for Blox Fruits")
end
