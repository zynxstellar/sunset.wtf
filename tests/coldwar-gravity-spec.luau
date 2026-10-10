local Vector3 = { new = function(x,y,z) return {X=x,Y=y,Z=z} end }
local Enum = { ActuatorRelativeTo = { World = "World" } }
local workspace = { Gravity = 196.2 }
local humanoid = { Health = 100 }
local root = { AssemblyMass = 10 }
local character = {
    FindFirstChild = function() return root end,
    FindFirstChildOfClass = function() return humanoid end,
}
local LocalPlayer = { Character = character }
local Settings = { SelectedGame = "Cold War" }
local created, connections, controls = {}, {}, {}
local function new(class, properties, parent)
    properties.ClassName, properties.Parent = class, parent
    function properties:Destroy() self.Parent = nil self.Destroyed = true end
    table.insert(created, properties)
    return properties
end
local function track(connection) table.insert(connections, connection) end
local RunService = { PreSimulation = { Connect = function() return {Disconnect=function() end} end } }
local MainTab = { Right = {} }
local function gameSection() return {} end
local Elements = {}
function Elements.Toggle(_, name, _, callback) controls[name] = callback end
function Elements.Slider(_, name, _, _, _, _, callback) controls[name] = callback end
-- INSERT_COLDWAR_GRAVITY
Settings.SetupColdWarGravity()
local gravity = Settings.ColdWarGravity
gravity.Step() assert(#created == 0, "disabled module allocated forces")
controls.Gravity(true) gravity.Step()
assert(#created == 2 and created[2].Force.Y == (196.2 - 90) * 10)
assert(created[2].ApplyAtCenterOfMass and created[2].RelativeTo == "World")
controls.Strength(250) root.AssemblyMass = 20 gravity.Step()
assert(#created == 2 and created[2].Force.Y == (196.2 - 250) * 20)
workspace.Gravity = 100 gravity.Step()
assert(created[2].Force.Y == -3000, "world gravity changes were ignored")
humanoid.Sit = true gravity.Step()
assert(created[1].Destroyed and created[2].Destroyed, "seating left force attached")
humanoid.Sit = false gravity.Step()
root = { AssemblyMass = 5 } gravity.Step()
assert(created[3].Destroyed and created[4].Destroyed and #created == 6, "respawn retained old force")
humanoid.Health = 0 gravity.Step()
assert(created[5].Destroyed and created[6].Destroyed, "death retained force")
humanoid.Health = 100 gravity.Step()
controls.Gravity(false)
assert(created[7].Destroyed and created[8].Destroyed, "disable retained force")
controls.Gravity(true) gravity.Step()
for _, connection in ipairs(connections) do connection:Disconnect() end
controls.Gravity(true) gravity.Step()
assert(gravity.Destroyed and not gravity.Enabled and #created == 10 and created[10].Destroyed)
assert(workspace.Gravity == 100, "module changed global gravity")
print("PASS Cold War Gravity: strength, mass/world updates, respawn, seating, death, disable and unload cleanup")
