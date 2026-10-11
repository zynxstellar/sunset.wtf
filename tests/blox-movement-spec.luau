local vector = {}
local mt = {}
function vector.new(x,y,z) return setmetatable({X=x,Y=y,Z=z}, mt) end
function mt.__index(v,key)
    local magnitude=math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z)
    if key=="Magnitude" then return magnitude end
    if key=="Unit" then return vector.new(v.X/magnitude,v.Y/magnitude,v.Z/magnitude) end
end
function mt.__mul(v,n) return vector.new(v.X*n,v.Y*n,v.Z*n) end
local zero=vector.new(0,0,0)
local character={}
local humanoid={Parent=true,Health=100,WalkSpeed=16,PlatformStand=false,AutoRotate=true}
local root={Parent=true,Anchored=false,AssemblyLinearVelocity=zero}
local paused=false
local direction=vector.new(1,1,0)
local created,destroyed,command=0,0,nil
-- INSERT_MOVEMENT
local movement=makeMovement({Zero=zero,
    Character=function() return character,humanoid,root end,
    Paused=function() return paused end,
    Direction=function() return direction end,
    CreateFlight=function()
        created+=1
        return {SetVelocity=function(_,value) command=value end,Destroy=function() destroyed+=1 end}
    end,
})
movement.Step()
assert(created==0 and humanoid.WalkSpeed==16)
movement.SetFly(true);movement.Step()
assert(created==1 and humanoid.PlatformStand and not humanoid.AutoRotate)
assert(math.abs(command.Magnitude-50)<1e-6, "diagonal flight exceeds configured speed")
movement.Step();assert(created==1)
paused=true;movement.Step();assert(command.Magnitude==0)
paused=false;movement.FlySpeed=90;movement.Step();assert(math.abs(command.Magnitude-90)<1e-6)
root.Anchored=true;movement.Step()
assert(destroyed==1 and not humanoid.PlatformStand and humanoid.AutoRotate)
root.Anchored=false;humanoid.SeatPart={};movement.Step();assert(created==1)
humanoid.SeatPart=nil;movement.Step();assert(created==2)
movement.SetFly(false);assert(destroyed==2 and not humanoid.PlatformStand)
movement.SetSpeed(true);movement.Step();assert(humanoid.WalkSpeed==32)
movement.WalkSpeed=70;movement.Step();assert(humanoid.WalkSpeed==70)
humanoid.WalkSpeed=20;movement.Step();assert(humanoid.WalkSpeed==70)
movement.SetSpeed(false);assert(humanoid.WalkSpeed==20,"native speed update was lost")
movement.SetSpeed(true);movement.Step();humanoid.WalkSpeed=24
movement.SetSpeed(false);assert(humanoid.WalkSpeed==24)
movement.SetSpeed(true);movement.SetFly(true);movement.Step()
local oldHumanoid=humanoid
character={};humanoid={Parent=true,Health=100,WalkSpeed=18,PlatformStand=false,AutoRotate=true}
root={Parent=true,Anchored=false,AssemblyLinearVelocity=zero}
movement.Step()
assert(oldHumanoid.WalkSpeed==24 and not oldHumanoid.PlatformStand and oldHumanoid.AutoRotate)
assert(humanoid.WalkSpeed==70 and created==4 and destroyed==3)
humanoid.Health=0;movement.Step()
assert(destroyed==4 and humanoid.WalkSpeed==18 and not humanoid.PlatformStand)
humanoid.Health=100;movement.Step();movement.Close()
assert(destroyed==5 and humanoid.WalkSpeed==18 and not humanoid.PlatformStand and humanoid.AutoRotate)
movement.Step();assert(created==5)
print("PASS Blox movement: only Fly/Speed, normalized speed, pause, anchor/seat, native speed restoration, respawn/death/unload")
