local Settings = { SelectedGame = "Cold War" }
local notices = {}
Settings.Notify = function(title, message, kind) table.insert(notices, {title, message, kind}) end
local ENV = {}
local now = 10
local os = { clock = function() return now end }
local attrs = {}
local hum = { Health = 100, Sit = true, SeatPart = {}, PlatformStand = false }
local LocalPlayer = { Character = { FindFirstChildOfClass = function() return hum end },
    GetAttribute = function(_, name) return attrs[name] end }
local root = {}
LocalPlayer.Character.FindFirstChild = function(_, name) if name == "HumanoidRootPart" then return root end end
local occupant = { Value = LocalPlayer.Character, IsA = function(_, class) return class == "ObjectValue" end }
local motor = { Part1 = root, IsA = function(_, class) return class == "Motor6D" end }
local customSeat = { Parent = {}, FindFirstChild = function(_, name)
    if name == "Occupant" then return occupant elseif name == "Motor6D" then return motor end
end }
local tagged, scans = {}, 0
local CollectionService = { GetTagged = function(_, tag)
    assert(tag == "FactoryVehicleSeat") scans += 1 return tagged
end }
local conscious = true
local wielder = { isConscious = function() return conscious end }
local function nativeGate() return not hum.Sit and not hum.PlatformStand end
local seatEvents = 0
local function onSeatState() seatEvents += 1 return "native event" end
local calls, blocked = 0, true
local function nativeSeat(on) calls += 1 blocked = on return "native seat", nil, 3 end
local inventory = { new = function() end, equip = function() end, setSeated = nativeSeat }
local gateValues = { false, 0, false, true, false, false, wielder, hum, LocalPlayer }
local upvalues = { [inventory.equip] = { [3] = nativeGate },
    [inventory.new] = { [28] = onSeatState }, [nativeGate] = gateValues,
    [onSeatState] = { hum } }
local debug = { getupvalues = function(fn) return upvalues[fn] or {} end }
local replacements, hookCount = {}, 0
local function hookfunction(fn, replacement)
    replacements[fn] = replacement
    hookCount += 1
    return fn
end
local module = {}
local character = { FindFirstChild = function(_, name) if name == "InventoryController" then return module end end }
local client = { FindFirstChild = function(_, name) if name == "Character" then return character end end }
local storage = { FindFirstChild = function(_, name) if name == "Client" then return client end end }
local game = { GetService = function() return storage end }
local loaded, requires, identity = false, 0, 8
local function rivalsModuleLoaded() return loaded end
local function getthreadidentity() return identity end
local function setthreadidentity(value) identity = value end
local function require(m) assert(m == module and identity == 2) requires += 1 return inventory end
local function warn() end
local connections = {}
local function track(c) table.insert(connections, c) end
local RunService = { RenderStepped = { Connect = function() return { Disconnect = function() end } end } }
local AimTab = { Left = {} }
local function gameSection(_, _, name) return name end
local inputHandler
local UIS = { InputBegan = {Connect=function(_, fn)
    inputHandler = fn return {Disconnect=function() end}
end}, GetFocusedTextBox=function() return nil end }
local task = { defer=function(fn) fn() end }
local toggle, checkButton
local Elements = { Toggle = function(_, _, _, callback) toggle = callback end,
    Button = function(_, name, callback) assert(name == "Check Seated") checkButton = callback end }
-- INSERT_SEATED_PRODUCTION
Settings.SetupColdWarSeated()
local feature = Settings.ColdWarSeated
feature.Update()
assert(requires == 0 and inventory.setSeated == nativeSeat)
toggle(true)
assert(requires == 0, "uninitialized module was required")
assert(string.find(checkButton(), "waiting for initialized InventoryController", 1, true))
loaded, now = true, 12
feature.Update()
assert(feature.Available and hookCount == 2 and identity == 8 and not blocked)
local gate, seat = replacements[nativeGate], replacements[onSeatState]
assert(gate(), "seated equip stayed blocked")
local result = table.pack(inventory.setSeated(true))
assert(not blocked and result.n == 3 and result[1] == "native seat" and result[3] == 3)
seat()
assert(seatEvents == 0, "seated event holstered the weapon")
for _, index in ipairs({ 1, 3, 5, 6 }) do
    gateValues[index] = true
    assert(not gate(), "non-seat action guard was removed")
    gateValues[index] = false
end
gateValues[2] = now
assert(not gate(), "switch cooldown was removed")
gateValues[2] = 0
conscious = false
assert(not gate(), "unconscious equip was allowed")
conscious = true
attrs.Reviving = true
assert(not gate(), "reviving guard was removed")
attrs.Reviving = nil
hum.PlatformStand = true
assert(not gate())
assert(seat() == "native event" and seatEvents == 1, "platform stand event was suppressed")
hum.PlatformStand = false
Settings.SelectedGame = "Rivals"
assert(not gate())
inventory.setSeated(true)
assert(blocked, "seat override crossed game boundary")
Settings.SelectedGame = "Cold War"
toggle(false)
assert(blocked and inventory.setSeated == nativeSeat and not gate())
toggle(true)
now += 2
feature.Update()
assert(gate() and not blocked and hookCount == 2, "re-enable stacked seat hooks")
feature.Restore()
assert(blocked and not gate() and inventory.setSeated == nativeSeat)
Settings.SetupColdWarSeated()
toggle(true)
feature = Settings.ColdWarSeated
feature.Update()
assert(hookCount == 2 and feature.Available and gate(), "reinjection stacked hooks")
-- Factory seats do not require Humanoid.Sit or SeatPart.
hum.Sit, hum.SeatPart = false, nil
tagged = { customSeat }
now += 1
assert(gate(), "custom occupied seat did not allow equip")
local status = checkButton()
assert(string.find(status, "seat=true", 1, true) and string.find(status, "hooks=true", 1, true))
assert(string.find(status, "gateHumanoid=true", 1, true))
assert(#notices > 0 and notices[#notices][1] == "Shoot While Seated")
local noticeBaseline = #notices
inputHandler({KeyCode={Name="One"}})
assert(#notices==noticeBaseline+1, "weapon key did not show seated status")
inputHandler({KeyCode={Name="One"}})
assert(#notices==noticeBaseline+1, "weapon key spam flooded notifications")

local customResult = table.pack(inventory.setSeated(true))
assert(not blocked and customResult.n == 3)
local eventCount = seatEvents
seat()
assert(seatEvents == eventCount, "custom seat event unequipped weapon")
local scanBaseline = scans
for _ = 1, 600 do assert(gate()) end
assert(scans == scanBaseline, "valid cached seat repeatedly scanned tags")
hum.PlatformStand = true
assert(not gate(), "custom seat bypassed platform guard")
hum.PlatformStand = false
occupant.Value = {}
assert(gate() == nativeGate(), "another player's seat counted as occupied")
now += 1
occupant.Value = LocalPlayer.Character
motor.Part1 = {}
assert(gate() == nativeGate(), "seat without character attachment counted as occupied")
now += 1
motor.Part1 = root
assert(gate())
feature.Restore()
assert(blocked, "disable did not restore custom seated inventory lock")
assert(gate() == nativeGate() and inventory.setSeated == nativeSeat)
print("PASS seated firing: loaded modules only, input/holster/equip seat gates, cooldown/consciousness/swim/carry/revive/platform checks, disable/game switch/reinjection/unload")
