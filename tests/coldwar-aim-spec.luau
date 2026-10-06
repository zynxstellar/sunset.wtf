-- The production handler is exercised against a native firing/ballistics fixture.
local meta={}
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},meta) end}
local Vector2={new=function(x,y) return Vector3.new(x,y,0) end}
function meta.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function meta.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function meta.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function meta.__index(a,k)
    if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=="Unit" then return a*(1/a.Magnitude) end
    if k=="Dot" then return function(_,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
    if k=="Cross" then return function(_,b) return Vector3.new(a.Y*b.Z-a.Z*b.Y,a.Z*b.X-a.X*b.Z,a.X*b.Y-a.Y*b.X) end end
end
local function typeof(v) return getmetatable(v)==meta and "Vector3" or type(v)=="table" and v.Kind or type(v) end
local function object(name,class,parent)
    local o={Name=name,Kind="Instance",ClassName=class,Parent=parent,Children={}}
    if parent then parent.Children[name]=o end
    function o:FindFirstChild(n) return self.Children[n] end
    function o:IsA(c) return self.ClassName==c end
    function o:FindFirstChildOfClass(c) for _,v in pairs(self.Children) do if v:IsA(c) then return v end end end
    function o:IsDescendantOf(p) return self.Parent==p end
    return o
end
local Settings={SelectedGame="Cold War"}
local ENV={Drawing={}}
local circles={}
function ENV.Drawing.new(kind)
    local o={Kind=kind,Remove=function(self) self.Removed=true self.Visible=false end}
    table.insert(circles,o) return o
end
local Color3={fromRGB=function(r,g,b) return {r,g,b} end}
local menu=false
local function anyMenuVisible() return menu end
local connections={}
local function track(c) table.insert(connections,c) end
local frame
local RunService={RenderStepped={Connect=function(_,f) frame=f return {Disconnect=function() end} end}}
local now=0
local os={clock=function() return now end}
local task={spawn=function(f) f() end}
local warnings={}
local function warn(v) table.insert(warnings,v) end
local controls={}
local AimTab,VisualsTab={Left={}},{Left={}}
local function gameSection(scope,column,name) return scope.."/"..name end
local Elements={}
local function control(section,name,value,fn)
    local c={Value=value,Set=function(self,v) self.Value=v fn(v) end}
    controls[section.."/"..name]=c return c
end
function Elements.Toggle(s,n,d,f) return control(s,n,d,f) end
function Elements.Dropdown(s,n,items,d,f) return control(s,n,d,f) end
function Elements.Slider(s,n,min,max,d,units,f) return control(s,n,d,f) end
local workspace={Children={},CurrentCamera={ViewportSize=Vector2.new(1920,1080)}}
function workspace.CurrentCamera:WorldToViewportPoint(p) return Vector3.new(960+p.X,540-p.Y,p.Z),p.Z>0 end
local wall,raycasts,rayFailure=nil,0,false
function workspace:Raycast(o,d,params)
    assert(params.Sentinel=="native collision params")
    raycasts+=1
    if rayFailure then error("cast failed") end
    return wall and {Instance=wall} or nil
end
local LocalPlayer=object("Me","Player")
LocalPlayer.Team={Name="NATO"}
local roster={LocalPlayer}
local Players={GetPlayers=function() return roster end}
local function player(name,team,x,z)
    local p=object(name,"Player") p.Team={Name=team}
    p.Character=object(name,"Model",workspace)
    for _,spec in ipairs({{"Head",3},{"Torso",0},{"HumanoidRootPart",0}}) do
        local part=object(spec[1],"BasePart",p.Character)
        part.Position=Vector3.new(x,spec[2],z) part.AssemblyLinearVelocity=Vector3.new()
    end
    table.insert(roster,p) return p
end
local enemy=player("Enemy","PACT",10,100)
local ally=player("Ally","NATO",0,50)
local spectator=player("Spectator","Lobby",0,30)
local function model(p) return p~=LocalPlayer and not p.Dead and p.Character or nil end
local ReplicatedStorage=object("RS","Folder")
local ballistics=object("Ballistics","Folder",object("Shared","Folder",ReplicatedStorage))
local tm=object("Trajectory","ModuleScript",ballistics)
local wm=object("WeaponSource","ModuleScript",object("Sources","Folder",ballistics))
local cm=object("ClientFire","ModuleScript",object("BallisticsClient","Folder",object("PlayerScripts","Folder",LocalPlayer)))
local params={Weapon={MuzzleSpeed=1000,K=0,Explosive=false},RaycastParams={Sentinel="native collision params"}}
local gravity=0
tm.Export={new=function(data) data.Gravity=gravity return data end,
    GetTimeForDistance=function(tr,d) return d/tr.MuzzleSpeed end,
    GetPositionAtTime=function(tr,t) return tr.Origin+tr.Direction*(tr.MuzzleSpeed*t)-Vector3.new(0,gravity*0.5*t*t,0) end}
local fp
wm.Export={toFireParams=function(data) fp=data return params end}
local calls,received,nativeFailure=0,nil,false
local function native(...)
    calls+=1 received=table.pack(...)
    if nativeFailure then error("native failure") end
    return "native",nil,42
end
cm.Export={fire=function() error("low-level fire must not be replaced") end,volley=native}
local loaded=false
local requireCalls=0
local identity=8
local function getthreadidentity() return identity end
local function setthreadidentity(v) identity=v end
local requireFailure=false
local function rivalsModuleLoaded() return loaded end
local function require(m)
    requireCalls+=1 assert(identity==2)
    if requireFailure then error("require failed") end
    return m.Export
end
-- INSERT_COLDWAR_AIM_PRODUCTION
Settings.SetupColdWarAim(model)
local aim=Settings.ColdWarAim
assert(requireCalls==0 and cm.Export.volley==native,"injection initialized weapon modules")
aim.SetEnabled(true)
assert(not aim.Available and requireCalls==0 and identity==8,"unready modules were required")
loaded=true now=2 frame()
assert(aim.Available and cm.Export.volley~=native and identity==8,"late-ready install failed")
local tool=object("Rifle","Tool")
local origin=Vector3.new()
local directions={Vector3.new(0,0,1),Vector3.new(0.03,0.01,1),Metadata="native metadata"}
local function fire(opts)
    return table.pack(cm.Export.volley(tool,2,3,origin,directions,opts,"extra",nil,9))
end
for _=1,3 do
    local result=fire()
    assert(result.n==3 and result[1]=="native" and result[2]==nil and result[3]==42)
    assert(received.n==9 and received[6]==nil and received[7]=="extra" and received[9]==9)
    assert(received[5]~=directions and received[5].Metadata=="native metadata")
    assert(received[5][1]:Dot((enemy.Character:FindFirstChild("Head").Position-origin).Unit)>0.99999)
    assert(math.abs(received[5][2].Magnitude-directions[2].Magnitude)<1e-6,"pellet magnitude changed")
    assert(math.abs(received[5][1]:Dot(received[5][2])-directions[1]:Dot(directions[2]))<1e-6,"spread changed")
end
assert(calls==3 and directions[1].X==0 and fp.Owner==LocalPlayer and fp.MuzzleIndex==2 and fp.BulletIndex==3)
controls["Cold War/Silent Aim/Aim Part"]:Set("Torso") fire()
assert(received[5][1].Y==0,"torso selection ignored")
aim.AimPart="Head" gravity=100 fire()
assert(received[5][1].Y>(enemy.Character.Children.Head.Position-origin).Unit.Y,"drop compensation missing")
gravity=0 enemy.Character.Children.HumanoidRootPart.AssemblyLinearVelocity=Vector3.new(20,0,0)
fire() assert(received[5][1].X>(enemy.Character.Children.Head.Position-origin).Unit.X,"movement lead missing")
enemy.Character.Children.HumanoidRootPart.AssemblyLinearVelocity=Vector3.new()
wall=object("Wall","BasePart",workspace)
fire() assert(received[5]==directions,"wall check bent a blocked shot")
aim.WallCheck=false fire() assert(received[5]~=directions)
aim.WallCheck=true wall=nil
aim.Radius=5 fire() assert(received[5]==directions,"FOV exclusion failed")
aim.Radius=150 aim.MaxDistance=25 fire() assert(received[5]==directions,"range exclusion failed")
aim.MaxDistance=1000 enemy.Dead=true fire() assert(received[5]==directions,"dead player targeted") enemy.Dead=false
local force=object("Shield","ForceField",enemy.Character)
fire() assert(received[5]==directions,"spawn shield ignored") enemy.Character.Children.Shield=nil
local values=object("CharacterValues","Folder",enemy.Character)
object("Unconscious","BoolValue",values).Value=true
fire() assert(received[5]==directions,"downed target selected") values.Children.Unconscious.Value=false
menu=true fire() assert(received[5]==directions) menu=false
fire({Replay=true}) assert(received[5]==directions,"non-native options altered")
params.Weapon.Explosive=true fire() assert(received[5]==directions) params.Weapon.Explosive=false
rayFailure=true fire() assert(received[5]==directions,"resolver error suppressed normal firing") rayFailure=false
nativeFailure=true local ok,err=pcall(fire) assert(not ok and tostring(err):find("native failure")) nativeFailure=false
aim.FOVVisible=true frame()
assert(circles[1].Visible and circles[1].Radius==150 and circles[1].Position.X==960)
menu=true frame() assert(not circles[1].Visible) menu=false
aim.SetEnabled(false) assert(cm.Export.volley==native,"disable did not restore volley")
requireFailure=true aim.SetEnabled(true) assert(identity==8 and cm.Export.volley==native)
requireFailure=false now=4 frame() assert(aim.Available)
local foreign=function() end cm.Export.volley=foreign
aim.SetEnabled(false) assert(cm.Export.volley==foreign,"foreign replacement was overwritten") cm.Export.volley=native
cm.Export.extra=function() end aim.SetEnabled(true)
assert(cm.Export.volley==native and not aim.Available,"ambiguous module was patched") cm.Export.extra=nil
now=6 frame() assert(aim.Available)
ENV.SunsetColdWarAimHook.Restore()
assert(cm.Export.volley==native and circles[1].Removed and not aim.Enabled)
aim.SetEnabled(true) frame() assert(cm.Export.volley==native,"unloaded handler recreated")
Settings.SetupColdWarAim(model) local replacement=Settings.ColdWarAim replacement.SetEnabled(true)
local first=cm.Export.volley
Settings.SetupColdWarAim(model)
assert(cm.Export.volley==native and not replacement.Enabled,"reinjection stacked handlers")
print("PASS Cold War Silent Aim: deferred/loaded modules and identity, repeated native calls/returns/errors, spread/input preservation, drop/lead, teams/death/shields/downed/FOV/range/walls/menu, options/errors pass through, disable/unload/reinjection and foreign handler ownership")
