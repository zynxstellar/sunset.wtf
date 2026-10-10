local meta={}
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},meta) end}
function meta.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function meta.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function meta.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function meta.__unm(a) return a*-1 end
function meta.__index(a,k)
    if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=="Unit" then return a*(1/a.Magnitude) end
end
local Enum={RaycastFilterType={Exclude="exclude",Include="include"}}
local RaycastParams={new=function() return {} end}
local LocalPlayer={}
local Settings={}
local model={}
local part={Position=Vector3.new(0,0,20),Size=Vector3.new(2,2,2),IsDescendantOf=function(_,m) return m==model end}
local blocker={GetAttribute=function() return nil end,IsDescendantOf=function() return false end,
    FindFirstAncestorOfClass=function() return nil end}
local otherCharacter=false
function blocker:FindFirstAncestorOfClass() return otherCharacter and {FindFirstChildOfClass=function() return {} end} or nil end
local rays=0
local workspace={Raycast=function(_,origin,delta,params)
    rays+=1
    if params.FilterType=="include" then return {Position=Vector3.new(0,0,11)} end
    local ignores=params.FilterDescendantsInstances
    if not table.find(ignores,blocker) and origin.Z<=10 and origin.Z+delta.Z>=10 then
        return {Instance=blocker,Position=Vector3.new(0,0,10)}
    end
    if origin.Z<=20 and origin.Z+delta.Z>=20 then return {Instance=part,Position=part.Position} end
end}
local speeds={}
local tr={new=function(data) table.insert(speeds,data.MuzzleSpeed) return data end,
    GetPositionAtTime=function(arc,t) return arc.Origin+arc.Direction*(arc.MuzzleSpeed*t) end,
    GetVelocityAtTime=function(arc) return arc.Direction*arc.MuzzleSpeed end,
    GetForwardSpeed=function(arc) return arc.MuzzleSpeed end}
local outcome="Pierce"
local interactions={resolve=function(projectile,context)
    assert(projectile.PenetrationBudget==4 and projectile.PierceCount==0)
    assert(context.Rng:NextNumber()==0.5 and context.MuzzleSpeed==100)
    local exit,thickness=context.FindExit(context.Result.Position,context.IncomingDir,blocker,4)
    assert(exit.Z==11 and thickness==1)
    return {Outcome=outcome,NewOrigin=context.Result.Position,NewDirection=context.IncomingDir,
        NewSpeed=context.SpeedAtEnd*0.75,Thickness=1,Ignore=blocker}
end}
local types={withDefaults=function(w) return table.clone(w) end}
local params={Weapon={MuzzleSpeed=100,PenetrationPower=4,PierceMaxDeflectionDeg=0,MaxDistance=100,MaxTime=2},
    RaycastParams={FilterType="exclude",FilterDescendantsInstances={},IgnoreWater=false,RespectCanCollide=false,CollisionGroup="Ballistics"}}
-- INSERT_PENETRATION
local function trace() return Settings.ColdWarPenetrationTrace(tr,interactions,types,params,Vector3.new(),Vector3.new(0,0,1),0.2,model,part) end
assert(trace(),"native pierce decision did not reach enemy")
assert(speeds[2]==75,"speed loss was ignored")
assert(#params.RaycastParams.FilterDescendantsInstances==0 and params.Weapon.PenetrationPower==4,"dry run mutated native parameters")
outcome="Stop" assert(not trace(),"blocked material authorized shooting")
outcome="Ricochet" assert(not trace(),"random ricochet authorized shooting")
outcome="Pierce" otherCharacter=true assert(not trace(),"another character was penetrated") otherCharacter=false
params.Weapon.PierceMaxDeflectionDeg=90 assert(not trace(),"deflection envelope ignored") params.Weapon.PierceMaxDeflectionDeg=0
params.Weapon.MaxDistance=12 assert(not trace(),"range limit ignored") params.Weapon.MaxDistance=100
params.Weapon.Terminal={} assert(not trace(),"vehicle terminal ballistics simulated") params.Weapon.Terminal=nil
params.Weapon.Explosive=true assert(not trace(),"explosive wallbang allowed") params.Weapon.Explosive=false
local previous=interactions.resolve
interactions.resolve=function() return {Outcome="Pierce",NewOrigin=Vector3.new(0,0,10),NewDirection=Vector3.new(0,0,1),NewSpeed=100} end
assert(not trace(),"invalid ignore decision was accepted") interactions.resolve=previous
assert(rays<1000,"dry trace exceeded bounded work")
print("PASS penetration trace: native Pierce/Stop/Ricochet, exit query, speed loss, immutable params, other-character/range/deflection rejection")
