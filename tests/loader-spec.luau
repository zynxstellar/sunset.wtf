-- INSERT_CURRENT_RELEASE
-- INSERT_RIVALS_RELEASE
local suppliedSource, downloadFailure, compileFailure
local executions, requests, compilations = 0, 0, 0
local environment = {}
local game = {}
function game:HttpGet(url)
    requests += 1
    local expectedFile = game.PlaceId == 17625359962 and "rivals%.lua" or "alua"
    assert(url:match("/[%da-f]+/" .. expectedFile .. "$") and not url:find("/main/"), "release URL is not pinned")
    if downloadFailure then error("offline") end
    return suppliedSource
end
local function getgenv() return environment end
local function print() end
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
game.PlaceId = 17625359962
suppliedSource = rivalsReleaseSource
run()
assert(executions == 3 and environment.SunsetLoaderUrl:match("/[%da-f]+/rivals%.lua$"),
    "Rivals did not load its pinned source")
suppliedSource = releaseSource
assert(not pcall(run), "Rivals accepted the non-Rivals build")
