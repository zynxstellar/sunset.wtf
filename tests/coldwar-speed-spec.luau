local function object(name, parent)
    local value = { Name = name, Children = {}, Parent = parent }
    if parent then parent.Children[name] = value end
    function value:FindFirstChild(child) return self.Children[child] end
    return value
end
local Settings = { SelectedGame = "Cold War" }
local ENV = {}
local LocalPlayer = {}
local AimTab = { Left = {} }
local controls = {}
local function gameSection(_, _, name) return name end
local Elements = {}
function Elements.Toggle(section, name, initial, callback)
    local control = { Value = initial }
    function control:Set(value) self.Value = value callback(value) end
    controls[section .. "/" .. name] = control
    return control
end
function Elements.Slider(section, name, minimum, maximum, initial, unit, callback)
    return Elements.Toggle(section, name, initial, callback)
end
local callbacks = {}
local RunService = { RenderStepped = {} }
function RunService.RenderStepped:Connect(callback)
    table.insert(callbacks, callback)
    return { Disconnect = function() end }
end
local cleanup = {}
local function track(connection) table.insert(cleanup, connection) end
local task = { spawn = function(callback) callback() end }
local now = 10
local os = { clock = function() return now end }
local warnings = {}
local function warn(message) table.insert(warnings, message) end
local identity = 8
local function getthreadidentity() return identity end
local function setthreadidentity(value) identity = value end
local storage = object("ReplicatedStorage")
local shared = object("Shared", storage)
local ballistics = object("Ballistics", shared)
local sources = object("Sources", ballistics)
local module = object("WeaponSource", sources)
local nativeProfile = { MuzzleSpeed = 100, Damage = 20 }
local native = function(request)
    return { Weapon = nativeProfile, Seed = request.Seed }
end
local source = { toFireParams = native }
local loaded = false
local requireCalls = 0
local function rivalsModuleLoaded() return loaded end
local function require(request)
    assert(request == module and identity == 2)
    requireCalls += 1
    return source
end
local game = { GetService = function(_, name)
    assert(name == "ReplicatedStorage")
    return storage
end }
-- INSERT_COLDWAR_SPEED_PRODUCTION
Settings.SetupColdWarBulletSpeed()
local speed = Settings.ColdWarBulletSpeed
local toggle = controls["Bullet Speed/Bullet Speed"]
local slider = controls["Bullet Speed/Speed Multiplier"]
assert(toggle and slider and not speed.Enabled and source.toFireParams == native)
toggle:Set(true)
assert(not speed.Available and requireCalls == 0, "unloaded module was required")
loaded = true
now = 11
callbacks[1]()
assert(speed.Available and source.toFireParams ~= native and identity == 8)
local normal = source.toFireParams({ Owner = LocalPlayer, Seed = nil })
local other = source.toFireParams({ Owner = {}, Seed = 1 })
assert(normal.Weapon == nativeProfile and other.Weapon == nativeProfile)
local shot = source.toFireParams({ Owner = LocalPlayer, Seed = 2 })
assert(shot.Weapon ~= nativeProfile and shot.Weapon.MuzzleSpeed == 200
    and shot.Weapon.Damage == 20 and nativeProfile.MuzzleSpeed == 100)
slider:Set(10)
assert(source.toFireParams({ Owner = LocalPlayer, Seed = 3 }).Weapon.MuzzleSpeed == 1000)
Settings.SelectedGame = "Rivals"
assert(source.toFireParams({ Owner = LocalPlayer, Seed = 4 }).Weapon == nativeProfile)
Settings.SelectedGame = "Cold War"
toggle:Set(false)
assert(source.toFireParams == native and not speed.Available)
now = 12
toggle:Set(true)
assert(speed.Available and source.toFireParams ~= native)
Settings.SetupColdWarBulletSpeed()
assert(source.toFireParams == native and not speed.Enabled, "reinjection stacked hooks")
local replacement = Settings.ColdWarBulletSpeed
controls["Bullet Speed/Bullet Speed"]:Set(true)
assert(source.toFireParams ~= native)
replacement.Restore()
assert(source.toFireParams == native, "unload left bullet-speed hook")
print("PASS Cold War Bullet Speed: deferred module, local seeded shots only, scaled copy, game switch, disable, reinject, unload")
