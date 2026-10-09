local objects, workers = {}, {}
local function new(_, properties, parent)
    local object = table.clone(properties or {})
    object.Parent = parent
    table.insert(objects, object)
    return object
end
local function label(parent, text) return new("TextLabel", {Text = text}, parent) end
local function border() end
local function makeDraggable(panel) panel.Draggable = true end
local task = {spawn = function(fn) table.insert(workers, fn) end}
local UDim = {new = function(...) return {...} end}
local UDim2 = {new = function(...) return {...} end, fromOffset = function(...) return {...} end,
    fromScale = function(...) return {...} end}
local Vector2 = {new = function(...) return {...} end}
local Enum = {ScaleType = {Crop = "crop"}, TextXAlignment = {Center = "center", Right = "right"},
    Font = {GothamBold = "bold", GothamSemibold = "semibold"}, TextTruncate = {AtEnd = "end"}}
local T = {}
local Gui = {Parent = true}
local Settings = {SelectedGame = "Cold War"}
local BedWars = {MusicCoverFiles = {}}
local RivalsVisuals = {}
local Persistence = {HUDFrames = {}}
local data = {available = true, title = "Track", artist = "Artist", position = 45, duration = 180}
local requests = 0
local ENV = {request = function(request)
    requests += 1
    assert(request.Url:find("127.0.0.1:47821/now-playing", 1, true))
    return {StatusCode = 200, Body = "mock"}
end}
local HttpService = {JSONDecode = function() return data end}
-- INSERT_MUSIC_HUD
Settings.SetupMusicHUD()
local panel = BedWars.SpotifyPanel
assert(panel and panel.Draggable and not panel.Visible, "Cold War music panel did not initialize")
assert(requests == 0 and #workers == 1, "music setup made an immediate network request")
Settings.SetupMusicHUD()
assert(BedWars.SpotifyPanel == panel and #workers == 1, "music setup duplicated the polling worker")
Settings.ColdWarMusicOn = true
assert(BedWars.MusicOverlayVisible())
Settings.SelectedGame = "BedWars"
assert(not BedWars.MusicOverlayVisible(), "Cold War toggle leaked into BedWars")
Settings.SelectedGame = "Cold War"
BedWars.SpotifyStep()
assert(BedWars.SpotifyTitle.Text == "Track - Artist")
local progressFound = false
for _, object in ipairs(objects) do if object.Text == "0:45 / 3:00" then progressFound = true end end
assert(progressFound, "music playback progress missing")
ENV.request = function() return {StatusCode = 503} end
BedWars.SpotifyStep()
assert(BedWars.SpotifyTitle.Text == "Start the music bridge")
Gui.Parent = nil
assert(not BedWars.MusicOverlayVisible(), "unloaded music HUD stayed enabled")
print("PASS music HUD: Cold War setup, one worker, deferred network, game isolation, track/progress, missing bridge, unload")
