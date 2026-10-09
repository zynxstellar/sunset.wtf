local Settings = { SelectedGame = "Cold War" }
local ENV = {}
local now = 0
local os = { clock = function() return now end }
local CFrame = { identity = { Kind = "CFrame", Identity = true } }
local function typeof(value) return type(value) == "table" and value.Kind or type(value) end
local shifted, tilted, shaking = {Kind="CFrame"}, {Kind="CFrame"}, {Kind="CFrame"}
local swayValues, shakeValues = {}, {}
local function sway(dt)
    swayValues[9], swayValues[10] = shifted, tilted
    return "sway", nil, dt
end
local function shake() shakeValues[4] = shaking return "shake" end
local function update() end
local viewmodel = { attach = function() end }
local frame
local RunService = { RenderStepped = { Connect = function(_, fn)
    frame = fn return { Disconnect = function() end }
end } }
local upvalues = { [viewmodel.attach] = {[36]=RunService,[37]=update},
    [update] = {[5]=sway,[9]=shake}, [sway] = swayValues, [shake] = shakeValues }
swayValues[9], swayValues[10], shakeValues[4] = shifted, tilted, shaking
local writes = 0
local debug = { getupvalues = function(fn) return upvalues[fn] or {} end,
    setupvalue = function(fn, index, value)
        assert(fn==sway and (index==9 or index==10) or fn==shake and index==4,
            "unrelated viewmodel state changed")
        writes += 1 upvalues[fn][index] = value
    end }
local hooks, hookCount = {}, 0
local function hookfunction(fn, wrapper) hooks[fn] = wrapper hookCount += 1 return fn end
local function object(children) return { FindFirstChild = function(_, name) return children[name] end } end
local module = {}
local storage = object({ Client = object({ Tools = object({ Weapon = object({
    controllers = object({WeaponViewmodel=module}) }) }) }) })
local game = { GetService = function() return storage end }
local loaded, requires, identity = false, 0, 8
local function rivalsModuleLoaded() return loaded end
local function getthreadidentity() return identity end
local function setthreadidentity(value) identity = value end
local function require(m) assert(m==module and identity==2) requires+=1 return viewmodel end
local warnings = {}
local function warn(message) table.insert(warnings,message) end
local connections = {}
local function track(c) table.insert(connections,c) end
local VisualsTab = { Left = {} }
local function gameSection(_,_,title) return title end
local toggle
local Elements = { Toggle = function(_,_,_,callback) toggle=callback end }
-- INSERT_STEADY_GUN
Settings.SetupColdWarSteadyGun()
local steady = Settings.ColdWarSteadyGun
frame()
assert(requires==0 and hookCount==0)
toggle(true)
assert(requires==0)
loaded,now=true,2
frame()
assert(steady.Available and hookCount==2 and identity==8)
local result=table.pack(hooks[sway](0.1))
hooks[shake]()
assert(result.n==3 and result[1]=="sway" and result[2]==nil and result[3]==0.1)
assert(swayValues[9]==CFrame.identity and swayValues[10]==CFrame.identity and shakeValues[4]==CFrame.identity,
    "gun still sways/strafe-rolls/shakes")
assert(writes==3)
toggle(false)
hooks[sway](0.1) hooks[shake]()
assert(swayValues[9]==shifted and swayValues[10]==tilted and shakeValues[4]==shaking,
    "disable did not restore native viewmodel motion")
toggle(true)
Settings.SelectedGame="Rivals" frame()
hooks[sway](0.1)
assert(swayValues[9]==shifted,"No Sway affected another game")
Settings.SelectedGame="Cold War" frame()
hooks[sway](0.1)
assert(swayValues[9]==CFrame.identity)
steady.Restore()
hooks[sway](0.1)
assert(swayValues[9]==shifted,"unload left sway disabled")
Settings.SetupColdWarSteadyGun()
toggle(true)
assert(hookCount==2 and Settings.ColdWarSteadyGun.Available,"reinjection stacked viewmodel hooks")
Settings.ColdWarSteadyGun.Restore()
assert(#warnings==0)
print("PASS No Sway: deferred loaded module, sway/strafe/shake outputs only, native results, identity, independent game/disable/reinjection/unload")
