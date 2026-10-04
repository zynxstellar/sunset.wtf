local function signal()
    local listeners={}
    return {Connect=function(_,fn)
        local entry={Fn=fn,Active=true}
        table.insert(listeners,entry)
        return {Disconnect=function() entry.Active=false end}
    end,Fire=function(_,...) for _,entry in ipairs(listeners) do if entry.Active then entry.Fn(...) end end end}
end
local meta={}
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},meta) end}
function meta.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function meta.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function meta.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function meta.__index(v,k)
    if k=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if k=="Unit" then local m=v.Magnitude return Vector3.new(v.X/m,v.Y/m,v.Z/m) end
end
Vector3.zero=Vector3.new(0,0,0)
Vector3.yAxis=Vector3.new(0,1,0)
local CFrame={lookAt=function() return {} end}
local game={PlaceId=17625359962,GameId=6035872082}
local Settings={FlyEnabled=true,FlySpeed=50,FlyCoast=0.5,SelectedGame="Rivals"}
local root={Parent=true,Position=Vector3.zero,CFrame={},AssemblyLinearVelocity=Vector3.zero}
local hum={Parent=true,Health=100,PlatformStand=false}
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return hum end}
local LocalPlayer={Character=character,CharacterAdded=signal()}
local Enum={KeyCode={W="W",S="S",D="D",A="A",Space="Space",LeftShift="Shift"}}
local held,focused,menu={},false,false
local UIS={IsKeyDown=function(_,k) return held[k] end,GetFocusedTextBox=function() return focused end}
local function anyMenuVisible() return menu end
local workspace={CurrentCamera={CFrame={LookVector=Vector3.new(0,0,-1),RightVector=Vector3.new(1,0,0)}}}
local RunService={RenderStepped=signal()}
local task={wait=function() end}
local movers={}
local function new(class,props,parent)
    local object={ClassName=class,Parent=parent}
    for k,v in pairs(props) do object[k]=v end
    function object:Destroy() self.Parent=nil end
    table.insert(movers,object)
    return object
end
local function track(c) return c end
-- INSERT_FLY_PRODUCTION
local initialFrame=root.CFrame
Fly.Start()
assert(hum.PlatformStand and #movers==2)
held.W=true
RunService.RenderStepped:Fire()
assert(movers[1].Velocity.Z==-50 and root.CFrame==initialFrame,"flight did not use velocity only")
Fly.Stop()
assert(root.AssemblyLinearVelocity.Z==-25 and not hum.PlatformStand,"disable did not preserve coast momentum")
assert(not movers[1].Parent and not movers[2].Parent,"flight actuators survived disable")
Fly.Start()
held.Space=true
RunService.RenderStepped:Fire()
assert(math.abs(movers[3].Velocity.Magnitude-50)<0.0001,"diagonal speed not normalized")
menu=true
RunService.RenderStepped:Fire()
assert(movers[3].Velocity.Magnitude==0,"open menu still moved flight")
menu=false
focused=true
RunService.RenderStepped:Fire()
assert(movers[3].Velocity.Magnitude==0,"typing moved flight")
focused=false
RunService.RenderStepped:Fire()
Fly.Stop(false)
assert(root.AssemblyLinearVelocity.Magnitude==0 and not hum.PlatformStand,"cleanup did not stop flight")
hum.PlatformStand=true
Fly.Start()
Fly.Stop()
assert(hum.PlatformStand,"original humanoid state not restored")
hum.Health=0
local count=#movers
Fly.Start()
assert(#movers==count,"flight started on dead character")
print("PASS velocity Fly: camera movement, no position snapping, coast on disable, menu/typing pause, cleanup")
