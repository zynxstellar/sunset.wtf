local ENV = {}
local environment = ENV
ENV.SunsetCheckpoint = function() end
local BedWars = {Running = true}
local destroyed, disconnected = 0, 0
local function destroyable()
    return {Destroy = function() destroyed += 1 end}
end
local Settings = {MenuBlurEffect = destroyable()}
local Gui = destroyable()
Settings.RootGui = Gui
ENV.SunsetLoading = {Gui = destroyable()}
local Connections = {
    {Disconnect = function() error("already gone") end},
    {Disconnect = function() disconnected += 1 end},
}
-- INSERT_STARTUP_ABORT
local source = "test"
local startup = function() error("intentional startup failure") end
local loadstring = function() return startup end
local function run()
    -- INSERT_WRAPPER_HANDOFF
end
local ok, message = pcall(run)
assert(not ok and tostring(message):find("intentional startup failure", 1, true))
assert(not BedWars.Running and #Connections == 0 and disconnected == 1)
assert(destroyed == 3 and ENV.SunsetLoading == nil and ENV.SunsetAbortStartup == nil)
startup = function() end
assert(pcall(run), "successful startup was rejected")
assert(destroyed == 3, "successful startup ran failure cleanup")
print("PASS startup failure: original error reported; loops, connections, loading UI and blur cleaned up")

-- Match the production HUD helper's function boundary. The menu callback is
-- outside this boundary, which made the previous local getter resolve to nil.
local BedWars = {KillChatQueue = {}}
local LocalPlayer = {UserId = 42}
local function defineHUD()
    local sessionStore = {getState = function() return {Bedwars = {kills = {["42"] = 7}}} end}
    -- INSERT_KILL_GETTER
end
defineHUD()
local Elements = {Toggle = function(_, _, _, callback) callback(true) end}
local chatSection = {}
-- INSERT_KILL_TOGGLE
assert(BedWars.KillChatOn and BedWars.KillChatLastCount == 7)
print("PASS BedWars startup: real Kill Chat callback reaches getter outside HUD function scope")
