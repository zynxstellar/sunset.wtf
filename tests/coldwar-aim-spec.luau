-- The production handler is exercised against a native firing/ballistics fixture.
local math=table.clone(math)
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
local SUNSET_BUILD="test-k276"
local messages={}
local function print(message) table.insert(messages,message) end
local ENV={Drawing={}}
local circles={}
function ENV.Drawing.new(kind)
    local o={Kind=kind,Remove=function(self) self.Removed=true self.Visible=false end}
    table.insert(circles,o) return o
end
local Color3={fromRGB=function(r,g,b) return {r,g,b} end}
local menu=false
local firingContext=false
local function anyMenuVisible()
    assert(not firingContext,"The current thread cannot access 'Instance' (lacking capability Plugin)")
    return menu
end
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
function Elements.Button(s,n,f) controls[s.."/"..n]={Click=f} end
local workspace={Children={},CurrentCamera={ViewportSize=Vector2.new(1920,1080),CFrame={Position=Vector3.new(0,0,-1)}}}
function workspace:FindFirstChild(name) return self.Children[name] end
local Enum={RaycastFilterType={Exclude="Exclude"}}
local RaycastParams={new=function() return {} end}
function workspace.CurrentCamera:WorldToViewportPoint(p) return Vector3.new(960+p.X,540-p.Y,p.Z),p.Z>0 end
local wall,raycasts,rayFailure=nil,0,false
local headWall=false
local collisionTarget
local directWall,muzzleWall=false,false
function workspace:Raycast(o,d,params)
    assert(params.Sentinel=="native collision params" or params.FilterType=="Exclude")
    raycasts+=1
    if rayFailure then error("cast failed") end
    if wall then return {Instance=wall} end
    if not params.Sentinel and (directWall or (muzzleWall and o.Z==0)) then
        return {Instance=object("Cover","BasePart",workspace)}
    end
    if headWall and d.Y>0.001 then return {Instance=object("Wall","BasePart",workspace)} end
    if collisionTarget and o.Z<=100 and o.Z+d.Z>=100 and d.Z>0 then
        local point=o+d*((100-o.Z)/d.Z)
        for _,name in ipairs({"Head","Torso"}) do
            local part=collisionTarget.Children[name]
            if math.abs(point.X-part.Position.X)<1 and math.abs(point.Y-part.Position.Y)<1 then return {Instance=part} end
        end
    end
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
collisionTarget=enemy.Character
local ally=player("Ally","NATO",0,50)
local spectator=player("Spectator","Lobby",0,30)
local function model(p) return p~=LocalPlayer and not p.Dead and p.Character or nil end
-- Do not supply a ReplicatedStorage variable: Roblox only exposes this service
-- through game:GetService. The old fixture masked a production nil reference.
local storage=object("RS","Folder")
local serviceCalls=0
local game={GetService=function(_,name)
    assert(name=="ReplicatedStorage") serviceCalls+=1 return storage
end}
local ballistics=object("Ballistics","Folder",object("Shared","Folder",storage))
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
local nativeYield=false
local function native(...)
    calls+=1 received=table.pack(...)
    if nativeFailure then error("native failure") end
    if nativeYield then
        assert(coroutine.yield("native waiting")=="continue firing","native continuation changed")
    end
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
assert(ENV.RiftCheckSilentAim==nil and aim.Check==nil,"removed diagnostic remains available")
assert(requireCalls==0 and cm.Export.volley==native,"injection initialized weapon modules")
aim.SetEnabled(true)
assert(not aim.Available and requireCalls==0 and identity==8,"unready modules were required")
loaded=true now=2 frame()
assert(aim.Available and cm.Export.volley~=native and identity==8,"late-ready install failed")
assert(serviceCalls>0,"Cold War did not resolve storage through the Roblox service API")
assert(controls["Cold War/Silent Aim/Check Silent Aim"]==nil,"removed diagnostic button remains")
local tool=object("Rifle","Tool")
local origin=Vector3.new()
local _,_,resolvedModel,resolvedPart=aim.Resolve(object("Rifle","Tool"),2,3,origin,Vector3.new(0,0,1))
assert(resolvedModel==enemy.Character and resolvedPart==enemy.Character:FindFirstChild("Head"),
    "Auto Shoot did not receive the selected model and part for its ground check")
