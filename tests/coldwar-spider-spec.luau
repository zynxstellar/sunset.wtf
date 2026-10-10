local Vector3={}
local meta={}
function Vector3.new(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},meta) end
function meta.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function meta.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function meta.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function meta.__index(a,key)
    if key=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if key=="Unit" then return a*(1/a.Magnitude) end
end
local Enum={RaycastFilterType={Exclude="exclude"},HumanoidStateType={Swimming="swim"}}
local RaycastParams={new=function() return {} end}
local humanoid={Health=100,MoveDirection=Vector3.new(1,0,0),State="run"}
function humanoid:GetState() return self.State end
local root={Parent={},Position=Vector3.new(),AssemblyLinearVelocity=Vector3.new(2,0,3)}
local character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end}
local LocalPlayer={Character=character,Kicks={}}
function LocalPlayer:Kick(message) table.insert(self.Kicks,message) end
local menu,typing=false,false
local function anyMenuVisible() return menu end
local UIS={GetFocusedTextBox=function() return typing end}
local Settings={SelectedGame="Cold War",Notifications={}}
function Settings.Notify(title,message) table.insert(Settings.Notifications,message) end
local normal=Vector3.new(-1,0,0)
local ledge,blocked=false,false
local workspace={Raycast=function(_,position,direction,params)
    assert(params.RespectCanCollide and params.FilterDescendantsInstances[1]==character)
    if ledge then
        if direction.Y<0 then return {Normal=Vector3.new(0,1,0),Position=root.Position+Vector3.new(0,1,0)} end
        if direction.Y>0 then return blocked and {Normal=Vector3.new(0,-1,0)} or nil end
        return nil
    end
    return normal and {Normal=normal} or nil
end}
local connections={}
local function track(c) table.insert(connections,c) end
local RunService={PreSimulation={Connect=function(_,fn) return {Disconnect=function() end} end}}
local MainTab={Left={}}
local function gameSection() return {} end
local Elements={}
function Elements.Toggle(_,_,default,fn) return {Set=function(value) fn(value) end} end
function Elements.Slider() end
-- INSERT_COLDWAR_SPIDER
Settings.SetupColdWarSpider()
local spider=Settings.ColdWarSpider
local function step()
    root.Position+=root.AssemblyLinearVelocity*0.05
    spider.Step(0.05)
end
step() assert(root.AssemblyLinearVelocity.Y==0,"disabled spider moved the character")
spider.Toggle.Set(true)
for i=1,20 do step() end
assert(root.AssemblyLinearVelocity.Y==12 and root.AssemblyLinearVelocity.X==2 and root.AssemblyLinearVelocity.Z==3)
assert(#LocalPlayer.Kicks==0,"normal climbing triggered correction exit")
normal=Vector3.new(-0.7,0.7,0) step()
assert(root.AssemblyLinearVelocity.Y==12,"roof slope stopped climbing")
ledge=true step()
assert(root.AssemblyLinearVelocity.X==6 and root.AssemblyLinearVelocity.Y==12,"clear ledge did not mantle")
blocked=true step()
assert(root.AssemblyLinearVelocity.Y==0,"mantle ignored blocked headroom")
ledge,blocked=false,false
normal=Vector3.new(-1,0,0) step()
normal=Vector3.new(0,1,0) step()
assert(root.AssemblyLinearVelocity.Y==0,"floor or ceiling was treated as a wall")
normal=Vector3.new(-1,0,0)
menu=true step() assert(root.AssemblyLinearVelocity.Y==0) menu=false
typing=true step() assert(root.AssemblyLinearVelocity.Y==0) typing=false
humanoid.Sit=true step() assert(root.AssemblyLinearVelocity.Y==0) humanoid.Sit=false
humanoid.Health=0 step() assert(root.AssemblyLinearVelocity.Y==0) humanoid.Health=100
for i=1,5 do step() end
root.Position+=Vector3.new(50,0,0) step()
assert(not spider.Enabled and #LocalPlayer.Kicks==1 and LocalPlayer.Kicks[1]=="Saved from AC")
step() assert(#LocalPlayer.Kicks==1,"correction caused repeated kicks")
spider.Toggle.Set(true) spider.LeaveOnCorrection=false
for i=1,5 do step() end
root.Position+=Vector3.new(50,0,0) step()
assert(not spider.Enabled and #LocalPlayer.Kicks==1 and #Settings.Notifications==1,"disable-only correction setting failed")
spider.Toggle.Set(true) step()
for _,connection in ipairs(connections) do connection:Disconnect() end
step()
assert(spider.Destroyed and not spider.Enabled and root.AssemblyLinearVelocity.Y==0,"unload left climbing active")
print("PASS Cold War Spider: wall-only movement, velocity preservation, input/death filters, correction exit/stop, unload")
