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
local noclip={Enabled=false}
function noclip.SetEnabled(on) noclip.Enabled=on end
local Settings={SelectedGame="Cold War",ColdWarCarFly=fly,ColdWarCarNoclip=noclip}
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
        FindFirstChild=function(_,name)
            if name=="CharacterValues" then return {FindFirstChild=function() return {Value=hum.Unconscious==true} end} end
            return name=="HumanoidRootPart" and root or limb
        end}
    return {Parent=Players,Team=team,Character=character},hum,root,health
end
local ally=player(1,10)
local foe,hum,target,limbHealth=player(2,100)
local far=player(2,500)
roster={LocalPlayer,ally,far,foe}
local car=setmetatable({Position=Vector3.zero},{__newindex=function(_,key)
    error("Auto ram must not reposition the car: "..key)
end})
local buriedX
local groundPart={Name="Ground"}
local workspace={Terrain={},FindFirstChild=function() return nil end}
function workspace:Raycast(origin)
    if origin.X==buriedX then return {Position=Vector3.new(origin.X,20,0),Material="Enum.Material.Grass",Instance=groundPart} end
end
local RaycastParams={new=function() return {} end}
local Enum={RaycastFilterType={Exclude="Exclude"}}
-- INSERT_CAR_KILL_ALL
Settings.SetupColdWarCarKillAll()
local ram=Settings.ColdWarCarKillAll
assert(fly.AutoRamControl(car)==nil and not fly.Enabled)
controls["Car Kill All"](true)
assert(ram.Enabled and fly.Enabled and noclip.Enabled)
local velocity=fly.AutoRamControl(car)
assert(ram.Target==foe and velocity.Y<0 and not ram.Contact)
assert(velocity.Magnitude<=100/(3.6*0.28))
car.Position=Vector3.new(0,-12,0)
local cruise=fly.AutoRamControl(car)
assert(cruise.X>100/(3.6*0.28) and cruise.Magnitude<=300/(3.6*0.28))
car.Position=Vector3.new(95,-12,0)
assert(fly.AutoRamControl(car).Y>0)
car.Position=Vector3.new(95,10,0)
assert(fly.AutoRamControl(car).X>0)
car.Position=Vector3.new(102,10,0)
assert(fly.AutoRamControl(car).X>0,"reversed before contact pass completed")
car.Position=Vector3.new(107,10,0)
assert(fly.AutoRamControl(car).X<0)
-- Live nearest selection uses our character instead of the car's root.
local localRoot={Position=Vector3.new(0,10,0)}
LocalPlayer.Character={FindFirstChild=function() return localRoot end}
local nearer,nearHum,nearRoot=player(2,20)
roster={LocalPlayer,ally,foe,nearer}
now+=0.3 fly.AutoRamControl(car)
assert(ram.Target==nearer,"nearby enemy was skipped while retaining old target")
buriedX=20 now+=0.3 fly.AutoRamControl(car)
assert(ram.Target==foe,"underground target retained")
buriedX=nil now+=0.3 fly.AutoRamControl(car) assert(ram.Target==nearer)
nearHum.Unconscious=true now+=0.3 fly.AutoRamControl(car)
assert(ram.Target==foe,"knocked target retained")
nearHum.Unconscious=false nearHum.SeatPart={}
now+=0.3 fly.AutoRamControl(car) assert(ram.Target==foe)
nearHum.SeatPart=nil
nearRoot.GetJoints=function() return {{Part1=nearRoot,Part0={Name="PassengerSeat",IsDescendantOf=function() return false end,IsA=function(_,kind) return kind=="Seat" end}}} end
now+=0.3 fly.AutoRamControl(car) assert(ram.Target==foe,"custom vehicle passenger targeted")
nearRoot.GetJoints=function() return {} end
now+=0.3 fly.AutoRamControl(car) assert(ram.Target==nearer)
now+=3.1 fly.AutoRamControl(car) assert(ram.Target==nearer,"timeout before ten seconds")
now+=7 fly.AutoRamControl(car) assert(ram.Target==foe,"ten-second timeout did not try another enemy")
now+=3.1 fly.AutoRamControl(car) assert(ram.Target==nearer,"timed-out player was skipped permanently")
menu=true assert(fly.AutoRamControl(car).Magnitude==0 and not ram.Active)
menu=false typing=true assert(fly.AutoRamControl(car).Magnitude==0)
typing=false
nearHum.Health=0 hum.Health=0 now+=0.3
assert(fly.AutoRamControl(car).Magnitude==0 and ram.Target==nil)
controls["Car Kill All"](false) assert(not noclip.Enabled and fly.AutoRamControl(car)==nil)
controls["Car Kill All"](true)
connections[#connections].Disconnect() assert(not ram.Enabled and fly.AutoRamControl==nil and not noclip.Enabled)
-- Distant hops are bounded to 100 studs and do not repeat near the target.
Settings.SetupColdWarCarKillAll()
ram=Settings.ColdWarCarKillAll
local knocked,knockedHum=player(2,5) knockedHum.Unconscious=true
local distant,distantHum,distantRoot=player(2,1000)
roster={LocalPlayer,knocked,distant}
local hopWrites=0
local hopCar=setmetatable({Position=Vector3.zero,AssemblyLinearVelocity=Vector3.zero},{__newindex=function(self,key,value)
    assert(key=="CFrame") hopWrites+=1 self.Position=value.Position
end})
controls["Car Kill All"](true) now+=1
local hopping=fly.AutoRamControl(hopCar)
assert(ram.Target==distant and hopWrites==1)
assert((hopCar.Position-distantRoot.Position).Magnitude<=100.001)
assert(hopping.Magnitude<=300/(3.6*0.28))
fly.AutoRamControl(hopCar) assert(hopWrites==1)
distantHum.Unconscious=true now+=1 fly.AutoRamControl(hopCar) assert(ram.Target==nil)
connections[#connections].Disconnect()
print("PASS Car Kill All: live nearest-player selection, knocked/seated filters, timeout retry, underground speed and hop bounds, ram path and cleanup")
