-- Use production creation/hosting functions to exercise all Cold War GUI roots.
local Settings = {IsColdWar = true}
local ENV = {}
local PlayerGui = {_type = "Instance", Name = "PlayerGui"}
local hiddenRoot = {_type = "Instance", Name = "HiddenUI"}
local coreRoot = {_type = "Instance", Name = "CoreGui"}
local hiddenCalls, coreCalls = 0, 0
local gethui
local game = {GetService = function(_, name)
    assert(name == "CoreGui")
    coreCalls += 1
    if coreRoot.Denied then error("CoreGui access denied") end
    return coreRoot
end}
local function typeof(value)
    return type(value) == "table" and value._type or type(value)
end
local connections, instances = {}, {}
local function track(connection) table.insert(connections, connection) return connection end
local Instance = {new = function(class)
    local parent, destroyed
    local object = {ClassName = class, Destroy = function() destroyed, parent = true, nil end}
    setmetatable(object, {
        __index = function(_, key)
            if key == "Parent" then return parent end
            if key == "Destroyed" then return destroyed end
        end,
        __newindex = function(self, key, value)
            if key == "Parent" then
                if value and value.RejectParent then error("Parent write rejected") end
                parent = value
            else rawset(self, key, value) end
        end,
    })
    table.insert(instances, object)
    return object
end}
-- INSERT_UI_HOST_PRODUCTION

ENV.gethui = function() hiddenCalls += 1 return hiddenRoot end
for _, name in ipairs({"MenuUI", "RiftLoading", "EspGui", "RiftColdWarESP"}) do
    local gui = new("ScreenGui", {Name = name, ResetOnSpawn = false}, PlayerGui)
    assert(gui.Parent == hiddenRoot and gui.Name == name and gui.ResetOnSpawn == false)
end
assert(hiddenCalls == 1 and coreCalls == 0, "preferred UI host was not reused")
assert(#connections == 4, "GUI roots lack unload cleanup")
local child = new("Frame", {Name = "MenuChild"}, instances[1])
assert(child.Parent == instances[1] and #connections == 4, "child was reparented or separately tracked")
for _, connection in ipairs(connections) do connection:Disconnect() end
for index = 1, 4 do assert(instances[index].Destroyed and not instances[index].Parent) end

-- A dead/inaccessible cached host is retried through the available containers.
Settings.ColdWarUIParent = {_type = "Instance", RejectParent = true}
hiddenRoot.RejectParent = true
local coreGui = new("ScreenGui", {Name = "MenuUI"}, PlayerGui)
assert(coreGui.Parent == coreRoot and coreCalls == 1)
hiddenRoot.RejectParent = false
Settings.ColdWarUIParent = nil
ENV.gethui = nil
gethui = function() return hiddenRoot end
assert(new("ScreenGui", {}, PlayerGui).Parent == hiddenRoot, "executor global gethui was ignored")

-- Missing, invalid and throwing gethui values fall back to CoreGui.
for _, getter in ipairs({function() end, function() return {} end, function() error("unavailable") end}) do
    Settings.ColdWarUIParent = nil
    ENV.gethui = getter
    assert(new("ScreenGui", {}, PlayerGui).Parent == coreRoot)
end

-- Failure is explicit and never silently puts Cold War's UI in PlayerGui.
Settings.ColdWarUIParent = nil
ENV.gethui = function() return nil end
coreRoot.Denied = true
local ok, err = pcall(new, "ScreenGui", {Name = "MenuUI"}, PlayerGui)
assert(not ok and tostring(err):find("accessible gethui() or CoreGui", 1, true))
assert(instances[#instances].Destroyed and not instances[#instances].Parent)

-- BedWars and Rivals retain their original parent without asking for gethui/CoreGui.
local previousHidden, previousCore, previousConnections = hiddenCalls, coreCalls, #connections
Settings.IsColdWar = false
for _, gameName in ipairs({"BedWars", "Rivals"}) do
    Settings.SelectedGame = gameName
    assert(new("ScreenGui", {Name = "MenuUI"}, PlayerGui).Parent == PlayerGui)
end
assert(hiddenCalls == previousHidden and coreCalls == previousCore and #connections == previousConnections)
print("PASS UI hosting: Cold War roots use gethui/CoreGui, children/layout preserved, unload cleanup, denied/missing APIs handled, other games keep PlayerGui")
