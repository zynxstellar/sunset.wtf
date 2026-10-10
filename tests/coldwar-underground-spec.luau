local meta={}
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},meta) end}
function meta.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function meta.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function meta.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function meta.__index(a,k)
    if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=="Unit" then return a*(1/a.Magnitude) end
end
local CFrame={new=function(p) return setmetatable({Position=p,Rotation={}}, {__mul=function(a,b) a.Rotation=b return a end}) end}
local Enum={RaycastFilterType={Exclude="exclude"}}
local RaycastParams={new=function() return {} end}
local function body(collides)
    local part={Parent={},CanCollide=collides,CFrame=CFrame.new(Vector3.new(0,3,0)),IsA=function(_,kind) return kind=="BasePart" end}
    return setmetatable(part,{__index=function(a,k) if k=="Position" then return a.CFrame.Position end end})
end
local root,accessory=body(true),body(false)
local parts={root,accessory}
local humanoid={Health=100,WalkSpeed=16,MoveDirection=Vector3.new(1,0,0)}
local onAdded,addedDisconnected
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end,
    GetDescendants=function() return parts end,
    DescendantAdded={Connect=function(_,fn) onAdded=fn addedDisconnected=false return {Disconnect=function() addedDisconnected=true end} end}}
local LocalPlayer={Character=character}
local menu,typing=false,false
local function anyMenuVisible() return menu end
local UIS={GetFocusedTextBox=function() return typing end}
local floor=true
local workspace={Raycast=function(_,origin,direction,params)
    assert(params.FilterDescendantsInstances[1]==character and params.RespectCanCollide)
    return floor and {Position=Vector3.new(origin.X,0,origin.Z),Normal=Vector3.new(0,1,0)} or nil
end}
local Settings={SelectedGame="Cold War",Notifications=0}
function Settings.Notify() Settings.Notifications+=1 end
local controls,connections={},{}
local MainTab={Left={}}
local function gameSection() return {} end
local Elements={}
function Elements.Toggle(_,name,_,fn) controls[name]=fn return {Set=fn} end
function Elements.Slider(_,name,_,_,_,_,fn) controls[name]=fn end
local function track(c) table.insert(connections,c) end
local RunService={PreSimulation={Connect=function() return {Disconnect=function() end} end}}
-- INSERT_UNDERGROUND
Settings.SetupColdWarUnderground()
local underground=Settings.ColdWarUnderground
underground.Step(0.1) assert(root.Position.Y==3 and root.CanCollide)
controls.Underground(true) underground.Step(0.1)
assert(root.Position.Y==-8 and math.abs(root.Position.X-1.6)<0.001 and not root.CanCollide and not accessory.CanCollide)
assert(controls["Crawl Speed"]==nil,"retired speed slider remains")
do
    local x=root.Position.X
    humanoid.WalkSpeed=24 underground.Step(0.1)
    assert(math.abs(root.Position.X-x-2.4)<0.001,"normal speed changes were ignored")
    x=root.Position.X humanoid.MoveDirection=Vector3.new(0.5,0,0) underground.Step(0.1)
    assert(math.abs(root.Position.X-x-1.2)<0.001,"analog movement was amplified")
    x=root.Position.X humanoid.WalkSpeed=0 underground.Step(0.1)
    assert(root.Position.X==x,"zero walking speed still moved")
    humanoid.WalkSpeed=16 humanoid.MoveDirection=Vector3.new(1,0,0)
end
local added=body(true) table.insert(parts,added) onAdded(added) assert(not added.CanCollide)
menu=true local x=root.Position.X underground.Step(0.1) menu=false assert(root.Position.X==x)
typing=true underground.Step(0.1) typing=false assert(root.Position.X==x)
controls.Depth(12) underground.Step(0.1) assert(root.Position.Y==-12)
controls.Underground(false)
assert(root.Position.Y==3.5 and root.CanCollide and not accessory.CanCollide and added.CanCollide and addedDisconnected)
controls.Underground(true) underground.Step(0.1)
floor=false underground.Step(0.1)
assert(not underground.Enabled and root.Position.Y==3.5 and root.CanCollide and Settings.Notifications==1)
controls.Underground(true) underground.Step(0.1)
assert(not underground.Enabled and root.Position.Y==3.5 and Settings.Notifications==2)
floor=true controls.Underground(true) underground.Step(0.1)
local deadPosition=root.Position humanoid.Health=0 underground.Step(0.1)
assert(not underground.Enabled and root.CanCollide and root.Position==deadPosition,"death teleported corpse or retained collision changes")
humanoid.Health=100 root.CFrame=CFrame.new(Vector3.new(0,3,0)) controls.Underground(true) underground.Step(0.1)
local oldRoot=root root=body(true) parts={root,accessory} underground.Step(0.1)
assert(not underground.Enabled and oldRoot.CanCollide and root.Position.Y==3,"respawn moved new root")
controls.Underground(true) underground.Step(0.1)
for _,c in ipairs(connections) do c:Disconnect() end
controls.Underground(true) underground.Step(0.1)
assert(underground.Destroyed and not underground.Enabled and root.Position.Y==3.5 and root.CanCollide)
print("PASS Underground: depth/movement, menu pause, descendants, disable/death/respawn/unload, missing ground restoration")
