local IS_GENERIC=true
local game={PlaceId=286090429}
local V,meta={},{}
function V.new(x,y,z) return setmetatable({X=x,Y=y,Z=z,Magnitude=math.sqrt(x*x+y*y+z*z)},meta) end
meta.__add=function(a,b) return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
meta.__sub=function(a,b) return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
meta.__mul=function(a,b) return V.new(a.X*b,a.Y*b,a.Z*b) end
meta.__index=function(a,key) if key=="Unit" then return V.new(a.X/a.Magnitude,a.Y/a.Magnitude,a.Z/a.Magnitude) end end
local Vector3=V;Vector3.zero=V.new(0,0,0)
local CFrame,Fmeta={},{}
function CFrame.new(x,y,z) return setmetatable({Position=type(x)=="table" and x or V.new(x or 0,y or 0,z or 0)},Fmeta) end
Fmeta.__mul=function(a,b) return CFrame.new(a.Position+b.Position) end
Fmeta.__index={ToOrientation=function() return 0,0,0 end}
function CFrame.fromOrientation() return CFrame.new() end
function CFrame.lookAt(position) return CFrame.new(position) end
local Enum={CameraType={Scriptable="scriptable"},RenderPriority={Last={Value=200}},UserInputType={MouseButton2="right"},
    KeyCode={W="W",A="A",S="S",D="D",E="E",Q="Q"},RaycastFilterType={Exclude="exclude"}}
local Settings,ENV={},{}
local camera={Parent=true,CFrame=CFrame.new(100,5,100),Focus=CFrame.new(100,5,90),CameraType="custom",CameraSubject={}}
local workspace={CurrentCamera=camera}
local Players={}
local function character(x,z,health,shield)
    local root={Parent=true,Position=V.new(x,0,z),CFrame=CFrame.new(x,0,z)}
    local head={Parent=true,Position=V.new(x,1.5,z)}
    local model={Root=root,Head=head,Humanoid={Health=health}}
    function model:FindFirstChild(name) return name=="HumanoidRootPart" and root or name=="Head" and head end
    function model:FindFirstChildOfClass(name) return name=="Humanoid" and self.Humanoid or name=="ForceField" and shield end
    function model:IsDescendantOf(world) return world==workspace end
    return model
end
local LocalPlayer={Parent=Players,Neutral=false,Team=1,Character=character(0,0,100)}
local enemy={Parent=Players,Neutral=false,Team=2,Character=character(10,0,100)}
local second={Parent=Players,Neutral=false,Team=2,Character=character(20,0,100)}
local teammate={Parent=Players,Neutral=false,Team=1,Character=character(1,0,100)}
local protected={Parent=Players,Neutral=false,Team=2,Character=character(2,0,100,true)}
local dead={Parent=Players,Neutral=false,Team=2,Character=character(3,0,0)}
function Players:GetPlayers() return {LocalPlayer,teammate,protected,dead,enemy,second} end
local controller={}
function controller:GetFighter(player) return {Entity={Model=player.Character},Get=function() return 0 end} end
controller.LocalFighter=controller:GetFighter(LocalPlayer)
local function genericTeammates(a,b) return a~=b and not a.Neutral and not b.Neutral and a.Team==b.Team end
local function targetPart(entity) return entity.Model.Head end
local keyDown={}
local UIS={GetFocusedTextBox=function() return nil end,IsKeyDown=function(_,key) return keyDown[key] end,
    IsMouseButtonPressed=function() return false end}
local menu=false
local function anyMenuVisible() return menu end
local function loadApi() return true end
local function warn() end
local bindings,cleanup={},{}
local RunService={BindToRenderStep=function(_,name,_,fn) bindings[name]=fn end,
    UnbindFromRenderStep=function(_,name) bindings[name]=nil end}
local function track(connection) table.insert(cleanup,connection) end
local stopped=0
local weapon={FindFirstChild=function() return nil end}
local RivalsAim={Enabled=false,Aimbot={Enabled=false},Wallbang={Enabled=false},
    KillAll={Enabled=false,RetryTime=2,AimPart="Head",TeamCheck=true,CameraSpeed=45},
    StopAutoFire=function() stopped+=1 end,StartArsenalShotAdapter=function() return true end,
    ResolveArsenalModule=function() return {gun=weapon} end}
-- INSERT_KILL_CYCLE
-- INSERT_ENEMY_ELIGIBILITY
-- INSERT_DETACHED_VIEW
local originalFrame,originalSubject=camera.CFrame,camera.CameraSubject
RivalsAim.SetKillAll(true)
local mode=RivalsAim.KillAll
assert(mode.Enabled and camera.CameraType=="scriptable")
mode.Controller.Tick()
assert(mode.Controller.Target.Player==enemy,"closest live unprotected enemy was not selected")
assert(LocalPlayer.Character.Root.CFrame.Position.X==10 and LocalPlayer.Character.Root.CFrame.Position.Z==3,"character did not move behind enemy")
bindings.RiftArsenalDetachedView(1/60)
assert(camera.CFrame.Position.X==100 and camera.CFrame.Position.Z==100,"view followed teleported character")
keyDown.W=true;bindings.RiftArsenalDetachedView(1/60);keyDown.W=false
assert(camera.CFrame.Position.Z<100,"detached view could not move")
local viewZ=camera.CFrame.Position.Z
local rayState={Active=true,Transform=function(origin,direction,params) return direction,params end}
local RaycastParams={new=function() return {} end}
local Ray={new=function(origin,direction) return {Origin=origin,Direction=direction} end}
-- Simulate the engine updating the character's welded head after root movement.
LocalPlayer.Character.Head.Position=LocalPlayer.Character.Root.CFrame.Position+V.new(0,1.5,0)
-- INSERT_SHOT_FRAME
local shot=shotTransform({Origin=camera.CFrame.Position,Direction=V.new(0,0,100)}, {})
assert(shot.Origin==LocalPlayer.Character.Head.Position and camera.CFrame.Position==shot.Origin,"native firing frame still used detached view origin")
bindings.RiftArsenalDetachedView(1/60)
assert(camera.CFrame.Position.X==100 and camera.CFrame.Position.Z==viewZ,"physical shot frame leaked into rendered view")
enemy.Character.Humanoid.Health=0;mode.Controller.Tick()
assert(mode.Controller.Target.Player==second,"dead target was not skipped immediately")
RivalsAim.SetKillAll(false)
assert(camera.CameraType=="custom" and camera.CameraSubject==originalSubject and camera.CFrame==originalFrame)
assert(not mode.Enabled and stopped>0)
RivalsAim.SetKillAll(true)
for _,connection in ipairs(cleanup) do connection.Disconnect() end
assert(not bindings.RiftArsenalDetachedView and camera.CameraType=="custom" and not mode.Enabled,"unload left camera detached")
print("PASS Arsenal detached view: live/enemy/protected filters, behind-target movement, fixed/movable view, physical shot origin, target death, disable and unload restoration")
