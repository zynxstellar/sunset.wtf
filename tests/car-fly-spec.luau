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
local CFrame={lookAt=function(_,v) return {LookVector=v} end}
local Enum=setmetatable({}, {__index=function(t,k) local v=setmetatable({}, {__index=function(_,key) return key end}) rawset(t,k,v) return v end})
local RunService={PreSimulation={Connect=function(_,fn) return {Disconnect=function() end} end}}
local Settings={SelectedGame="Cold War",Notify=function() end}
local MainTab={Left={}}
local controls,objects,connections,keys={},{},{},{}
local menu,typing=false,false
local function anyMenuVisible() return menu end
local UIS={GetFocusedTextBox=function() return typing end,IsKeyDown=function(_,key) return keys[key] end}
local function track(c) connections[#connections+1]=c end
local function gameSection() return {} end
local Elements={Label=function() end}
function Elements.Toggle(_,n,_,fn) controls[n]=fn end
function Elements.Slider(_,n,_,_,_,_,fn) controls[n]=fn end
local function new(kind,props,parent)
    local obj={Parent=parent,ClassName=kind}
    for k,v in pairs(props) do obj[k]=v end
    function obj:Destroy() self.Destroyed=true self.Parent=nil end
    objects[#objects+1]=obj return obj
end
local chassis={Parent=true,Anchored=false,AssemblyMass=100,CFrame={Rotation="upright",LookVector=Vector3.new(0,0,-1)},IsDescendantOf=function() return false end}
local seat={Name="DriverSeat",AssemblyRootPart=chassis,IsA=function(_,kind) return kind=="BasePart" or kind=="VehicleSeat" end,IsDescendantOf=function() return false end}
local joints={}
local root={GetJoints=function() return joints end}
local humanoid={Health=100,SeatPart=seat}
seat.Occupant=humanoid
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end}
local LocalPlayer={Character=character}
local workspace={Gravity=196.2,CurrentCamera={CFrame={LookVector=Vector3.new(0,0,-1)}}}
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
print("PASS Car Fly: camera movement, normalized diagonals, custom/native driver seats, passenger/death/anchor filters, bounded constraints, menu/input pause, unload")
