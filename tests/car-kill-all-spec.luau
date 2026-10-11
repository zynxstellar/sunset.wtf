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
local CFrame={lookAt=function(pos) return {Position=pos} end}
local now=10
local os={clock=function() return now end}
local menu,typing=false,false
local function anyMenuVisible() return menu end
local UIS={GetFocusedTextBox=function() return typing end}
local controls,connections={},{}
local function track(c) connections[#connections+1]=c end
local function gameSection() return {} end
local Elements={Label=function() end,Toggle=function(_,n,_,f) controls[n]=f end,
    Slider=function(_,n,_,_,_,_,f) controls[n]=f end}
local AimTab={Left={}}
local fly={Enabled=false}
local Settings={SelectedGame="Cold War",ColdWarCarFly=fly}
local Players={}
local LocalPlayer={Parent=Players,Team=1}
local roster={LocalPlayer}
function Players:GetPlayers() return roster end
local function player(team,x)
    local health={Value=100,IsA=function(_,k) return k=="NumberValue" end}
    local limb={FindFirstChild=function() return health end}
    local hum={Health=100}
    local root={Position=Vector3.new(x,10,0),Anchored=false,GetJoints=function() return {} end,CFrame={LookVector=Vector3.new(0,0,-1)}}
    local character={Parent={},FindFirstChildOfClass=function() return hum end,
        FindFirstChild=function(_,name) return name=="HumanoidRootPart" and root or limb end}
    return {Parent=Players,Team=team,Character=character},hum,root,health
end
local ally=player(1,10)
local foe,hum,target,limbHealth=player(2,100)
roster={LocalPlayer,ally,foe}
local car=setmetatable({Position=Vector3.zero},{__newindex=function(_,key)
    error("Auto ram must not reposition the car: "..key)
end})
-- INSERT_CAR_KILL_ALL
Settings.SetupColdWarCarKillAll()
local ram=Settings.ColdWarCarKillAll
assert(fly.AutoRamControl(car)==nil and not fly.Enabled)
controls["Car Kill All"](true)
assert(ram.Enabled and fly.Enabled)
local velocity=fly.AutoRamControl(car)
assert(ram.Target==foe and ram.Active and car.Position==Vector3.zero and velocity.X>0)
assert(velocity.Magnitude<=150)
target.GetJoints=function() return {{Part1=target,Part0={Name="PassengerSeat",IsDescendantOf=function() return false end,IsA=function(_,kind) return kind=="Seat" end}}} end
now+=0.1 fly.AutoRamControl(car) assert(ram.Target==nil,"custom vehicle passenger retained")
target.GetJoints=function() return {} end
hum.SeatPart={} now+=1 fly.AutoRamControl(car)
assert(ram.Target==nil,"seated target retained")
hum.SeatPart=nil
local foe2,hum2=player(2,120)
roster={LocalPlayer,ally,foe,foe2}
now+=1 fly.AutoRamControl(car)
assert(ram.Target==foe2,"seated former target was immediately reselected")
now+=3.1 fly.AutoRamControl(car)
assert(ram.Target==foe2,"target abandoned before ten seconds")
now+=7 fly.AutoRamControl(car)
assert(ram.Target==foe,"ten-second timeout did not switch to another player")
roster={LocalPlayer,ally,foe}
local firstTarget=ram.Target
now+=0.1 fly.AutoRamControl(car) assert(ram.Target==firstTarget,"living target changed")
menu=true assert(fly.AutoRamControl(car).Magnitude==0 and not ram.Active)
menu=false typing=true assert(fly.AutoRamControl(car).Magnitude==0)
typing=false hum.Health=0 now+=1
assert(fly.AutoRamControl(car).Magnitude==0 and ram.Target==nil)
hum.Health=100 now+=1 fly.AutoRamControl(car)
limbHealth.Value=0 now+=1 fly.AutoRamControl(car) assert(ram.Target==nil,"limb-dead target was retained")
limbHealth.Value=100 now+=1 fly.AutoRamControl(car)
foe.Parent=nil now+=1 fly.AutoRamControl(car) assert(ram.Target==nil,"departed player retained")
foe.Parent=Players now+=1 fly.AutoRamControl(car)
fly.OnVehicleLost() assert(ram.Target==nil and not ram.Active)
controls["Car Kill All"](false) assert(fly.AutoRamControl(car)==nil)
controls["Car Kill All"](true) now+=1 fly.AutoRamControl(car)
connections[#connections].Disconnect()
assert(not ram.Enabled and not ram.Active and fly.AutoRamControl==nil and ram.Target==nil)
print("PASS Car Kill All: player-only enemy targeting, flight without position writes, bounded velocity, target retention/death/leave, menu/typing pause, seat-loss reset and unload")
