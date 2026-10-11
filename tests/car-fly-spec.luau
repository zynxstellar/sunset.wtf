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
local Enum=setmetatable({}, {__index=function(t,k) local v=setmetatable({}, {__index=function(_,key) return key end}) rawset(t,k,v) return v end})
local RunService={PreSimulation={Connect=function(_,fn) return {Disconnect=function() end} end}}
local now=10
local os={clock=function() return now end}
local Settings={SelectedGame="Cold War",Notify=function() end}
local MainTab={Left={}}
local controls,objects,connections,keys={},{},{},{}
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
    objects[#objects+1]=obj return obj
end
local chassis={Position=Vector3.new(0,10,0),Size=Vector3.new(6,4,10),FindFirstAncestorOfClass=function() return nil end,Parent=true,Anchored=false,AssemblyMass=100,CFrame={Position=Vector3.new(0,10,0),Rotation="upright",LookVector=Vector3.new(0,0,-1)},IsDescendantOf=function() return false end}
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
assert(objects[2].VectorVelocity.Y==25)
for _=1,100 do fly.Step(1/60) end assert(#objects==3,"constraints recreated each frame")
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
controls["Car Lift"](true)
fly.Step(1/60)
local plate=objects[#objects]
assert(plate.ClassName=="Part" and plate.Anchored and plate.CanCollide)
assert(plate.CFrame.Position.Y+0.5==8,"plate started above underside")
local firstY=plate.CFrame.Position.Y
fly.Step(1/60) assert(plate.CFrame.Position.Y==firstY,"idle platform rose")
controls["Car Fly"](true)
fly.Step(1/60)
assert(not plate.Destroyed,"flight destroyed catch platform")
chassis.Position=Vector3.new(10,20,20)
fly.Step(1/60)
assert(plate.CFrame.Position.Y>firstY,"platform did not follow flight height")
local flightHeight=plate.CFrame.Position.Y
controls["Car Fly"](false)
assert(not plate.Destroyed,"flight disable destroyed catch platform")
chassis.Position=Vector3.new(20,18,30)
fly.Step(1/60)
assert(plate.CFrame.Position.Y==flightHeight-2,"platform did not follow falling car downward")
assert(plate.CFrame.Position.X==20 and plate.CFrame.Position.Z==30,"platform did not follow driving horizontally")
for _=1,200 do fly.Step(1/60) end
assert(plate.CFrame.Position.Y==flightHeight-2,"platform height drifted below the wheels")
menu=true local paused=plate.CFrame.Position.Y
fly.Step(1/60) assert(plate.CFrame.Position.Y==paused)
menu=false
controls["Car Lift"](false) assert(plate.Destroyed)
controls["Car Lift"](true) fly.Step(1/60)
local replacement=objects[#objects]
joints={} fly.Step(1/60) assert(replacement.Destroyed,"seat exit left lift behind")
connections[#connections].Disconnect()
Settings.SetupColdWarCarFly()
fly=Settings.ColdWarCarFly
joints={{Part0=seat,Part1=root}}
do
local function event()
    local fn
    return {Connect=function(_,callback) fn=callback return {Disconnect=function() fn=nil end} end,
        Fire=function(_,part) if fn then fn(part) end end}
end
local model={Name="Car",Parent=workspace,DescendantAdded=event(),DescendantRemoving=event(),
    IsA=function(_,kind) return kind=="Model" end,GetAttribute=function() return 1 end,
    FindFirstChildOfClass=function() end,GetBoundingBox=function() return chassis.CFrame,chassis.Size end}
local wheel={Name="Tire",Parent=model,Position=Vector3.new(20,17,30),Size=Vector3.new(2,4,2),
    CFrame={RightVector=Vector3.new(0,1,0),UpVector=Vector3.new(1,0,0),LookVector=Vector3.new(0,0,1)},
    IsA=function(_,kind) return kind=="BasePart" end}
model.GetDescendants=function() return {wheel} end
chassis.FindFirstAncestorOfClass=function() return model end
seat.Parent=model
controls["Car Lift"](true) fly.Step(1/60)
local wheelPlate=objects[#objects]
assert(wheelPlate.CFrame.Position.Y+0.5==16,"rotated wheel bounds were ignored")
wheel.Position=Vector3.new(20,19,30) fly.Step(1/60)
assert(wheelPlate.CFrame.Position.Y+0.5==18,"suspension movement did not move support")
local second={Name="WheelRear",Parent=model,Position=Vector3.new(20,14,30),Size=wheel.Size,CFrame=wheel.CFrame,IsA=wheel.IsA}
model.DescendantAdded:Fire(second) fly.Step(1/60)
assert(wheelPlate.CFrame.Position.Y+0.5==13,"new wheel was not tracked")
model.DescendantRemoving:Fire(second) second.Parent=nil fly.Step(1/60)
assert(wheelPlate.CFrame.Position.Y+0.5==18,"removed wheel kept support too low")
controls["Car Lift"](false) assert(wheelPlate.Destroyed)
chassis.FindFirstAncestorOfClass=function() return nil end
seat.Parent=nil
end
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
Settings.ColdWarCarAntiAim={Enabled=true}
fly.Step(1/60) assert(not objects[#objects].Enabled,"Car Fly fought anti aim rotation")
Settings.ColdWarCarAntiAim.Enabled=false
fly.Step(1/60) assert(objects[#objects].Enabled,"Car Fly did not resume upright hold")
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
controls["Car Fling"](true) fly.Step(1/60)
joints={} fly.Step(1/60) assert(not fly.ContactCollisionActive)
connections[#connections].Disconnect()
print("PASS Car Fly: camera movement, normalized diagonals, custom/native driver seats, passenger/death/anchor filters, bounded constraints, menu/input pause, unload")
