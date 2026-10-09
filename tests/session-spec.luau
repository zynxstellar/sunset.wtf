local function signal()
    local handlers = {}
    return { Connect = function(_, fn)
        local entry = { Active = true, Fn = fn }
        table.insert(handlers, entry)
        return { Disconnect = function() entry.Active = false end }
    end, Fire = function(_, ...)
        for _, entry in ipairs(handlers) do if entry.Active then entry.Fn(...) end end
    end }
end
local clock = 0
local os = { clock = function() return clock end }
local game = { JobId = "one" }
local attrs, folders = {}, {}
local LocalPlayer = { GetAttribute = function(_, name) return attrs[name] end,
    FindFirstChild = function(_, name) return folders[name] end }
local Settings = { SelectedGame = "Cold War" }
local connections = {}
local function track(connection) table.insert(connections, connection) return connection end
local function unload()
    for _, connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
end
local function character()
    local humanoid = { Health = 100, Died = signal() }
    return { FindFirstChildOfClass = function() return humanoid end }, humanoid
end
local function session() return { Seconds = 0, Kills = 0, Deaths = 0, Observed = {} } end
-- INSERT_SESSION_TRACKER
attrs.Kills, attrs.Deaths = 40, 20
local current, human = character()
LocalPlayer.Character = current
local stats = session()
local step = Settings.NewSessionTracker(stats, "Cold War", true)
assert(stats.Kills == 0 and stats.Deaths == 0, "included pre-injection stats")
clock = 61
attrs.Kills = 42
step()
assert(stats.Seconds == 61 and stats.Kills == 2)
human.Died:Fire()
assert(stats.Deaths == 0, "event counted before replicated death source")
attrs.Deaths = 21
step()
human.Died:Fire()
step()
assert(stats.Deaths == 1, "double counted native death and stat delta")
attrs.Kills = 0
step()
attrs.Kills = 1
step()
assert(stats.Kills == 3, "round reset lost subsequent kill")
attrs.Kills = 80
game.JobId = "two"
step()
assert(stats.Kills == 3, "server change added existing stats")
unload()
clock = 90
attrs.Kills = 90
step()
assert(stats.Seconds == 61 and stats.Kills == 3, "unload left tracker running")
local fresh = session()
local freshStep = Settings.NewSessionTracker(fresh, "Cold War", true)
assert(fresh.Kills == 0 and fresh.Deaths == 0 and fresh.Seconds == 0, "reinjection carried session")
unload()
attrs = {}
LocalPlayer.Character = nil
local bedwars = session()
local deathsStep = Settings.NewSessionTracker(bedwars, "BedWars", false)
LocalPlayer.Character, human = character()
deathsStep()
human.Died:Fire()
human.Died:Fire()
assert(bedwars.Deaths == 1 and bedwars.Seconds == 0 and bedwars.Observed.Deaths,
    "local death fallback duplicated or replaced BedWars time")
LocalPlayer.Character = nil
deathsStep()
human.Died:Fire()
assert(bedwars.Deaths == 1, "removed character kept counting deaths")
unload()

local objects = {}
local function new(_, props, parent)
    local object = table.clone(props or {})
    object.Parent = parent
    function object:Destroy() self.Destroyed = true self.Visible = false end
    table.insert(objects, object)
    return object
end
local function label(parent, text) return new("TextLabel", { Text = text }, parent) end
local function border() end
local function makeDraggable(panel) panel.Draggable = true end
local T = {}
local UDim = { new = function(...) return {...} end }
local UDim2 = { new = function(...) return {...} end, fromOffset = function(...) return {...} end }
local Enum = { Font = { GothamBold = "bold", GothamMedium = "medium" } }
local Gui = {}
local Persistence = { HUDFrames = {} }
local RunService = { Heartbeat = signal() }
local VisualsTab = { Left = {} }
local function gameSection(_, _, title) return title end
local controls = {}
local Elements = { Toggle = function(section, name, _, callback) controls[section .. "/" .. name] = callback end }
-- INSERT_SESSION_HUD
Settings.SetupColdWarSession()
local hud = Persistence.HUDFrames.ColdWarSessionInfo
assert(hud and hud.Draggable and not hud.Visible)
controls["Session Info/Session Info"](true)
assert(hud.Visible)
local hasUnknownKills = false
for _, object in ipairs(objects) do if object.Text == "Kills: --" then hasUnknownKills = true end end
assert(hasUnknownKills, "unavailable kill source presented as confirmed stats")
clock = 152
RunService.Heartbeat:Fire(0.25)
assert(Settings.ColdWarSession.Seconds == 62, "HUD time failed while tracking")
controls["Session Info/Session Info"](false)
assert(not hud.Visible)
clock = 153
RunService.Heartbeat:Fire(0.25)
assert(Settings.ColdWarSession.Seconds == 63, "disabled HUD stopped session")
unload()
assert(hud.Destroyed)
Settings.SetupColdWarSession()
assert(Settings.ColdWarSession.Seconds == 0 and Settings.ColdWarSession.Kills == 0,
    "new HUD reused previous session")
unload()
print("PASS session HUD: fresh injection, stat baselines/deltas/reset, native death dedup, late character, playtime, visibility, drag, unload")

local BedWars = { Session = { Seconds = 0, Kills = 0, Deaths = 0, Games = 0,
    SourceValues = {}, Observed = {} } }
local sessionClock, sessionFields, kills = clock, {}, 8
local function sessionMap() return "Test map" end
local function currentBedWarsKills() return kills end
local function updateSessionDeaths() end
local function sessionNumber() end
-- INSERT_BEDWARS_SESSION_UPDATE
updateSession()
assert(BedWars.Session.Kills == 0, "BedWars counted kills from before injection")
kills = 9
updateSession()
assert(BedWars.Session.Kills == 1)
BedWars.Session = { Seconds = 0, Kills = 0, Deaths = 0, Games = 0,
    SourceValues = {}, Observed = {} }
updateSession()
assert(BedWars.Session.Kills == 0, "fresh BedWars session included earlier kills")
print("PASS BedWars session: existing kills excluded, new kills counted, reinjection baseline reset")
