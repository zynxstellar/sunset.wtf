local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local mt={__mul=function(v,n) return Vector3.new(v.X*n,v.Y*n,v.Z*n) end}
local create=Vector3.new
Vector3.new=function(...) return setmetatable(create(...),mt) end
Vector3.zero=Vector3.new(0,0,0)
local now=0
local os={clock=function() return now end}
local Settings={SelectedGame="Cold War",Notify=function(_,err) error(err) end}
local root={Parent=true,Anchored=false,AssemblyMass=100,IsDescendantOf=function() return false end}
local seat={AssemblyRootPart=root}
local hum={Health=100}
local character={FindFirstChildOfClass=function() return hum end}
local LocalPlayer={Character=character}
Settings.ColdWarCarFly={DriverSeat=function() return seat end}
local workspace={Gravity=196.2}
local Enum={ActuatorRelativeTo={World="World"}}
local MainTab={Left={}}
local controls,connections,objects={},{},{}
local function gameSection() return {} end
local function track(c) table.insert(connections,c) end
local RunService={PreSimulation={Connect=function() return {Disconnect=function() end} end}}
local Elements={Toggle=function(_,name,_,callback) controls[name]=callback end,
    Slider=function(_,name,_,_,_,_,callback) controls[name]=callback end}
local function new(kind,props,parent)
    props.ClassName,props.Parent=kind,parent
    function props:Destroy() self.Destroyed=true self.Parent=nil end
    table.insert(objects,props) return props
end
-- INSERT_CAR_ANTI_AIM
Settings.SetupColdWarCarAntiAim()
local anti=Settings.ColdWarCarAntiAim
anti.Step() assert(#objects==0)
controls["Car Anti Aim"](true) anti.Step()
assert(#objects==2 and objects[2].ClassName=="AngularVelocity")
local first=objects[2].AngularVelocity
now=2 anti.Step()
assert(#objects==2 and objects[2].AngularVelocity.X~=first.X and objects[2].AngularVelocity.Z~=first.Z)
controls["Spin Speed"](100) anti.Step()
assert(math.abs(objects[2].AngularVelocity.X)<=12)
controls["Car Anti Aim"](false)
assert(objects[2].Destroyed and root.AssemblyAngularVelocity==Vector3.zero)
controls["Car Anti Aim"](true) anti.Step()
seat=nil anti.Step() assert(objects[4].Destroyed)
seat={AssemblyRootPart=root} anti.Step()
hum.Health=0 anti.Step() assert(objects[6].Destroyed)
hum.Health=100 anti.Step()
Settings.SelectedGame="Rivals" anti.Step() assert(objects[8].Destroyed)
Settings.SelectedGame="Cold War" anti.Step()
connections[#connections].Disconnect()
assert(objects[10].Destroyed and anti.Destroyed and not anti.Enabled)
print("PASS Car Anti Aim: driver validation, bounded multi-axis rotation, reuse, disable/seat loss/death/game/unload cleanup")