local directions={Vector3.new(0,0,1),Vector3.new(0.03,0.01,1),Metadata="native metadata"}
local readonlyDirections=false
local function fire(opts)
    directions={Vector3.new(0,0,1),Vector3.new(0.03,0.01,1),Metadata="native metadata"}
    if readonlyDirections then table.freeze(directions) end
    firingContext=true
    local results=table.pack(pcall(cm.Export.volley,tool,2,3,origin,directions,opts,"extra",nil,9))
    firingContext=false
    if not results[1] then error(results[2],0) end
    return table.pack(table.unpack(results,2,results.n))
end
for _=1,3 do
    local result=fire()
    assert(result.n==3 and result[1]=="native" and result[2]==nil and result[3]==42)
    assert(received.n==9 and received[6]==nil and received[7]=="extra" and received[9]==9)
    assert(received[5]==directions and received[5].Metadata=="native metadata","reference volley array identity/metadata changed")
    assert(received[5][1]:Dot((enemy.Character:FindFirstChild("Head").Position-origin).Unit)>0.99999)
    assert(received[5][2]==received[5][1],"reference volley directions were not updated together")
end
assert(calls==3 and fp.Owner==LocalPlayer and fp.MuzzleIndex==2 and fp.BulletIndex==3)
assert(aim.Diagnostics.Shots==3 and aim.Diagnostics.Redirected==3,"firing counters did not observe shots")
assert(controls["Cold War/Instant Hit/Instant Hit"]==nil,"removed Instant Hit toggle remains")
aim.HitChance=0
fire()
assert(directions[1].X==0 and received[5]==directions,"zero chance redirected or replaced a native shot")
assert(aim.Diagnostics.LastReason:find("Hit Chance"),"chance skip was not recorded")
aim.HitChance=100
fire()
assert(directions[1].X>0,"full chance skipped an eligible shot")
local originalRandom=math.random
local rolls=0
math.random=function() rolls+=1 return 0.49 end
aim.HitChance=50 fire()
assert(rolls==1 and directions[1].X>0 and directions[2]==directions[1],"chance was not rolled once per volley")
math.random=function() rolls+=1 return 0.5 end
fire() assert(rolls==2 and directions[1].X==0,"chance boundary redirected a skipped shot")
math.random=originalRandom aim.HitChance=100
nativeYield=true
local firingThread=coroutine.create(function()
    for _=1,3 do
        local result=fire()
        assert(result.n==3 and result[1]=="native" and result[2]==nil and result[3]==42)
    end
end)
for _=1,3 do
    local ok,waiting=coroutine.resume(firingThread,"continue firing")
    assert(ok and waiting=="native waiting","repeated native firing could not yield")
