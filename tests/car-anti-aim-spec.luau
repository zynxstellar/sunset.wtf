local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local mt={__mul=function(v,n) return Vector3.new(v.X*n,v.Y*n,v.Z*n) end}
mt.__add=function(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
mt.__sub=function(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
mt.__index=function(v,k)
    local length=math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)
    if k=="Magnitude" then return length end
    if k=="Unit" then return v*(1/length) end
end
local create=Vector3.new
Vector3.new=function(...) return setmetatable(create(...),mt) end
Vector3.zero=Vector3.new(0,0,0)
local now=0
local os={clock=function() return now end}
local Settings={SelectedGame="Cold War",Notify=function(_,err) error(err) end}
local root={Parent=true,Anchored=false,AssemblyMass=100,Position=Vector3.zero,IsDescendantOf=function() return false end}
local seat={AssemblyRootPart=root}
local hum={Health=100}
local character={FindFirstChildOfClass=function() return hum end}
local LocalPlayer={Character=character}
Settings.ColdWarCarFly={DriverSeat=function() return seat end}
local CFrame={}
local frames={__mul=function(frame,rotation) frame.Rotation=rotation;return frame end}
function CFrame.new(position) return setmetatable({Position=position,Rotation="steady"},frames) end
local camera={Parent=true,CameraType="Custom",CameraSubject=hum,
    CFrame=CFrame.new(Vector3.new(0,5,12)),Focus=CFrame.new(Vector3.zero)}
local workspace={Gravity=196.2,CurrentCamera=camera}
local Enum={ActuatorRelativeTo={World="World"},CameraType={Scriptable="Scriptable"},RenderPriority={Last={Value=2000}}}
local MainTab={Left={}}
local controls,connections,objects={},{},{}
local function gameSection() return {} end
local function track(c) table.insert(connections,c) end
local RunService={PreSimulation={Connect=function() return {Disconnect=function() end} end}}
local render
function RunService:BindToRenderStep(_,_,fn) render=fn end
function RunService:UnbindFromRenderStep() render=nil end
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
assert(math.abs(first.Magnitude-45)<0.001,"faster default spin missing")
render()
assert(camera.CameraType=="Scriptable" and camera.CFrame.Rotation=="steady")
root.Position=Vector3.new(10,20,30)
camera.CFrame.Rotation="car rolled"
render()
assert(camera.CFrame.Rotation=="steady" and camera.CFrame.Position.X==10
    and camera.CFrame.Position.Y==25 and camera.CFrame.Position.Z==42,"camera inherited spin or failed to follow translation")
now=2 anti.Step()
assert(#objects==2 and objects[2].AngularVelocity.X~=first.X and objects[2].AngularVelocity.Z~=first.Z)
controls["Spin Speed"](999) anti.Step()
assert(math.abs(objects[2].AngularVelocity.Magnitude-120)<0.001)
controls["Car Anti Aim"](false)
assert(objects[2].Destroyed and root.AssemblyAngularVelocity==Vector3.zero)
assert(camera.CameraType=="Custom" and camera.CameraSubject==hum,"disable did not restore camera")
controls["Car Anti Aim"](true) anti.Step()
seat=nil anti.Step() assert(objects[4].Destroyed and camera.CameraType=="Custom")
seat={AssemblyRootPart=root} anti.Step()
hum.Health=0 anti.Step() assert(objects[6].Destroyed)
hum.Health=100 anti.Step()
Settings.SelectedGame="Rivals" anti.Step() assert(objects[8].Destroyed)
Settings.SelectedGame="Cold War" anti.Step()
connections[#connections].Disconnect()
assert(objects[10].Destroyed and anti.Destroyed and not anti.Enabled)
assert(render==nil and camera.CameraType=="Custom","unload left camera binding")
print("PASS Car Anti Aim: faster bounded spin, stable translated camera, driver validation, constraint reuse and camera restoration")
