local function signal()
    local callbacks={}
    return {Connect=function(_,fn) callbacks[#callbacks+1]=fn return {Disconnect=function() end} end,
        Fire=function(_,dt) for _,fn in ipairs(callbacks) do fn(dt) end end}
end
local Color3={fromRGB=function(...) return {...} end}
local Vector2={new=function(...) return {...} end}
local Vector3={new=function(...) return {...} end}
local NumberRange={new=function(...) return {...} end}
local NumberSequence={new=function(v) return v end}
local NumberSequenceKeypoint={new=function(...) return {...} end}
local ColorSequence={new=function(v) return v end}
local root={CFrame="root position"}
local humanoid={Health=100}
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end}
local LocalPlayer={Character=character}
local workspace={CurrentCamera={}}
local RunService={Heartbeat=signal()}
local Settings={SelectedGame="Cold War"}
local VisualsTab={Left={}}
local controls,objects,connections={},{},{}
local function track(c) connections[#connections+1]=c end
local function gameSection() return {} end
local Elements={Label=function() end}
function Elements.Toggle(_,name,_,fn) controls[name]=fn end
Elements.ColorPicker=Elements.Toggle
function Elements.Slider(_,name,_,_,_,_,fn) controls[name]=fn end
local function new(kind,props,parent)
    local obj={ClassName=kind,Parent=parent,Total=0}
    for k,v in pairs(props) do obj[k]=v end
    function obj:Emit(n) self.Total+=n end
    function obj:Destroy() self.Parent=nil self.Destroyed=true end
    objects[#objects+1]=obj
    return obj
end
-- INSERT_LOCAL_EFFECTS
Settings.SetupColdWarLocalEffects()
RunService.Heartbeat:Fire(1) assert(#objects==0)
controls["Local Shooting Effects"](true)
RunService.Heartbeat:Fire(0.3)
assert(#objects==2 and objects[2].Total==4 and objects[2].Rate==0)
for _=1,100 do RunService.Heartbeat:Fire(0.01) end
assert(#objects==2 and objects[2].Total<=20,"effect allocation/emission unbounded")
humanoid.Health=0 RunService.Heartbeat:Fire(0.3)
assert(objects[1].Destroyed,"death left particles")
humanoid.Health=100 RunService.Heartbeat:Fire(0.3)
assert(#objects==4)
Settings.SelectedGame="Rivals" RunService.Heartbeat:Fire(0.3)
assert(objects[3].Destroyed)
Settings.SelectedGame="Cold War" RunService.Heartbeat:Fire(0.3)
connections[#connections].Disconnect()
assert(objects[5].Destroyed)
RunService.Heartbeat:Fire(0.3) assert(#objects==6)
print("PASS local effects: disabled default, bounded allocation/emission, death/game switch/unload cleanup")