end
assert(coroutine.resume(firingThread,"continue firing"))
assert(coroutine.status(firingThread)=="dead","native firing continuation stuck after first bullet")
nativeYield=false
controls["Cold War/Silent Aim/Aim Part"]:Set("Torso") fire()
assert(received[5][1].Y==0,"torso selection ignored")
aim.AimPart="Head" gravity=100 fire()
assert(received[5][1].Y>(enemy.Character.Children.Head.Position-origin).Unit.Y,"drop compensation missing")
gravity=0 enemy.Character.Children.HumanoidRootPart.AssemblyLinearVelocity=Vector3.new(20,0,0)
fire() assert(received[5][1].X>(enemy.Character.Children.Head.Position-origin).Unit.X,"movement lead missing")
enemy.Character.Children.HumanoidRootPart.AssemblyLinearVelocity=Vector3.new()
wall=object("Wall","BasePart",workspace)
fire() assert(directions[1].X==0,"wall check bent a blocked shot")
aim.Wallbang=true fire() assert(directions[1].X==0,"nonpenetrating weapon bent a blocked shot")
params.Weapon.PenetrationPower=10
fire() assert(directions[1].X==0,"penetrating weapon bypassed mandatory visibility")
aim.WallCheck=false
local strictDirection=aim.Resolve(tool,2,3,origin,Vector3.new(0,0,1),true)
assert(strictDirection==nil,"Auto Shoot strict path accepted blocked target")
aim.WallCheck=true
aim.Wallbang=false fire() assert(directions[1].X==0,"disabled wallbang redirected through cover")
aim.WallCheck=false fire() assert(directions[1].X==0,"saved wall-check setting bypassed mandatory visibility")
aim.WallCheck=true wall=nil
directWall=true fire() assert(directions[1].X==0,"native collision filter bypassed direct-view cover")
directWall=false muzzleWall=true fire() assert(directions[1].X==0,"blocked muzzle redirected at a visible player")
muzzleWall=false
enemy.Team={Name="NATO"}
fire() assert(directions[1].X==0,"same-name teammate targeted")
enemy.Team=LocalPlayer.Team
fire() assert(directions[1].X==0,"same-team teammate targeted")
enemy.Team=nil
fire() assert(directions[1].X==0,"player without a combat team targeted")
enemy.Team={Name="PACT"}
fire() assert(directions[1].X>0,"eligible enemy was not restored")
headWall=true
aim.TargetVisiblePart=true fire()
assert(directions[1].Y==0,"visible torso was not chosen when head was blocked")
controls["Cold War/Silent Aim/Target Visible Part"]:Set(false)
fire() assert(directions[1].X==0,"selected head was bypassed with visible-part fallback disabled")
headWall=false
controls["Cold War/Silent Aim/Target Visible Part"]:Set(true)
aim.Radius=5 fire() assert(directions[1].X==0,"FOV exclusion failed")
assert(aim.Diagnostics.LastReason:find("FOV"),"FOV failure missing from diagnostic")
enemy.Character.Children.Torso.Size=Vector3.new(2,4,1)
fire() assert(directions[1].X>0,"body overlap inside the FOV circle was ignored")
enemy.Character.Children.Torso.Size=nil
aim.Radius=150 aim.MaxDistance=25 fire() assert(directions[1].X==0,"range exclusion failed")
aim.MaxDistance=1000 enemy.Dead=true fire() assert(directions[1].X==0,"dead player targeted") enemy.Dead=false
local force=object("Shield","ForceField",enemy.Character)
fire() assert(directions[1].X==0,"spawn shield ignored") enemy.Character.Children.Shield=nil
local values=object("CharacterValues","Folder",enemy.Character)
object("Unconscious","BoolValue",values).Value=true
fire() assert(directions[1].X==0,"downed target selected") values.Children.Unconscious.Value=false
menu=true frame() fire() assert(directions[1].X==0) menu=false frame()
fire({Replay=true}) assert(directions[1].X==0,"non-native options altered")
params.Weapon.Explosive=true fire() assert(directions[1].X==0) params.Weapon.Explosive=false
rayFailure=true fire() assert(directions[1].X==0,"resolver error suppressed normal firing") rayFailure=false
assert(aim.Diagnostics.Errors>0 and aim.Diagnostics.LastReason:find("cast failed"),"resolver error was hidden from diagnostic")
readonlyDirections=true fire()
assert(directions[1].X==0 and aim.Enabled,"read-only native array blocked normal firing") readonlyDirections=false
local beforeFailure=calls
nativeFailure=true local ok,err=pcall(fire) assert(not ok and tostring(err):find("native failure")) nativeFailure=false
assert(calls==beforeFailure+1 and aim.Enabled,"native error caused duplicate firing or changed module state")
aim.SetEnabled(false)
fire() assert(directions[1].X==0,"disable did not restore native firing after failure")
local recorded=0
Settings.ColdWarBulletTrails={Enabled=true,Record=function(t,m,b,o,ds)
    recorded+=1 assert(t==tool and m==2 and b==3 and o==origin and ds==directions)
end}
aim.SetEnabled(false)
local observer=cm.Export.volley
assert(observer~=native,"trails required Silent Aim enabled")
aim.SetEnabled(false) assert(cm.Export.volley==observer,"trail toggle stacked a firing wrapper")
fire() assert(recorded==1 and directions[1].X==0,"trail-only observer altered native shot")
Settings.ColdWarBulletTrails.Enabled=false aim.SetEnabled(false)
assert(cm.Export.volley==native,"disabling both features left a firing wrapper")
Settings.ColdWarBulletTrails=nil
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
assert(ENV.RiftCheckSilentAim==nil,"unload left a stale diagnostic shortcut")
aim.SetEnabled(true) frame() assert(cm.Export.volley==native,"unloaded handler recreated")
Settings.SetupColdWarAim(model) local replacement=Settings.ColdWarAim replacement.SetEnabled(true)
local first=cm.Export.volley
Settings.SetupColdWarAim(model)
assert(cm.Export.volley==native and not replacement.Enabled,"reinjection stacked handlers")
print("PASS Cold War Silent Aim: deferred modules, native array update and ballistic landing, repeated yielding calls with UI permission denied in weapon thread, drop/lead, target filters, read-only arrays, native errors, disable/unload/reinjection")
