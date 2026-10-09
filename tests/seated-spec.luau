local Settings = { SelectedGame = "Cold War" }
local ENV = {}
local now = 10
local os = { clock = function() return now end }
local attrs = {}
local hum = { Health = 100, Sit = true, SeatPart = {}, PlatformStand = false }
local LocalPlayer = { Character = { FindFirstChildOfClass = function() return hum end },
    GetAttribute = function(_, name) return attrs[name] end }
local conscious = true
local wielder = { isConscious = function() return conscious end }
local function nativeGate() return not hum.Sit and not hum.PlatformStand end
local equipGate = nativeGate
local seatEvents = 0
local function onSeatState() seatEvents += 1 return "native event" end
local calls, blocked = 0, true
local equipped, equipCalls = nil, 0
local rifle = { Parent = {}, GetAttribute = function() return "Weapon" end }
local function nativeSeat(on)
    calls += 1 blocked = on
    if on then equipped = nil end
    return "native seat", nil, 3
end
local inventory = { new = function() end, equip = function(tool)
    equipCalls += 1
    if equipGate() then equipped = tool end
end, setSeated = nativeSeat,
    getEquipped = function() return equipped end, getTools = function() return {rifle} end }
local gateValues = { false, 0, false, true, false, false, wielder, hum, LocalPlayer }
local upvalues = { [inventory.equip] = { [3] = nativeGate },
    [inventory.new] = { [28] = onSeatState }, [nativeGate] = gateValues,
    [onSeatState] = { hum } }
local debug = { getupvalues = function(fn) return upvalues[fn] or {} end }
local replacements, hookCount = {}, 0
local function hookfunction(fn, replacement)
    replacements[fn] = replacement
    if fn == nativeGate then equipGate = replacement end
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
local tasks = {}
local task = { spawn = function(fn) table.insert(tasks, fn) end }
local function finishTasks()
    local pending = tasks tasks = {}
    for _, fn in ipairs(pending) do fn() end
end
local connections = {}
local function track(c) table.insert(connections, c) end
local RunService = { RenderStepped = { Connect = function() return { Disconnect = function() end } end } }
local AimTab = { Left = {} }
local function gameSection(_, _, name) return name end
local toggle
local Elements = { Toggle = function(_, _, _, callback) toggle = callback end }
-- INSERT_SEATED_PRODUCTION
Settings.SetupColdWarSeated()
local feature = Settings.ColdWarSeated
feature.Update()
assert(requires == 0 and inventory.setSeated == nativeSeat)
toggle(true)
assert(requires == 0, "uninitialized module was required")
loaded, now = true, 12
feature.Update()
assert(feature.Available and hookCount == 2 and identity == 8 and not blocked)
assert(equipped == nil and #tasks == 1, "equip was not deferred")
finishTasks()
assert(equipped == rifle and equipCalls == 1, "already holstered seated weapon was not equipped")
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
equipped, hum.SeatPart = nil, {}
feature.Update()
assert(#tasks == 1)
feature.Restore()
finishTasks()
assert(equipped == nil and equipCalls == 1, "unload allowed a pending seated equip")
assert(blocked and not gate() and inventory.setSeated == nativeSeat)
Settings.SetupColdWarSeated()
toggle(true)
feature = Settings.ColdWarSeated
feature.Update()
assert(hookCount == 2 and feature.Available and gate(), "reinjection stacked hooks")
feature.Restore()
assert(not gate() and inventory.setSeated == nativeSeat)
print("PASS seated firing: loaded modules only, input/holster/equip seat gates, cooldown/consciousness/swim/carry/revive/platform checks, disable/game switch/reinjection/unload")
