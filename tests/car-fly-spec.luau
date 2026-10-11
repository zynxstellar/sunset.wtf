local vectors={}
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},vectors) end}
Vector3.zero=Vector3.new(0,0,0)
function vectors.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function vectors.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function vectors.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function vectors.__index(a,k)
    if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=="Unit" then return a*(1/a.Magnitude) end
end
local Color3={fromRGB=function(...) return {...} end}
local CFrame={new=function(x,y,z) return {Position=Vector3.new(x,y,z)} end,lookAt=function(_,v) return {LookVector=v} end}
local RaycastParams={new=function() return {} end}
local Enum=setmetatable({}, {__index=function(t,k) local v=setmetatable({}, {__index=function(_,key) return key end}) rawset(t,k,v) return v end})
local RunService={PreSimulation={Connect=function(_,fn) return {Disconnect=function() end} end}}
local now=10
local os={clock=function() return now end}
local Settings={SelectedGame="Cold War",Notify=function() end}
local MainTab={Left={}}
local controls,objects,connections,keys={},{},{},{}
local platforms={}
local menu,typing=false,false
local function anyMenuVisible() return menu end
local UIS={GetFocusedTextBox=function() return typing end,IsKeyDown=function(_,key) return keys[key] end}
local function track(c) connections[#connections+1]=c end
local function gameSection() return {} end
local Elements={Label=function() end,Button=function(_,n,fn) controls[n]=fn end}
function Elements.Toggle(_,n,_,fn) controls[n]=fn end
function Elements.Slider(_,n,_,_,_,_,fn) controls[n]=fn end
local function new(kind,props,parent)
    local obj={Parent=parent,ClassName=kind}
    for k,v in pairs(props) do obj[k]=v end
    function obj:Destroy() self.Destroyed=true self.Parent=nil end
    if kind=="Part" then platforms[#platforms+1]=obj else objects[#objects+1]=obj end
    return obj
end
local chassis={Position=Vector3.new(0,10,0),Size=Vector3.new(6,4,10),FindFirstAncestorOfClass=function() return nil end,Parent=true,Anchored=false,AssemblyMass=100,AssemblyLinearVelocity=Vector3.zero,CFrame={Position=Vector3.new(0,10,0),Rotation="upright",LookVector=Vector3.new(0,0,-1)},IsDescendantOf=function() return false end}
local seat={Name="DriverSeat",AssemblyRootPart=chassis,IsA=function(_,kind) return kind=="BasePart" or kind=="VehicleSeat" end,IsDescendantOf=function() return false end}
local joints={}
local root={GetJoints=function() return joints end}
local humanoid={Health=100,SeatPart=seat}
seat.Occupant=humanoid
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end}
local LocalPlayer={Character=character}
local OverlapParams={new=function() return {} end}
local nearby={}
local workspace={Gravity=196.2,CurrentCamera={CFrame={LookVector=Vector3.new(0,0,-1)}}}
local grounded=false
function workspace:Raycast() return grounded and {} or nil end
function workspace:FindFirstChild() return self.Vehicles end
function workspace:GetPartBoundsInRadius(_,_,params)
    assert(params.MaxParts==64 and params.FilterDescendantsInstances[1]==self.Vehicles)
    return nearby
end
-- INSERT_CAR_FLY
Settings.SetupColdWarCarFly()
local fly=Settings.ColdWarCarFly
fly.Step(1/60) assert(#objects==0)
controls["Car Fly"](true)
keys.W=true keys.D=true keys.Space=true
fly.Step(1/60)
assert(#objects==3 and math.abs(objects[2].VectorVelocity.Magnitude-math.sqrt(45*45+25*25))<0.001)
assert(#platforms==0,"platform appeared during active flight")
assert(objects[2].VectorVelocity.Y==25)
for _=1,100 do fly.Step(1/60) end assert(#objects==3,"constraints recreated each frame")
workspace.FallenPartsDestroyHeight=-500
chassis.Position=Vector3.new(0,-450,0)
keys.Space=false keys.LeftControl=true
fly.Step(1/60)
assert(objects[2].VectorVelocity.Y>=fly.VerticalSpeed,"flight continued downward into destruction height")
chassis.Position=Vector3.new(0,10,0)
keys.LeftControl=false

menu=true fly.Step(1/60) assert(objects[2].VectorVelocity.Magnitude==0)
menu=false typing=true fly.Step(1/60) assert(objects[2].VectorVelocity.Magnitude==0)
typing=false
humanoid.SeatPart=nil fly.Step(1/60) assert(objects[1].Destroyed and objects[3].Destroyed)
joints={{Part0=seat,Part1=root}}
fly.Step(1/60) assert(#objects==6,"custom Motor6D driver seat unsupported")
seat.Name="PassengerSeat" seat.IsA=function(_,kind) return kind=="BasePart" end
fly.Step(1/60) assert(objects[4].Destroyed,"passenger kept control")
seat.Name="DriverSeat" fly.Step(1/60)
humanoid.Health=0 fly.Step(1/60) assert(objects[7].Destroyed)
humanoid.Health=100 chassis.Anchored=true fly.Step(1/60) assert(#objects==9)
chassis.Anchored=false fly.Step(1/60)
Settings.SelectedGame="Rivals" fly.Step(1/60) assert(objects[10].Destroyed)
Settings.SelectedGame="Cold War" fly.Step(1/60)
connections[#connections].Disconnect() assert(objects[13].Destroyed)
fly.Step(1/60) assert(#objects==15)
Settings.SetupColdWarCarFly()
fly=Settings.ColdWarCarFly
joints={{Part0=seat,Part1=root}}
local countPlatforms=#platforms
controls["Car Fly"](true)
fly.Step(1/60)
assert(#platforms==countPlatforms,"platform appeared in flight")
controls["Car Fly"](false)
chassis.AssemblyLinearVelocity=Vector3.new(0,5,0)
fly.Step(1/60)
assert(#platforms==countPlatforms,"platform appeared while rising")
chassis.AssemblyLinearVelocity=Vector3.new(0,-10,0)
grounded=true
fly.Step(1/60)
assert(#platforms==countPlatforms,"platform appeared on the ground")
grounded=false
fly.Step(1/60)
local plate=platforms[#platforms]
assert(#platforms==countPlatforms+1 and plate.Anchored and plate.CanCollide,"fall after flight did not create catch platform")
local height=plate.CFrame.Position.Y
chassis.Position=Vector3.new(20,18,30)
chassis.AssemblyLinearVelocity=Vector3.zero
fly.Step(1/60)
assert(plate.CFrame.Position.Y==height and plate.CFrame.Position.X==20,"catch platform followed falling height or failed horizontal follow")
for _=1,100 do fly.Step(1/60) end
assert(#platforms==countPlatforms+1,"catch platform recreated each frame")
controls["Car Fly"](true)
assert(plate.Destroyed,"resuming flight left platform")
fly.Step(1/60)
controls["Car Fly"](false)
chassis.AssemblyLinearVelocity=Vector3.new(0,-5,0)
fly.Step(1/60)
local replacement=platforms[#platforms]
joints={} fly.Step(1/60)
assert(replacement.Destroyed,"seat exit left catch platform")
connections[#connections].Disconnect()
Settings.SetupColdWarCarFly()
fly=Settings.ColdWarCarFly
joints={{Part0=seat,Part1=root}}
controls["Car Lift"](true)
chassis.AssemblyLinearVelocity=Vector3.zero
countPlatforms=#platforms
fly.Step(1/60)
assert(#platforms==countPlatforms,"Car Lift created platform while stationary")
chassis.AssemblyLinearVelocity=Vector3.new(0,-10,0)
fly.Step(1/60)
local manualPlate=platforms[#platforms]
assert(#platforms==countPlatforms+1)
controls["Car Lift"](false)
assert(manualPlate.Destroyed)
chassis.AssemblyLinearVelocity=Vector3.zero
Settings.ColdWarCarNoclip={Enabled=true}
controls["Car Fling"](true)
assert(fly.Enabled and fly.ContactFlingEnabled and Settings.ColdWarCarNoclip.Enabled)
keys.W=true keys.D=false keys.Space=false
fly.Step(1/60)
assert(not fly.ContactCollisionActive and objects[#objects-1].VectorVelocity.Magnitude==45)
workspace.Vehicles={}
chassis.Parent=workspace
local other={Anchored=false}
local otherModel={Parent=workspace.Vehicles,IsA=function(_,k) return k=="Model" end,GetAttribute=function() return 2 end}
nearby={{AssemblyRootPart=other,Parent=otherModel}}
fly.Step(1/60)
assert(fly.ContactCollisionActive and objects[#objects-1].VectorVelocity.Magnitude==150)
assert(objects[#objects].ClassName=="AlignOrientation" and objects[#objects].Enabled)
assert(Settings.ColdWarCarNoclip.Enabled,"contact boost disabled noclip")
controls["Ram Speed"](200) fly.Step(1/60)
assert(objects[#objects-1].VectorVelocity.Magnitude==200)
local count=#objects
for _=1,100 do fly.Step(1/60) end assert(#objects==count)
for _,object in ipairs(objects) do assert(object.ClassName~="AngularVelocity","ram mode created spin") end
menu=true fly.Step(1/60)
assert(not fly.ContactCollisionActive and objects[#objects-1].VectorVelocity.Magnitude==0)
menu=false keys.W=false fly.Step(1/60) assert(not fly.ContactCollisionActive)
keys.W=true other.Anchored=true fly.Step(1/60) assert(not fly.ContactCollisionActive)
other.Anchored=false fly.Step(1/60)
controls["Car Fling"](false)
assert(not fly.ContactCollisionActive and fly.Enabled)
controls["Car Fling"](true) fly.Step(1/60)
controls["Car Fly"](false)
assert(not fly.ContactCollisionActive and not fly.ContactFlingEnabled)
assert(platforms[#platforms].Destroyed,"platform appeared before falling after disable")
controls["Car Fling"](true) fly.Step(1/60)
joints={} fly.Step(1/60) assert(not fly.ContactCollisionActive)
connections[#connections].Disconnect()
print("PASS Car Fly: camera movement, normalized diagonals, custom/native driver seats, passenger/death/anchor filters, bounded constraints, menu/input pause, unload")
