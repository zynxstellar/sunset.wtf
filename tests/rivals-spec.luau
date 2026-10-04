-- Execute the production Rivals/menu/board functions with isolated engine mocks.
local function signal()
    local handlers = {}
    return {
        Connect = function(_, fn)
            table.insert(handlers, fn)
            return { Disconnect = function() end }
        end,
        Fire = function(_, ...)
            for _, fn in ipairs(handlers) do fn(...) end
        end,
    }
end
local Enum = setmetatable({}, {__index=function(t,k)
    local group=setmetatable({}, {__index=function(g,n) rawset(g,n,n) return n end})
    rawset(t,k,group) return group
end})
local vectors={}
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectors) end}
local Vector2={new=function(x,y) return Vector3.new(x,y,0) end}
function vectors.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function vectors.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function vectors.__index(a,k)
    if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=="Unit" then return a*(1/a.Magnitude) end
    if k=="Dot" then return function(_,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
end
local function color(r,g,b)
    return {R=r,G=g,B=b,Lerp=function(self) return self end,ToHSV=function() return 0,1,1 end}
end
local Color3={new=color,fromRGB=function(r,g,b) return color(r/255,g/255,b/255) end}
local UDim={new=function(s,o) return {Scale=s,Offset=o} end}
local UDim2={new=function(xs,xo,ys,yo) return {X=UDim.new(xs,xo),Y=UDim.new(ys,yo)} end}
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local ColorSequence={new=function(v) return v end}
local ColorSequenceKeypoint={new=function(t,c) return {Time=t,Value=c} end}
local TweenInfo={new=function() return {} end}
local TweenService={Create=function() return {Play=function() end,Cancel=function() end,
    Destroy=function() end,Completed=signal()} end}
local Ray={new=function(o,d) return {Origin=o,Direction=d,_type="Ray"} end}
local CFrame={}
local frameMeta={}
function CFrame.new(p,y,z)
    if type(p)=="number" then p=Vector3.new(p,y,z) end
    return setmetatable({Position=p or Vector3.new(),_type="CFrame",Angles={0,0,0},ToObjectSpace=function(self,other)
        return CFrame.new(other.Position-self.Position)
    end,ToOrientation=function(self) return table.unpack(self.Angles) end},frameMeta)
end
function CFrame.fromOrientation(x,y,z)
    local f=CFrame.new()
    f.Angles={x,y,z}
    f.LookVector=Vector3.new(-math.sin(y)*math.cos(x),math.sin(x),-math.cos(y)*math.cos(x))
    return f
end
function frameMeta.__mul(a,b)
    local f=CFrame.fromOrientation(table.unpack(b.Angles))
    f.Position=a.Position
    return f
end
function CFrame.lookAt(p,target)
    local direction=(target-p).Unit
    local frame=CFrame.fromOrientation(math.asin(direction.Y),math.atan2(-direction.X,-direction.Z),0)
    frame.Position=p
    return frame
end
local function typeof(v)
    if getmetatable(v)==vectors then return "Vector3" end
    return type(v)=="table" and v._type or type(v)
end
local task={defer=function(fn) fn() end}
function task.spawn(fn,...)
    local co=coroutine.create(fn)
    local ok,err=coroutine.resume(co,...)
    assert(ok,err)
end
function task.wait() coroutine.yield() end
local created={}
local function new(class,props,parent)
    local obj={ClassName=class,Name=class,Visible=true,Text="",TextSize=13,
        Size=UDim2.fromOffset(0,0),Position=UDim2.fromOffset(0,0),BackgroundTransparency=0,
        AbsoluteSize=Vector2.new(200,30),AbsolutePosition=Vector2.new(0,0),TextBounds=Vector2.new(80,18),
        children={},attributes={},signals={}}
    for k,v in pairs(props or {}) do obj[k]=v end
    obj.Parent=parent
    if parent then table.insert(parent.children,obj) end
    function obj:IsA(kind)
        return kind==self.ClassName or (kind=="GuiObject" and table.find(
            {"Frame","TextLabel","TextButton","TextBox","ScrollingFrame","ImageLabel"},self.ClassName)~=nil)
    end
    function obj:GetChildren() return self.children end
    function obj:GetDescendants()
        local result={}
        local function visit(n) for _,c in ipairs(n.children) do table.insert(result,c) visit(c) end end
        visit(self) return result
    end
    function obj:FindFirstChildOfClass(kind)
        for _,c in ipairs(self.children) do if c:IsA(kind) then return c end end
    end
    function obj:GetAttribute(k) return self.attributes[k] end
    function obj:SetAttribute(k,v) self.attributes[k]=v end
    function obj:GetPropertyChangedSignal(k)
        self.signals[k]=self.signals[k] or signal() return self.signals[k]
    end
    function obj:Destroy() self.Parent=nil end
    for _,k in ipairs({"MouseButton1Click","MouseButton2Click","MouseEnter","MouseLeave","FocusLost"}) do obj[k]=signal() end
    table.insert(created,obj)
    return obj
end
local function label(parent,text,size,c) return new("TextLabel",{Text=text,TextSize=size or 13,TextColor3=c},parent) end
local function border(parent,c) return new("UIStroke",{Color=c},parent) end
local function riftAsset() return nil end
local function riftTrashFallback() end
local function makeDraggable() end
local connections={}
local function track(c) table.insert(connections,c) return c end
local RunService={Heartbeat=signal(),RenderStepped=signal()}
local Gui=new("ScreenGui",{},nil)
Gui.Parent=true
local PlayerGui=new("Folder",{},nil)
local Window={Visible=false}
local BedWarsUI,RivalsUI
local Settings={SelectedGame="Rivals",MenuBlurOn=true,ModuleListOn=true,SetMenuBlur=function() end}
local Camera={CameraType="Custom",CFrame=CFrame.new(Vector3.new()),ViewportSize=Vector2.new(1920,1080)}
Camera.CFrame.LookVector=Vector3.new(0,0,1)
local workspace={CurrentCamera=Camera}
local RaycastParams={new=function() return {} end}
local raycastResult,raycastFailure,casts=nil,false,{}
function workspace:Raycast(origin,direction,params)
    if raycastFailure then error("raycast unavailable") end
    table.insert(casts,{Origin=origin,Direction=direction,Params=params})
    if type(raycastResult)=="function" then return raycastResult(origin,direction,params) end
    return raycastResult
end
local mouse={}
local LocalPlayer={CameraMode="LockFirstPerson",GetMouse=function() return mouse end,
    GetAttribute=function() return 1 end}
local Players={GetPlayers=function() return {LocalPlayer} end}
local UIS={MouseBehavior="LockCenter",MouseIconEnabled=false,TouchEnabled=false,
    IsMouseButtonPressed=function() return false end,GetMouseLocation=function() return Vector2.new(100,100) end}
local ENV={}
local useScriptable=true
local function anyMenuVisible() return Window.Visible or RivalsUI and RivalsUI.Visible or false end
local RivalsAim={Enabled=false,FOVVisible=false,Radius=150,AimPart="Head",WallCheck=true}
local BedWars={KitCatalog=function() error("Rivals must not read BedWars kit modules") end}
local Persistence={HUDFrames={}}
local ConfigControls,gameSections,Tabs={},{},{}
local AimTab={Left=new("Frame",{},nil)}
local VisualsTab={Left=new("Frame",{},nil)}
local SettingsTab={Left=new("Frame",{},nil)}
Tabs.Combat={Left=AimTab.Left,Right=new("Frame",{},nil)}
Tabs.Visuals={Left=VisualsTab.Left,Right=new("Frame",{},nil)}
Tabs.Sunset={Left=SettingsTab.Left,Right=new("Frame",{},nil)}
local function gameSection(gameName,column,title)
    local box=new("Frame",{},column)
    box:SetAttribute("SunsetGame",gameName)
    label(box,title)
    local content=new("Frame",{AutomaticSize=Enum.AutomaticSize.Y},box)
    content.game,content.section=gameName,title
    for name,tab in pairs(Tabs) do if tab.Left==column then content.tab=name end end
    table.insert(gameSections,{Game=gameName,Box=box})
    return content
end
local Elements={}
local function addControl(parent,text,kind,default,callback)
    local value=default
    local row=new("Frame",{},parent)
    local c={Kind=kind,Key=parent.tab.."/"..parent.game.."/"..parent.section.."/"..text,
        Box=parent.Parent,Row=row,Get=function() return value end}
    c.Set=function(v) value=v callback(v) end
    table.insert(ConfigControls,c)
    return c
end
function Elements.Toggle(p,t,d,cb)
    local c=addControl(p,t,"toggle",d,cb)
    new("Frame",{Size=UDim2.fromOffset(12,12)},c.Row)
    label(c.Row,t)
    new("TextButton",{Visible=true,Text="-"},c.Row)
    return c
end
function Elements.Slider(p,t,a,b,d,s,cb)
    local c=addControl(p,t,"number",d,cb)
    c.Min,c.Max=a,b
    return c
end
function Elements.Dropdown(p,t,options,d,cb)
    local c=addControl(p,t,"choice",d,cb)
    c.Options=options
    return c
end
Elements.Label=label
local BRAND,SUNSET_BUILD="RIFT","test-k259"
local hooks,hookInstalls,originalCalls={},0,{}
local currentMethod="Raycast"
local caller=false
local checkcaller=function() return caller end
local getnamecallmethod=function() return currentMethod end
local newcclosure=function(fn) return fn end
local hookmetamethod=function(_,name,fn)
    hookInstalls+=1
    local previous=hooks[name] or function(self,...)
        table.insert(originalCalls,{Self=self,Args=table.pack(...)})
        if name=="__index" then return "original property" end
        return "original result",nil,"third result"
    end
    hooks[name]=fn
    return previous
end

-- Native Gun contract observed in Dex: two calls per shot (packet and tracers),
-- encoded CFrame/hit-part fields, and five return slots including nils.
local packet={[utf8.char(0)]=CFrame.new(Vector3.new(0,0,0)),
    [utf8.char(1)]=CFrame.new(Vector3.new(0,1,0)),Other="keep"}
local cameraCalls,shots,tracer,shotArgs=0,0,nil,nil
local networkPacket
local nativeCamera=function(self,...)
    cameraCalls+=1
    self.CameraArgs=table.pack(...)
    return networkPacket and select(3,...)~=true and networkPacket or packet,nil,"camera-extra"
end
local fighterPrototype={GetCameraData=nativeCamera}
local localFighter=setmetatable({IsLocalPlayer=true,
    Get=function() return "arena" end,
    GetRaycastWhitelist=function() return {"native arena"} end},{__index=fighterPrototype})
local controller={LocalFighter=localFighter,GetFighter=function(_,p) return p.Fighter end}
local gun={StartShooting=function(item,...)
    shots+=1
    shotArgs=table.pack(...)
    local data=item.ClientFighter:GetCameraData()
    if item.BetweenQueries then item.BetweenQueries() end
    tracer=item.ClientFighter:GetCameraData("whitelist","spread",true)
    if item.Fail then error("native gun error") end
    if item.Blocked then return false end
    return true,"StartShooting",data,nil,shotArgs[2]
end}
local nativeShot=gun.StartShooting
local scripts=new("Folder",{},nil)
function scripts:FindFirstChild(name)
    return {FindFirstChild=function(_,child)
        if name=="Controllers" and child=="FighterController" then return controller end
        if name=="Modules" and child=="ItemTypes" then
            return {FindFirstChild=function(_,n) if n=="Gun" then return gun end end}
        end
    end}
end
function LocalPlayer:FindFirstChild(name) if name=="PlayerScripts" then return scripts end end
local identity,requireFailure=8,false
local getthreadidentity=function() return identity end
local setthreadidentity=function(value) identity=value end
local require=function(module)
    assert(identity==2,"Cannot require a non-RobloxScript module from a RobloxScript")
    if requireFailure then error("module initialization failed") end
    return module
end
local function combatPlayer(team,x,health,environment)
    local model=new("Model",{},nil)
    model.Parent=workspace
    local head=new("BasePart",{Name="Head",Position=Vector3.new(x,0,100)},model)
    head.CFrame=CFrame.new(head.Position)
    local torso=new("BasePart",{Name="UpperTorso",Position=Vector3.new(x,1,100)},model)
    local root=new("BasePart",{Name="HumanoidRootPart",Position=Vector3.new(x,2,100)},model)
    torso.CFrame,root.CFrame=CFrame.new(torso.Position),CFrame.new(root.Position)
    new("Humanoid",{Health=health or 100},model)
    function model:FindFirstChild(name)
        for _,c in ipairs(self.children) do if c.Name==name then return c end end
    end
    function model:IsDescendantOf(parent) return self.Parent==parent end
    function head:IsDescendantOf(parent) return parent==model or parent==workspace end
    torso.IsDescendantOf,root.IsDescendantOf=head.IsDescendantOf,head.IsDescendantOf
    return {Character={},GetAttribute=function() return team end,
        Fighter={Entity={Model=model,RootPart=head},Get=function() return environment or "arena" end}},head
end
function Camera:WorldToViewportPoint(position)
    return Vector3.new(960+position.X,540,position.Z),true
end

-- INSERT_RIVALS_PRODUCTION

local search={Text="test",ReleaseFocus=function(self) self.released=true end,
    CaptureFocus=function() error("Menu opening must not capture keyboard focus") end}
Settings.ActiveSearchBox=search
Window.Visible=true
onMenuVisibility()
assert(LocalPlayer.CameraMode=="LockFirstPerson" and Camera.CameraType=="Custom")
assert(UIS.MouseBehavior=="Default" and UIS.MouseIconEnabled)
onMenuVisibility() -- Repeated notifications must not overwrite the saved locked state.
Window.Visible=false
onMenuVisibility()
assert(UIS.MouseBehavior=="LockCenter" and UIS.MouseIconEnabled==false)
assert(search.released and search.Text=="")
Window.Visible=true
onMenuVisibility()
restoreMenuInput()
assert(UIS.MouseBehavior=="LockCenter" and UIS.MouseIconEnabled==false,"unload did not restore mouse")
Window.Visible=false
UIS.MouseBehavior="Default"
UIS.MouseIconEnabled=true
Window.Visible=true
onMenuVisibility()
rememberGameInput("MouseBehavior","LockCenter")
rememberGameInput("MouseIconEnabled",false)
Window.Visible=false
onMenuVisibility()
assert(UIS.MouseBehavior=="LockCenter" and UIS.MouseIconEnabled==false,
    "menu ignored new mouse state requested by the game while open")
print("PASS Rivals input: first-person camera preserved, focus released, mouse restored on close/unload")

requireFailure=true
RivalsAim.Setup()
assert(not RivalsAim.Available and identity==8,"failed require leaked game script identity")
requireFailure=false
RivalsAim.Setup()
assert(RivalsAim.Available and identity==8,"game module load failed or did not restore identity")
assert(hookInstalls==0 and gun.StartShooting==nativeShot,"disabled aim patched a game method")
RivalsAim.SetEnabled(true)
assert(RivalsAim.Enabled and hookInstalls==0)
local state=ENV.SunsetRivalsAimHook
local enemy,target=combatPlayer(2,30)
local ally=combatPlayer(1,0)
local dead=combatPlayer(2,0,0)
local elsewhere=combatPlayer(2,0,100,"other arena")
Players.GetPlayers=function() return {LocalPlayer,ally,dead,elsewhere,enemy} end
local item={ClientFighter=localFighter,Info={IsRaycast=true}}
raycastResult={Instance=target,Position=target.Position-Vector3.new(0,0,0.5)}
for i=1,15 do
    local result=table.pack(gun.StartShooting(item,nil,"last",nil))
    assert(result.n==5 and result[1] and result[2]=="StartShooting" and result[4]==nil and result[5]=="last")
    assert(shotArgs.n==3 and shotArgs[1]==nil and shotArgs[3]==nil)
    assert(result[3][utf8.char(2)]==target and tracer[utf8.char(2)]==target,
        "packet and tracer did not select the actual enemy fighter model")
    assert(result[3].Other=="keep" and packet[utf8.char(2)]==nil,"rewriter mutated native packet")
    local origin=result[3][utf8.char(0)]
    assert(origin.Position==packet[utf8.char(0)].Position,"rewriter changed the native origin position")
    assert(origin.LookVector:Dot((target.Position-origin.Position).Unit)>0.9999,
        "shot frame stayed at the crosshair while the tracer frame moved")
    assert(result[3][utf8.char(1)].Position==packet[utf8.char(1)].Position)
    local view=result[3][utf8.char(1)]
    assert(view.LookVector:Dot((target.Position-view.Position).Unit)>0.9999)
    assert(result[3][utf8.char(3)].Position.Z==-0.5,"hit offset lost the actual surface collision")
end
assert(shots==15 and cameraCalls==30,"aim duplicated or dropped native firing calls")
raycastResult=nil
local noHit=select(3,gun.StartShooting(item))
assert(noHit~=packet and noHit[utf8.char(2)]==nil and noHit[utf8.char(3)]==nil,
    "no native collision fabricated a hit part instead of using directional aim")
local shotPosition=target.Position
item.BetweenQueries=function() target.Position=Vector3.new(75,0,100) end
local captured=select(3,gun.StartShooting(item))
for _,data in ipairs({captured,tracer}) do
    for i=0,1 do
        local frame=data[utf8.char(i)]
        assert(frame.LookVector:Dot((shotPosition-frame.Position).Unit)>0.9999,
            "main packet and tracer used different points within one shot")
    end
end
target.Position=shotPosition
item.BetweenQueries=nil
for _,name in ipairs({"Torso","Root"}) do
    RivalsAim.AimPart=name
    local part=enemy.Fighter.Entity.Model:FindFirstChild(name=="Torso" and "UpperTorso" or "HumanoidRootPart")
    raycastResult={Instance=part,Position=part.Position}
    assert(select(3,gun.StartShooting(item))[utf8.char(2)]==part,"Aim Part choice ignored")
end
RivalsAim.AimPart="Head"
local wall={IsDescendantOf=function() return false end}
raycastResult={Instance=wall,Position=Vector3.new(0,0,20)}
assert(select(3,gun.StartShooting(item))==packet,"wall-blocked enemy was selected")
RivalsAim.WallCheck=false
wall.CFrame=CFrame.new(raycastResult.Position)
local throughWall=select(3,gun.StartShooting(item))
assert(throughWall~=packet and throughWall[utf8.char(2)]==wall,
    "disabled wall check invented an enemy collision through a wall")
RivalsAim.WallCheck=true
raycastResult=nil
local savedOrigin=packet[utf8.char(0)]
packet[utf8.char(0)]={Position=Vector3.new(),NativeSentinel="opaque origin"}
assert(select(3,gun.StartShooting(item))[utf8.char(0)]==packet[utf8.char(0)],
    "non-CFrame origin shape was rejected or replaced")
packet[utf8.char(0)]=savedOrigin
packet[utf8.char(0)]=CFrame.new(Vector3.new(0,0,10))
raycastResult=function(origin)
    if origin.Z==10 then return {Instance=wall,Position=Vector3.new(0,0,20)} end
    return nil
end
assert(select(3,gun.StartShooting(item))==packet,"wall at the shot origin was missed by camera-only check")
packet[utf8.char(0)]=savedOrigin
raycastResult=nil
raycastFailure=true
assert(select(3,gun.StartShooting(item))==packet,"failed collision query blocked native shot")
raycastFailure=false
local extra=table.pack(localFighter:GetCameraData(nil,"ordinary query"))
assert(extra.n==3 and extra[1]==packet and extra[2]==nil and extra[3]=="camera-extra",
    "camera query outside a gun call changed")
assert(localFighter.CameraArgs.n==2 and localFighter.CameraArgs[1]==nil)
item.Blocked=true
local blocked=table.pack(gun.StartShooting(item))
assert(blocked.n==1 and blocked[1]==false,"aim changed native cooldown/reload refusal")
item.Blocked=false
Window.Visible=true
assert(select(3,gun.StartShooting(item))==packet,"menu-open shot was redirected")
Window.Visible=false
RivalsAim.Radius=10
assert(select(3,gun.StartShooting(item))==packet,"out-of-FOV target selected")
RivalsAim.Radius=150
item.Info.IsRaycast=false
assert(select(3,gun.StartShooting(item))==packet,"non-raycast gun was altered")
item.Info.IsRaycast=true
local foreign=setmetatable({IsLocalPlayer=false},{__index=fighterPrototype})
assert(select(3,gun.StartShooting({ClientFighter=foreign,Info={IsRaycast=true}}))==packet)
local originalProjection=Camera.WorldToViewportPoint
Camera.WorldToViewportPoint=function() error("target disappeared") end
assert(select(3,gun.StartShooting(item))==packet,"selection failure blocked native firing")
Camera.WorldToViewportPoint=originalProjection
item.Fail=true
local ok,err=pcall(gun.StartShooting,item)
assert(not ok and tostring(err):find("native gun error",1,true))
item.Fail=false
assert(localFighter:GetCameraData()==packet,"native error leaked shot context")
RivalsAim.SetEnabled(false)
assert(not state.Active and select(3,gun.StartShooting(item))==packet)
local installed=gun.StartShooting
RivalsAim.SetEnabled(true)
assert(gun.StartShooting==installed,"toggle stacked duplicate shot wrappers")

-- Regression from the user's live k258 probe: firing uses six-component tables,
-- while the tracer query's third argument requests raw CFrames. The position and
-- YXZ angles below were captured from GetCameraData, rather than invented fields.
local fixture0={100.26226806640625,-676.2423095703125,1179.3311767578125,
    0.17469914257526398,-0.7852363586425781,0}
local fixture1={91.49556732177734,-675.494384765625,1188.1007080078125,
    0.00018309835286345333,-0.7851985692977905,7.275957614183426e-12}
local fixture3={3.0888671875,0.856201171875,-1.750244140625,0,-3.1112923622131348,0}
-- Independent matrix entries validate the observed YXZ convention against raw
-- frame 0; XYZ order would put a nonzero value in row 2, column 1.
assert(math.abs(math.cos(fixture0[5])-0.7072212100028992)<1e-6)
assert(math.abs(math.sin(fixture0[5])*math.sin(fixture0[4])+0.12288365513086319)<1e-6)
assert(math.abs(-math.sin(fixture0[4])+0.1738118678331375)<1e-6)
local savedPacket=packet
local function fixtureFrame(values)
    return CFrame.new(values[1],values[2],values[3])
        * CFrame.fromOrientation(values[4],values[5],values[6])
end
packet={[utf8.char(0)]=fixtureFrame(fixture0),[utf8.char(1)]=fixtureFrame(fixture1),
    [utf8.char(3)]=fixtureFrame(fixture3),Other="keep"}
local model=enemy.Fighter.Entity.Model
local hitbox=new("BasePart",{Name="HitboxHead",Position=Vector3.new(35,0,100)},model)
hitbox.CFrame=CFrame.new(hitbox.Position)
hitbox.IsDescendantOf=target.IsDescendantOf
local bodybox=new("BasePart",{Name="HitboxBody",Position=Vector3.new(35,1,100)},model)
bodybox.CFrame=CFrame.new(bodybox.Position)
bodybox.IsDescendantOf=target.IsDescendantOf
for _,stringKeys in ipairs({true,false}) do
    local function key(i) return stringKeys and utf8.char(i) or i end
    local function serialize(values)
        local t={CodecExtra="keep"}
        for i=0,5 do t[key(i)]=values[i+1] end
        return t
    end
    networkPacket={[utf8.char(0)]=serialize(fixture0),[utf8.char(1)]=serialize(fixture1),
        [utf8.char(3)]=serialize(fixture3),Other="keep"}
    local function checkDirection(encoded,expected,fixture)
        assert(typeof(encoded)=="table" and encoded.CodecExtra=="keep",
            "firing frame became a CFrame or lost native fields")
        local position=Vector3.new(encoded[key(0)],encoded[key(1)],encoded[key(2)])
        assert(position.X==fixture[1] and position.Y==fixture[2] and position.Z==fixture[3],
            "encoded firing origin moved")
        local pitch,yaw=encoded[key(3)],encoded[key(4)]
        local direction=Vector3.new(-math.sin(yaw)*math.cos(pitch),math.sin(pitch),
            -math.cos(yaw)*math.cos(pitch))
        assert(direction:Dot((expected-position).Unit)>0.9999,
            "encoded firing frame still aims at the crosshair")
    end
    raycastResult={Instance=hitbox,Position=hitbox.Position-Vector3.new(0,0,0.5)}
    for i=1,10 do
        local result=table.pack(gun.StartShooting(item,nil,"encoded",nil))
        local data=result[3]
        assert(result.n==5 and result[5]=="encoded" and data~=networkPacket)
        assert(data[utf8.char(2)]==hitbox and tracer[utf8.char(2)]==hitbox,
            "aim ignored the native head hitbox")
        for field=0,1 do
            checkDirection(data[utf8.char(field)],hitbox.Position,field==0 and fixture0 or fixture1)
            local raw=tracer[utf8.char(field)]
            assert(typeof(raw)=="CFrame" and raw.LookVector:Dot((hitbox.Position-raw.Position).Unit)>0.9999)
        end
        local offset=data[utf8.char(3)]
        assert(typeof(offset)=="table" and offset[key(2)]==-0.5 and offset.CodecExtra=="keep",
            "network hit offset was not encoded like native firing data")
        assert(networkPacket[utf8.char(0)][key(3)]==fixture0[4] and networkPacket[utf8.char(2)]==nil,
            "encoded native data was mutated")
    end
    local nativeOffset=networkPacket[utf8.char(3)]
    networkPacket[utf8.char(3)]=nil
    local formerlyMissed=select(3,gun.StartShooting(item))
    assert(typeof(formerlyMissed[utf8.char(3)])=="table"
        and formerlyMissed[utf8.char(3)][key(2)]==-0.5,
        "aiming away from geometry produced an unencoded hit offset")
    networkPacket[utf8.char(3)]={UnknownEncoding=true}
    assert(select(3,gun.StartShooting(item))==networkPacket,
        "unknown offset encoding produced a partial shot packet")
    networkPacket[utf8.char(3)]=nativeOffset
    RivalsAim.AimPart="Torso"
    raycastResult={Instance=bodybox,Position=bodybox.Position}
    local torsoData=select(3,gun.StartShooting(item))
    checkDirection(torsoData[utf8.char(1)],bodybox.Position,fixture1)
    RivalsAim.AimPart="Head"
    raycastResult=nil
    local noCollision=select(3,gun.StartShooting(item))
    assert(noCollision[utf8.char(2)]==nil and noCollision[utf8.char(3)]==nil)
    local view=networkPacket[utf8.char(1)]
    local component=view[key(5)]
    view[key(5)]=nil
    assert(select(3,gun.StartShooting(item))==networkPacket,"unknown codec shape did not fail open")
    view[key(5)]=component
    RivalsAim.SetEnabled(false)
    assert(select(3,gun.StartShooting(item))==networkPacket,"disabled aim changed encoded data")
    RivalsAim.SetEnabled(true)
end
networkPacket=nil
packet=savedPacket
table.remove(model.children,table.find(model.children,hitbox))
table.remove(model.children,table.find(model.children,bodybox))
raycastResult=nil
print("PASS Rivals serialized firing: captured YXZ tables, raw tracers, native hitboxes, offsets, fail-open, disabled data")
state.Restore()
assert(gun.StartShooting==nativeShot and rawget(localFighter,"GetCameraData")==nil,
    "unload did not restore native gun and inherited camera method")
print("PASS Rivals shots: repeated shots, both aim frames, origin positions, real metadata, body choices, walls, cleanup")

RivalsAim.BuildUI()
assert(RivalsUI and not BedWarsUI and RivalsUI.Name=="RiftRivalsBoard")
assert(RivalsUI.Size.X.Offset==1740 and RivalsUI.Size.Y.Offset==770)
assert(Persistence.HUDFrames.RivalsMenu==RivalsUI and Persistence.HUDFrames.ModuleList)
local cards,columns={},{}
for _,o in ipairs(RivalsUI:GetDescendants()) do
    if o:IsA("TextButton") and o.Name=="Silent Aim" then cards.aim=o end
    if o:IsA("TextButton") and o.Name=="FOV Circle" then cards.fov=o end
    if o.Parent==RivalsUI and o:IsA("Frame") and o.Name~="Frame" then columns[o.Name]=o end
end
assert(columns.Combat and columns.Visuals and columns.Sunset and not columns.KIT)
assert(cards.aim and cards.fov and cards.aim.Size.Y.Offset==35)
assert(cards.aim.Parent:IsA("ScrollingFrame"),"Rivals lost shared scrolling card list")
local radius,partControl,wallControl
for _,c in ipairs(ConfigControls) do
    if c.Key=="Visuals/Rivals/FOV Circle/Radius" then radius=c end
    if c.Key=="Combat/Rivals/Silent Aim/Aim Part" then partControl=c end
    if c.Key=="Combat/Rivals/Silent Aim/Wall Check" then wallControl=c end
end
assert(radius and radius.Kind=="number" and radius.Max==1500)
radius.Set(1250)
assert(RivalsAim.Radius==1250)
RivalsAim.FOVVisible=true
RunService.RenderStepped:Fire()
for _,o in ipairs(created) do if o.Name=="FOVCircle" then assert(o.Size.X.Offset==2500) end end
assert(ConfigControls[1]==partControl,"Aim Part must be the first Silent Aim setting")
partControl.Set("Torso")
assert(RivalsAim.AimPart=="Torso")
wallControl.Set(false)
assert(RivalsAim.WallCheck==false)
local rivalsTitle=false
for _,o in ipairs(RivalsUI:GetDescendants()) do
    if o.Text=="RIFT | RIVALS" then rivalsTitle=true end
    assert(o.Text~="Aim support ready","removed status text still rendered")
end
assert(rivalsTitle)
cards.aim.MouseButton2Click:Fire()
local aimControl
for _,c in ipairs(ConfigControls) do if c.Key=="Combat/Rivals/Silent Aim/Silent Aim" then aimControl=c end end
local row=aimControl.Row
assert(row.Size.Y.Offset==22)
assert(row:FindFirstChildOfClass("Frame").Position.Y.Scale==0.5)
assert(row:FindFirstChildOfClass("TextButton").Position.Y.Scale==0.5)
assert(row:FindFirstChildOfClass("TextLabel").TextYAlignment==Enum.TextYAlignment.Center)
Settings.ActiveSearchBox.Text="silent"
Settings.ActiveSearchBox:GetPropertyChangedSignal("Text"):Fire()
assert(cards.aim.Visible and not cards.fov.Visible,"shared search filtering failed")
print("PASS Rivals board: shared BedWars layout/cards/search, game-specific controls, FOV slider")

BedWars.KitCatalog=function() return {},{} end
Settings.SelectedGame="BedWars"
BedWars.BuildUI()
assert(BedWarsUI.Name=="RiftBedWarsBoard" and BedWarsUI.Size.X.Offset==1955)
assert(Persistence.HUDFrames.BedWarsMenu==BedWarsUI)
local kitColumn
local bedwarsTitle=false
for _,o in ipairs(BedWarsUI:GetDescendants()) do if o.Text=="RIFT | BEDWARS" then bedwarsTitle=true end end
assert(bedwarsTitle)
for _,o in ipairs(BedWarsUI:GetChildren()) do if o.Name=="KIT" then kitColumn=o end end
assert(kitColumn,"shared renderer lost BedWars kit column")
print("PASS BedWars board: original dimensions and kit column retained")
