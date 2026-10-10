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
Enum.KeyCode=setmetatable({}, {__index=function(t,name)
    local key={Name=name}
    rawset(t,name,key)
    return key
end})
Enum.RenderPriority={Camera={Value=200},Last={Value=300}}
local vectors={}
local Vector3={new=function(x,y,z) return setmetatable({X=x or 0,Y=y or 0,Z=z or 0},vectors) end}
local Vector2={new=function(x,y) return Vector3.new(x,y,0) end}
function vectors.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function vectors.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function vectors.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function vectors.__index(a,k)
    if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=="Unit" then return a*(1/a.Magnitude) end
    if k=="Dot" then return function(_,b) return a.X*b.X+a.Y*b.Y+a.Z*b.Z end end
end
local function color(r,g,b)
    return {R=r,G=g,B=b,_type="Color3",Lerp=function(self) return self end,ToHSV=function() return 0,1,1 end}
end
local Color3={new=color,fromRGB=function(r,g,b) return color(r/255,g/255,b/255) end}
local T={element=color(0,0,0),text=color(1,1,1),dim=color(0.5,0.5,0.5),red=color(1,0,1)}
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
    end,ToOrientation=function(self) return table.unpack(self.Angles) end,
        Lerp=function(self,goal,alpha)
            local f=CFrame.fromOrientation(self.Angles[1]+(goal.Angles[1]-self.Angles[1])*alpha,
                self.Angles[2]+(goal.Angles[2]-self.Angles[2])*alpha,
                self.Angles[3]+(goal.Angles[3]-self.Angles[3])*alpha)
            f.Position=self.Position
            f.LerpAlpha=alpha
            return f
        end},frameMeta)
end
function CFrame.fromOrientation(x,y,z)
    local f=CFrame.new()
    f.Angles={x,y,z}
    f.LookVector=Vector3.new(-math.sin(y)*math.cos(x),math.sin(x),-math.cos(y)*math.cos(x))
    return f
end
CFrame.Angles=CFrame.fromOrientation
function frameMeta.__mul(a,b)
    if getmetatable(b)==vectors then return a.Position+b end
    local f=CFrame.fromOrientation(table.unpack(b.Angles))
    f.Position=a.Position
    return f
end
function frameMeta.__add(frame,offset)
    local result=CFrame.fromOrientation(table.unpack(frame.Angles))
    result.Position=frame.Position+offset
    result.LookVector=frame.LookVector
    return result
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
    function obj:ReleaseFocus() self.Focused=false end
    function obj:FindFirstChild(name)
        for _,child in ipairs(self.children) do if child.Name==name then return child end end
    end
    function obj:IsDescendantOf(parent)
        local current=self.Parent
        while type(current)=="table" do
            if current==parent then return true end
            current=current.Parent
        end
        return false
    end
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
local RunService={Heartbeat=signal(),RenderStepped=signal(),Stepped=signal(),PreSimulation=signal()}
RunService.Bindings={}
function RunService:BindToRenderStep(name,priority,callback)
    assert(priority==201 or priority==301 or priority==302 or priority==303)
    self.Bindings[name]=callback
end
function RunService:UnbindFromRenderStep(name) self.Bindings[name]=nil end
local Gui=new("ScreenGui",{},nil)
Gui.Parent=true
local PlayerGui=new("Folder",{},nil)
local Window={Visible=false}
local BedWarsUI,RivalsUI
local Settings={SelectedGame="Rivals",MenuKey=Enum.KeyCode.RightShift,
    MenuBlurOn=true,ModuleListOn=true,GameBoards={},SetMenuBlur=function() end,
    MakeMenuDraggable=function() end}
local Camera={CameraType="Custom",CFrame=CFrame.new(Vector3.new()),ViewportSize=Vector2.new(1920,1080)}
Camera.signals = {}
function Camera:GetPropertyChangedSignal(name)
    self.signals[name] = self.signals[name] or signal()
    return self.signals[name]
end
Camera.CFrame.LookVector=Vector3.new(0,0,1)
local workspace={CurrentCamera=Camera}
workspace.signals = {}
function workspace:GetPropertyChangedSignal(name)
    self.signals[name] = self.signals[name] or signal()
    return self.signals[name]
end
local RaycastParams={new=function() return {} end}
local raycastResult,raycastFailure,casts=nil,false,{}
function workspace:Raycast(origin,direction,params)
    if raycastFailure then error("raycast unavailable") end
    table.insert(casts,{Origin=origin,Direction=direction,Params=params})
    if type(raycastResult)=="function" then return raycastResult(origin,direction,params) end
    return raycastResult
end
local mouse={}
local LocalPlayer={CameraMode="LockFirstPerson",CameraMinZoomDistance=0.5,CameraMaxZoomDistance=12.5,
    GetMouse=function() return mouse end,
    GetAttribute=function() return 1 end}
local Players={GetPlayers=function() return {LocalPlayer} end}
local aimMouseHeld=false
local UIS={MouseBehavior="LockCenter",MouseIconEnabled=false,TouchEnabled=false,
    InputBegan=signal(),InputChanged=signal(),GetFocusedTextBox=function() return nil end,
    IsMouseButtonPressed=function(_,button) return aimMouseHeld and button==Enum.UserInputType.MouseButton2 end,
    GetMouseLocation=function() return Vector2.new(100,100) end}
local ENV={}
local allDrawings={Objects={}}
function allDrawings.new(kind)
    local object={Kind=kind,Visible=false,Remove=function(self) self.Removed=true self.Visible=false end}
    table.insert(allDrawings.Objects,object)
    return object
end
ENV.Drawing=allDrawings
local ESP={Stop=function() end}
local useScriptable=true
local function anyMenuVisible()
    for _,board in pairs(Settings.GameBoards) do if board.Parent and board.Visible then return true end end
    return Window.Visible or RivalsUI and RivalsUI.Visible or false
end
local RivalsAim={Enabled=false,FOVVisible=false,Radius=150,AimPart="Head",WallCheck=true}
RivalsAim.Assist={Enabled=false,AimPart="Head",WallCheck=true,HoldMouse=true,Strength=8}
RivalsAim.Aimbot={Enabled=false,AimPart="Head",WallCheck=true,HoldMouse=true,MaxDistance=1000}
local RivalsVisuals={BoxesOn=false,OutlinesOn=false,BoxColor=color(1,0,0),OutlineColor=color(0,1,0)}
RivalsVisuals.TargetHUDBarTime=0.3
local RivalsKillChat={Enabled=false,Message="GG! - Rift",Cooldown=2,Queue={}}
local clockNow=0
local os={clock=function() return clockNow end}
local chatMessages={}
local warnings={}
local function warn(message) table.insert(warnings,message) end
local BedWars={KitCatalog=function() error("Rivals must not read BedWars kit modules") end}
function BedWars.KillChatSend(message) table.insert(chatMessages,message) return true end
local bedWarsMarks={Players={}}
local function setBedWarsMark(kind,model,c)
    local mark=bedWarsMarks[kind][model] or {Parent=model,Destroy=function(self) self.Parent=nil end}
    mark.Color=c
    bedWarsMarks[kind][model]=mark
end
local Persistence={HUDFrames={}}
local ConfigControls,gameSections,Tabs={},{},{}
local AimTab={Left=new("Frame",{},nil)}
local VisualsTab={Left=new("Frame",{},nil)}
local SettingsTab={Left=new("Frame",{},nil)}
local MainTab={Left=new("Frame",{},nil)}
local MiscTab={Left=new("Frame",{},nil)}
local FunTab={Left=new("Frame",{},nil)}
local PlayerTab={Left=new("Frame",{},nil)}
local flightStarts,flightStops=0,0
local Fly={Start=function() flightStarts+=1 end,Stop=function() flightStops+=1 end}
Tabs.Combat={Left=AimTab.Left,Right=new("Frame",{},nil)}
Tabs.Movement={Left=MainTab.Left,Right=new("Frame",{},nil)}
Tabs.Misc={Left=MiscTab.Left,Right=new("Frame",{},nil)}
Tabs.Fun={Left=FunTab.Left,Right=new("Frame",{},nil)}
Tabs.Player={Left=PlayerTab.Left,Right=new("Frame",{},nil)}
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
local function configKey(parent,text)
    return parent.tab.."/"..parent.game.."/"..parent.section.."/"..text
end
local function addControl(parent,text,kind,default,callback)
    local value=default
    local row=new("Frame",{},parent)
    local c={Kind=kind,Key=parent.tab.."/"..parent.game.."/"..parent.section.."/"..text,
        Box=parent.Parent,Row=row,Get=function() return value end}
    c.Set=function(v) value=v callback(v) end
    table.insert(ConfigControls,c)
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
function Elements.ColorPicker(p,t,d,cb) return addControl(p,t,"color",d,cb) end
function Elements.TextBox(p,t,placeholder,cb,d) return addControl(p,t,"text",d,cb) end
Elements.Label=label
function Elements.Button(parent,text,callback)
    local button=new("TextButton",{Text=text},parent)
    button.MouseButton1Click:Connect(callback)
    return button
end
local BRAND,SUNSET_BUILD="RIFT","test-k262"
local RIFT_KILL_MESSAGE="RIFT ON TOP 10$ LIFETIME, STEAL AN EGG, RIVALS, BEDWARS, ZSA, JJS, ARSENAL!"
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
local eliminationCalls=0
local nativeElimination=function(self,...)
    eliminationCalls+=1
    self.LastArgs=table.pack(...)
    if self.Fail then error("native elimination error") end
    return "effect",nil,"extra"
end
local eliminationApi={EliminationEffect=nativeElimination}
local scripts=new("Folder",{},nil)
function scripts:FindFirstChild(name)
    return {FindFirstChild=function(_,child)
        if name=="Controllers" and child=="FighterController" then return controller end
        if name=="Modules" and child=="ItemTypes" then
            return {FindFirstChild=function(_,n) if n=="Gun" then return gun end end}
        end
        if name=="Modules" and child=="ClientReplicatedClasses" then
            return {FindFirstChild=function(_,n)
                if n=="ClientFighter" then return {FindFirstChild=function(_,m)
                    if m=="FighterInterface" then return eliminationApi end
                end} end
            end}
        end
    end}
end
function LocalPlayer:FindFirstChild(name) if name=="PlayerScripts" then return scripts end end
local identity,requireFailure,requireCalls,modulesReady=8,false,0,false
local getloadedmodules=function() return modulesReady and {controller,gun,eliminationApi} or {} end
local getthreadidentity=function() return identity end
local setthreadidentity=function(value) identity=value end
local require=function(module)
    requireCalls+=1
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
    function model:GetBoundingBox() return CFrame.new(head.Position),Vector3.new(4,6,2) end
    function head:IsDescendantOf(parent) return parent==model or parent==workspace end
    torso.IsDescendantOf,root.IsDescendantOf=head.IsDescendantOf,head.IsDescendantOf
    return {Character={},GetAttribute=function() return team end,
        Fighter={Entity={Model=model,RootPart=head},Get=function() return environment or "arena" end}},head
end
function Camera:WorldToViewportPoint(position)
    return Vector3.new(960+position.X,540-position.Y,position.Z),true
end

local game = { JobId = "mock-session" }
Settings.RunCallback = function(callback, ...) return callback(...) end
Settings.Notify = function() end
local Lighting = {}
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
UIS.MouseBehavior = "LockCenter"
UIS.MouseIconEnabled = false
Window.Visible=false
onMenuVisibility()
assert(UIS.MouseBehavior=="Default" and UIS.MouseIconEnabled==true,
    "menu did not restore captured input without a global hook")
print("PASS Rivals input: first-person camera preserved, focus released, mouse restored on close/unload")

requireFailure=true
RivalsAim.Setup()
assert(requireCalls==0 and not RivalsAim.Available and identity==8,"startup required game modules")
RivalsAim.SetEnabled(true)
assert(requireCalls==0 and not RivalsAim.Enabled,"aim initialized a module before the game")
modulesReady=true
RivalsAim.SetEnabled(true)
assert(not RivalsAim.Enabled and identity==8,"failed require leaked game script identity")
requireFailure=false
RivalsAim.Setup()
assert(not RivalsAim.Available and identity==8,"setup eagerly loaded game modules")
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

local fovCleanupIndex=#connections+1
RivalsFOV.Setup()
RivalsSpeed.Setup()
RivalsView.Setup()
RivalsAim.Setup()
state=ENV.SunsetRivalsAimHook
RivalsAim.BuildUI()
assert(RivalsUI and not BedWarsUI and RivalsUI.Name=="RiftRivalsBoard")
assert(RivalsUI.Size.X.Offset==880 and RivalsUI.Size.Y.Offset==640)
assert(Persistence.HUDFrames.RivalsMenu==RivalsUI and Persistence.HUDFrames.ModuleList)
local cards,columns={},{}
for _,o in ipairs(RivalsUI:GetDescendants()) do
    if o:IsA("TextButton") and o.Name=="Silent Aim" then cards.aim=o end
    if o:IsA("TextButton") and o.Name=="FOV Circle" then cards.fov=o end
    if o:IsA("TextButton") and o.Name=="Fly" then cards.fly=o end
    if o:IsA("TextButton") and o.Name=="Aim Assist" then cards.assist=o end
    if o:IsA("TextButton") and o.Name=="Aimbot" then cards.aimbot=o end
    if o:IsA("TextButton") and o.Name=="Player Outlines" then cards.outlines=o end
    if o:IsA("TextButton") and o.Name=="ESP Boxes" then cards.boxes=o end
    if o:IsA("TextButton") and o.Name=="Spinbot" then cards.spin=o end
    if o:IsA("TextButton") and o.Name=="FOV" then cards.cameraFOV=o end
    if o:IsA("TextButton") and o.Name=="Kill Chat" then cards.killChat=o end
    if o.Parent==RivalsUI and o:IsA("Frame") and o.Name~="Frame" then columns[o.Name]=o end
end
assert(columns.Combat and columns.Visuals and columns.Sunset and not columns.KIT)
assert(columns.Combat.Visible and not columns.Visuals.Visible, "multiple categories overlap at startup")
do
local visualsTab
for _, object in ipairs(RivalsUI:GetDescendants()) do
    if object.Name == "VisualsTab" then visualsTab = object end
end
assert(visualsTab, "category navigation is missing")
visualsTab.MouseButton1Click:Fire()
assert(columns.Visuals.Visible and not columns.Combat.Visible, "category selection does not switch content")
local menuScale = RivalsUI:FindFirstChildOfClass("UIScale")
Camera.ViewportSize = Vector2.new(640, 480)
Camera.signals.ViewportSize:Fire()
assert(menuScale.Scale < 1 and menuScale.Scale * 880 <= 608, "compact menu exceeds the viewport")
Camera.ViewportSize = Vector2.new(1920, 1080)
Camera.signals.ViewportSize:Fire()
assert(menuScale.Scale == 1, "menu did not resize after viewport replacement")
end
assert(cards.aim and cards.fov and cards.aim.Size.Y.Offset==42)
assert(cards.fly,"Rivals Fly is missing from the Movement column")
assert(cards.assist and cards.aimbot and cards.outlines and cards.boxes,"new Rivals modules are missing")
assert(cards.spin and cards.cameraFOV,"Spinbot or camera FOV card missing")
assert(cards.killChat and eliminationApi.EliminationEffect==nativeElimination,"Kill Chat missing or enabled on startup")
local function findConfig(key)
    for _,c in ipairs(ConfigControls) do if c.Key==key then return c end end
    error("missing config "..key)
end
do
local fovToggle=findConfig("Visuals/Rivals/FOV/FOV")
local fovValue=findConfig("Visuals/Rivals/FOV/Field of View")
assert(fovToggle.GetBind()==nil and fovValue.Min==30 and fovValue.Max==120)
Camera.FieldOfView=70
fovValue.Set(100)
assert(Camera.FieldOfView==70,"disabled FOV changed camera")
fovToggle.Set(true)
assert(Camera.FieldOfView==100,"FOV toggle did not apply")
Camera.FieldOfView=65
RunService.Bindings.RiftRivalsFOV()
assert(Camera.FieldOfView==100,"game camera update overrode selected FOV")
local replacement={FieldOfView=75}
workspace.CurrentCamera=replacement
RunService.Bindings.RiftRivalsFOV()
assert(Camera.FieldOfView==70 and replacement.FieldOfView==100,"camera swap did not restore/capture FOV")
fovToggle.Set(false)
assert(replacement.FieldOfView==75,"FOV off did not restore original")
workspace.CurrentCamera=Camera
fovToggle.Set(true)
connections[fovCleanupIndex].Disconnect()
assert(Camera.FieldOfView==70 and not RunService.Bindings.RiftRivalsFOV,"FOV unload cleanup failed")
local spin=findConfig("Player/Rivals/Spinbot/Spinbot")
local speed=findConfig("Player/Rivals/Spinbot/Spin Speed")
local reverse=findConfig("Player/Rivals/Spinbot/Reverse Spin")
local character=new("Model",{},nil)
character.Parent=workspace
local hum=new("Humanoid",{Health=100,AutoRotate=true,WalkSpeed=16},character)
local root=new("Part",{Name="HumanoidRootPart",Position=Vector3.new(3,4,5),CFrame=CFrame.new(Vector3.new(3,4,5))},character)
function character:FindFirstChild(name)
    for _,child in ipairs(self.children) do if child.Name==name then return child end end
end
LocalPlayer.Character=character
speed.Set(360)
spin.Set(true)
RunService.Stepped:Fire(0,0.05)
assert(not hum.AutoRotate and math.abs(root.CFrame.Angles[2]-math.rad(18))<0.0001,"spin speed failed")
reverse.Set(true)
RunService.Stepped:Fire(0,0.05)
assert(math.abs(root.CFrame.Angles[2])<0.0001,"reverse spin failed")
Settings.FlyEnabled=true
RunService.Stepped:Fire(0,0.05)
assert(hum.AutoRotate,"flight conflict did not restore rotation")
Settings.FlyEnabled=false
RunService.Stepped:Fire(0,0.05)
assert(not hum.AutoRotate,"spin did not resume")
spin.Set(false)
assert(hum.AutoRotate and spin.GetBind()==nil,"spin toggle did not restore rotation")
local speedToggle=findConfig("Movement/Rivals/Speed/Speed")
local speedValue=findConfig("Movement/Rivals/Speed/Walk Speed")
speedValue.Set(10000)
assert(hum.WalkSpeed==16,"disabled Speed altered movement")
speedToggle.Set(true)
assert(hum.WalkSpeed==10000,"Speed rejected a value above the slider range")
hum.WalkSpeed=20
RunService.PreSimulation:Fire()
assert(hum.WalkSpeed==10000,"Speed did not maintain selected value")
speedToggle.Set(false)
assert(hum.WalkSpeed==16,"Speed did not restore original movement")
local third=findConfig("Player/Rivals/Third Person/Third Person")
local thirdDistance=findConfig("Player/Rivals/Third Person/Distance")
local zoom=findConfig("Player/Rivals/Zoom Unlocker/Zoom Unlocker")
root.ClassName="BasePart"
root.LocalTransparencyModifier=1
local viewBase=Camera.CFrame
raycastResult=nil
RivalsUI.Visible=false
third.Set(true)
assert(LocalPlayer.CameraMode==Enum.CameraMode.Classic and root.LocalTransparencyModifier==0,
    "third person did not reveal local avatar")
assert(math.abs((Camera.CFrame.Position-viewBase.Position).Magnitude-10)<0.0001,"third-person distance not applied")
RunService.Bindings.RiftRivalsView()
assert(math.abs((Camera.CFrame.Position-viewBase.Position).Magnitude-10)<0.0001,"camera offset accumulated")
zoom.Set(true)
UIS.InputChanged:Fire({UserInputType=Enum.UserInputType.MouseWheel,Position=Vector3.new(0,0,-1)},false)
RunService.Bindings.RiftRivalsView()
assert(math.abs((Camera.CFrame.Position-viewBase.Position).Magnitude-13)<0.0001,"scroll zoom failed")
thirdDistance.Set(20)
assert(math.abs((Camera.CFrame.Position-viewBase.Position).Magnitude-20)<0.0001,"distance setting failed")
raycastResult={Position=viewBase.Position+Vector3.new(0,0,2),Normal=Vector3.new(0,0,-1)}
RunService.Bindings.RiftRivalsView()
assert(math.abs((Camera.CFrame.Position-viewBase.Position).Magnitude-1.7)<0.0001,"camera wall collision failed")
raycastResult=nil
third.Set(false)
zoom.Set(false)
assert(Camera.CFrame==viewBase and root.LocalTransparencyModifier==1
    and LocalPlayer.CameraMinZoomDistance==0.5 and LocalPlayer.CameraMaxZoomDistance==12.5
    and LocalPlayer.CameraMode=="LockFirstPerson","view disable did not restore original state")
LocalPlayer.Character=nil
print("PASS Rivals Speed/view: typed speed above range, third person, wheel zoom, wall collision, state restoration")
print("PASS Rivals Spinbot/FOV: speed/reverse/flight cleanup, camera swaps, disabled values, unload restoration")
end
local chatToggle=findConfig("Fun/Rivals/Kill Chat/Kill Chat")
local chatDelay=findConfig("Fun/Rivals/Kill Chat/Message Delay")
assert(chatToggle.GetBind()==nil and chatDelay.Min==1 and chatDelay.Max==10)
assert(not pcall(findConfig,"Fun/Rivals/Kill Chat/Message"),"fixed kill message remained editable")
chatDelay.Set(2)
chatToggle.Set(true)
assert(identity==8 and RivalsKillChat.Enabled,"Kill Chat activation/identity restore failed")
local localInterface={ClientFighter={IsLocalPlayer=true}}
local remoteInterface={ClientFighter={IsLocalPlayer=false}}
local result=table.pack(eliminationApi.EliminationEffect(localInterface,"enemy",7))
assert(result.n==3 and result[1]=="effect" and result[2]==nil and result[3]=="extra",
    "elimination observer changed return values")
assert(localInterface.LastArgs[1]=="enemy" and localInterface.LastArgs[2]==7,"arguments changed")
eliminationApi.EliminationEffect(remoteInterface,"enemy")
assert(#RivalsKillChat.Queue==1,"remote player's elimination queued chat")
RunService.Heartbeat:Fire()
assert(#chatMessages==1 and chatMessages[1]==RIFT_KILL_MESSAGE,"exact local elimination message failed")
eliminationApi.EliminationEffect(localInterface,"enemy2")
RunService.Heartbeat:Fire()
assert(#chatMessages==1,"message delay not respected")
clockNow=2
RunService.Heartbeat:Fire()
assert(#chatMessages==2,"queued message did not send after delay")
localInterface.Fail=true
assert(not pcall(eliminationApi.EliminationEffect,localInterface,"enemy3") and #RivalsKillChat.Queue==0,
    "native errors swallowed or failed effects queued")
localInterface.Fail=false
RivalsKillChat.Message="old saved message"
eliminationApi.EliminationEffect(localInterface,"enemy")
assert(RivalsKillChat.Queue[1]==RIFT_KILL_MESSAGE,"old message changed the fixed kill message")
chatToggle.Set(false)
assert(eliminationApi.EliminationEffect==nativeElimination and #RivalsKillChat.Queue==0,
    "disable did not restore method/clear queue")
requireFailure=true
chatToggle.Set(true)
assert(not chatToggle.Get() and not RivalsKillChat.Enabled and identity==8,"require failure left enabled")
requireFailure=false
chatToggle.Set(true)
print("PASS Rivals Kill Chat: exact message, local feedback, native results/errors, delay, disable/failure cleanup")
local cameraStep=RunService.Bindings.RiftRivalsCameraAim
assert(cameraStep,"camera aim was not scheduled after the game camera")
cards.aimbot.MouseButton1Click:Fire()
local cameraBefore=Camera.CFrame
cameraStep(1/60)
assert(Camera.CFrame==cameraBefore,"hold-right-mouse mode moved without activation")
aimMouseHeld=true
cameraStep(1/60)
assert(Camera.CFrame.LookVector:Dot((target.Position-Camera.CFrame.Position).Unit)>0.9999)
assert(Camera.CFrame.Position==cameraBefore.Position,"aimbot moved the camera position")
do
    local savedPlayers=Players.GetPlayers
    local other,otherHead=combatPlayer(2,1)
    Players.GetPlayers=function() return {LocalPlayer,enemy,other} end
    local savedPosition=target.Position
    target.Position=Vector3.new(300,0,100)
    cameraStep(1/60)
    assert(state.LockedPlayer==enemy and Camera.CFrame.LookVector:Dot(
        (target.Position-Camera.CFrame.Position).Unit)>0.9999,"aimbot switched targets or dropped lock outside acquisition FOV")
    aimMouseHeld=false
    cameraStep(1/60)
    assert(state.LockedPlayer==nil,"mouse release kept the old lock")
    aimMouseHeld=true
    cameraStep(1/60)
    assert(state.LockedPlayer==other,"aimbot did not reacquire on new activation")
    otherHead.Position=Vector3.new(2000,0,100)
    cameraStep(1/60)
    assert(state.LockedPlayer==nil,"aimbot retained an out-of-range target")
    findConfig("Combat/Rivals/Aimbot/Max Distance").Set(4000)
    RivalsAim.Radius=2500
    cameraStep(1/60)
    assert(state.LockedPlayer==enemy,"increased target range did not permit reacquisition")
    raycastResult={Instance=wall,Position=Vector3.new(0,0,20)}
    findConfig("Combat/Rivals/Aimbot/Wall Check").Set(false)
    cameraStep(1/60)
    assert(state.LockedPlayer==enemy,"wall check off dropped the lock behind cover")
    findConfig("Combat/Rivals/Aimbot/Wall Check").Set(true)
    cameraStep(1/60)
    assert(state.LockedPlayer==nil,"wall check on kept a blocked lock")
    raycastResult=nil
    findConfig("Combat/Rivals/Aimbot/Max Distance").Set(1000)
    RivalsAim.Radius=150
    target.Position=savedPosition
    Players.GetPlayers=savedPlayers
end
cameraBefore=Camera.CFrame
Window.Visible=true
cameraStep(1/60)
assert(Camera.CFrame==cameraBefore,"aimbot ran while the menu was open")
Window.Visible=false
RivalsAim.Radius=10
cameraStep(1/60)
assert(Camera.CFrame==cameraBefore,"aimbot ignored the FOV radius")
RivalsAim.Radius=150
raycastResult={Instance=wall,Position=Vector3.new(0,0,20)}
cameraStep(1/60)
assert(Camera.CFrame==cameraBefore,"camera aim ignored a wall")
raycastResult=nil
findConfig("Combat/Rivals/Aimbot/Aim Part").Set("Root")
cameraStep(1/60)
local aimRoot=enemy.Fighter.Entity.Model:FindFirstChild("HumanoidRootPart")
assert(Camera.CFrame.LookVector:Dot((aimRoot.Position-Camera.CFrame.Position).Unit)>0.9999,
    "camera aim ignored its own selected body part")
findConfig("Combat/Rivals/Aimbot/Aim Part").Set("Head")
cards.aimbot.MouseButton1Click:Fire()
cards.assist.MouseButton1Click:Fire()
Camera.CFrame=CFrame.lookAt(Vector3.new(),Vector3.new(0,0,-100))
cameraStep(1/60)
assert(math.abs(Camera.CFrame.LerpAlpha-(1-math.exp(-8/60)))<1e-8,
    "aim assist smoothing did not account for frame time")
assert(Camera.CFrame.LookVector:Dot((target.Position-Camera.CFrame.Position).Unit)<0.9999,
    "aim assist snapped instead of smoothing")
cards.aimbot.MouseButton1Click:Fire()
cameraStep(1/60)
assert(Camera.CFrame.LerpAlpha==nil
    and Camera.CFrame.LookVector:Dot((target.Position-Camera.CFrame.Position).Unit)>0.9999,
    "aimbot did not take priority when both aim modes were enabled")
cards.aimbot.MouseButton1Click:Fire()
cards.assist.MouseButton1Click:Fire()
aimMouseHeld=false
print("PASS camera aim: sticky player lock, release/reacquisition, range, walls, body selection, smoothing, priority, menu pause")
do
    local hudToggle=findConfig("Visuals/Rivals/Target HUD/Target HUD")
    local model=enemy.Fighter.Entity.Model
    local humanoid=model:FindFirstChildOfClass("Humanoid")
    enemy.DisplayName,enemy.UserId="Test target",42
    Players.GetUserThumbnailAsync=function(_,id) assert(id==42) return "rbxassetid://42" end
    state.LockedPlayer=enemy
    hudToggle.Set(true)
    local hud=RivalsAim.TargetHUD
    assert(hud.Visible and Persistence.HUDFrames.TargetHUD==hud,"target HUD did not follow lock")
    assert(hud:FindFirstChild("TargetName").Text=="Test target"
        and hud:FindFirstChild("Avatar").Image=="rbxassetid://42","target name/avatar were not displayed")
    humanoid.Health,humanoid.MaxHealth=35,100
    RivalsAim.UpdateTargetHUD()
    assert(hud:FindFirstChild("TargetHealth").Text=="35 / 100 HP","HUD health was stale")
    Window.Visible=true
    RivalsAim.UpdateTargetHUD()
    assert(not hud.Visible,"HUD covered the menu")
    Window.Visible=false
    humanoid.Health=0
    RivalsAim.UpdateTargetHUD()
    assert(not hud.Visible,"HUD showed a dead target")
    humanoid.Health=100
    state.LockedPlayer=nil
    hudToggle.Set(false)
    assert(not hud.Visible,"HUD did not hide when disabled")
    local musicToggle=findConfig("Visuals/Rivals/Music Overlay/Music Overlay")
    BedWars.SpotifyPanel=new("Frame",{Visible=false},Gui)
    BedWars.Running=false
    musicToggle.Set(true)
    assert(BedWars.SpotifyPanel.Visible and BedWars.MusicOverlayVisible(),
        "Rivals music overlay depended on BedWars running")
    Settings.SelectedGame="BedWars"
    assert(not BedWars.MusicOverlayVisible(),"Rivals music setting leaked to BedWars")
    Settings.SelectedGame="Rivals"
    musicToggle.Set(false)
    assert(not BedWars.SpotifyPanel.Visible,"music overlay did not hide when disabled")
end
print("PASS Rivals HUDs: locked target, name/avatar, health changes, death/menu/disable, independent music setting")

local outlineColor,boxColor=color(0.4,0.2,0.9),color(0.2,0.8,0.4)
findConfig("Visuals/Rivals/Player Outlines/Color").Set(outlineColor)
findConfig("Visuals/Rivals/ESP Boxes/Color").Set(boxColor)
cards.outlines.MouseButton1Click:Fire()
cards.boxes.MouseButton1Click:Fire()
RunService.RenderStepped:Fire(1/60)
local function liveVisuals()
    local outlines,boxes={},{}
    for _,o in ipairs(created) do
        if o.Name=="RiftPlayerOutline" and o.Parent then table.insert(outlines,o) end
    end
    for _,o in ipairs(allDrawings.Objects) do
        if o.Kind=="Square" and o.ZIndex==2 and not o.Removed then table.insert(boxes,o) end
    end
    return outlines,boxes
end
local highlights,boxes=liveVisuals()
assert(#highlights==3 and #boxes==3,"visuals did not include every living non-local player")
for _,entry in ipairs(highlights) do assert(entry.OutlineColor==outlineColor) end
assert(boxes[1].Visible and boxes[1].Size.X==4 and boxes[1].Size.Y==6,
    "ESP box did not use projected model bounds")
do
    local perspective={ViewportSize=Camera.ViewportSize,WorldToViewportPoint=function(_,point)
        return Vector3.new(960+point.X*1000/point.Z,540-point.Y*1000/point.Z,point.Z)
    end}
    local _,_,nearWidth,nearHeight=projectBounds(perspective,CFrame.new(Vector3.new(0,0,100)),Vector3.new(4,6,2))
    local _,_,farWidth,farHeight=projectBounds(perspective,CFrame.new(Vector3.new(0,0,1000)),Vector3.new(4,6,2))
    assert(farWidth<nearWidth and farHeight<nearHeight and farHeight<24,
        "distant ESP boxes retained a large minimum size")
end
local enemyColored=false
for _,box in ipairs(boxes) do
    assert(box.Color==boxColor or box.Color==Settings.PlayerESP.Rivals.TeamColor,"ESP color did not update")
    enemyColored=enemyColored or box.Color==boxColor
end
assert(enemyColored,"enemy box color was ignored")
local humanoid=enemy.Fighter.Entity.Model:FindFirstChildOfClass("Humanoid")
humanoid.Health=0
RunService.RenderStepped:Fire(1/60)
highlights,boxes=liveVisuals()
assert(#highlights==2 and #boxes==2,"dead player visuals remained or teammates disappeared")
humanoid.Health=100
local oldEntity=enemy.Fighter.Entity
local replacement=combatPlayer(2,40)
enemy.Fighter.Entity=replacement.Fighter.Entity
RunService.RenderStepped:Fire(1/60)
highlights,boxes=liveVisuals()
local respawnFound=false
for _,entry in ipairs(highlights) do if entry.Adornee==enemy.Fighter.Entity.Model then respawnFound=true end end
assert(#highlights==3 and respawnFound,"respawned entity did not replace the old visual")
enemy.Fighter.Entity=oldEntity
cards.outlines.MouseButton1Click:Fire()
cards.boxes.MouseButton1Click:Fire()
RunService.RenderStepped:Fire(1/60)
highlights,boxes=liveVisuals()
assert(#highlights==0 and #boxes==0,"disabled visuals remained")
print("PASS Rivals visuals: all players and teams, independent colors, projected boxes, death, respawn, cleanup")
local flightControl
for _,c in ipairs(ConfigControls) do
    if c.Key=="Movement/Rivals/Fly/Fly" then flightControl=c end
end
assert(flightControl and flightControl.GetBind()==nil)
for _,c in ipairs(ConfigControls) do
    if c.Kind=="toggle" then
        assert(c.Row:FindFirstChildOfClass("TextButton").Visible,"a toggle has no keybind editor")
    end
end
cards.fly.MouseButton1Click:Fire()
assert(Settings.FlyEnabled and flightStarts==1,"Fly menu card did not start flight")
cards.fly.MouseButton1Click:Fire()
assert(not Settings.FlyEnabled and flightStops==1,"Fly menu card did not stop flight")
UIS.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.F},false)
assert(not Settings.FlyEnabled and flightStarts==1,"F toggled Fly")
cards.fly.MouseButton2Click:Fire()
local bindButton=flightControl.Row:FindFirstChildOfClass("TextButton")
assert(bindButton and bindButton.Visible,"Fly keybind editor is hidden")
bindButton.MouseButton1Click:Fire()
UIS.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.F},false)
assert(flightControl.GetBind()==Enum.KeyCode.F and not Settings.FlyEnabled,
    "assigning a key either failed or toggled the module")
UIS.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.F},false)
assert(Settings.FlyEnabled and flightStarts==2,"user-assigned Fly key did not work")
assert(flightControl.SetBind(Settings.MenuKey)==false and flightControl.GetBind()==Enum.KeyCode.F,
    "module bind stole the menu key")
bindButton.MouseButton1Click:Fire()
UIS.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.Backspace},false)
assert(flightControl.GetBind()==nil,"Backspace did not clear a module bind")
flightControl.Set(false)
UIS.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.F},false)
assert(not Settings.FlyEnabled and flightStarts==2,"removed bind remained active")
print("PASS optional keybinds: unbound default, editor, user assignment, activation, menu-key protection, removal")
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
assert(columns.Combat.Visible and not columns.Visuals.Visible, "search left matching results in a hidden category")
print("PASS Rivals board: shared BedWars layout/cards/search, game-specific controls, FOV slider")
cards.outlines.MouseButton1Click:Fire()
RunService.RenderStepped:Fire(1/60)
assert(#liveVisuals()==3)
ENV.SunsetRivalsAimHook.Restore()
assert(not RivalsKillChat.Enabled and eliminationApi.EliminationEffect==nativeElimination
    and #RivalsKillChat.Queue==0,"unload did not clean up Kill Chat")
local remainingOutlines,remainingBoxes=liveVisuals()
assert(#remainingOutlines==0 and #remainingBoxes==0 and RunService.Bindings.RiftRivalsCameraAim==nil,
    "unload left camera aim or enemy visuals active")
print("PASS Rivals unload: camera binding removed and visual instances destroyed")

BedWars.KitCatalog=function() return {},{} end
Settings.SelectedGame="BedWars"
BedWars.BuildUI()
assert(BedWarsUI.Name=="RiftBedWarsBoard" and BedWarsUI.Size.X.Offset==880)
assert(Persistence.HUDFrames.BedWarsMenu==BedWarsUI)
local kitColumn
local bedwarsTitle=false
for _,o in ipairs(BedWarsUI:GetDescendants()) do if o.Text=="RIFT | BEDWARS" then bedwarsTitle=true end end
assert(bedwarsTitle)
for _,o in ipairs(BedWarsUI:GetChildren()) do if o.Name=="KIT" then kitColumn=o end end
assert(kitColumn,"shared renderer lost BedWars kit column")
print("PASS compact board: category navigation, viewport resize, search selects results, BedWars kit controls retained")
do
BedWars.PlayersOn=true
BedWars.PlayerOutlineColor=outlineColor
for _,player in ipairs(Players:GetPlayers()) do
    if player~=LocalPlayer then player.Character=player.Fighter.Entity.Model end
end
refreshBedWarsPlayers()
local count=0
for _,mark in pairs(bedWarsMarks.Players) do count+=1 assert(mark.Color==outlineColor) end
assert(count==3,"BedWars outlines omitted teammates or included dead players")
BedWars.PlayersOn=false
refreshBedWarsPlayers()
assert(next(bedWarsMarks.Players)==nil,"BedWars outline toggle did not clean up")
print("PASS BedWars outlines: all living players and teams, consistent color, disable cleanup")
Settings.SelectedGame="Rivals"
RivalsUI.Visible=false
Window.Visible=false
local originalView=Camera.CFrame
local originalMode,originalMin,originalMax=LocalPlayer.CameraMode,LocalPlayer.CameraMinZoomDistance,LocalPlayer.CameraMaxZoomDistance
RivalsView.ThirdPerson=true
RivalsView.ZoomUnlocked=true
RivalsView.Apply()
assert(RunService.Bindings.RiftRivalsView)
for _,connection in ipairs(connections) do connection:Disconnect() end
assert(not RunService.Bindings.RiftRivalsView and Camera.CFrame==originalView
    and LocalPlayer.CameraMode==originalMode and LocalPlayer.CameraMinZoomDistance==originalMin
    and LocalPlayer.CameraMaxZoomDistance==originalMax,"unload did not restore camera/zoom")
print("PASS view unload: camera offset, mode, zoom bounds, and render binding restored")
end

(function()
    local drawings={Objects={}}
    function drawings.new(kind)
        if drawings.FailKind==kind then error("Drawing allocation failed") end
        local object={Kind=kind,Visible=false,Remove=function(self) self.Removed=true self.Visible=false end}
        table.insert(drawings.Objects,object)
        return object
    end
    ENV.Drawing=drawings
    Settings.SelectedGame="Cold War"
    Window.Visible=false
    for _,board in pairs(Settings.GameBoards) do board.Visible=false end
    local oldBedwarsBoard=BedWarsUI
    local cleanupIndex=#connections+1
    local restoredSpeed=0
    ENV.SunsetColdWarBulletSpeed={Restore=function() restoredSpeed+=1 end}
    Settings.SetupColdWar()
    assert(restoredSpeed==1 and ENV.SunsetColdWarBulletSpeed==nil,"retired Bullet Speed hook was not restored")
    local board=Settings.GameBoards["Cold War"]
    assert(board and board.Name=="RiftCold WarBoard" and BedWarsUI==oldBedwarsBoard,
        "Cold War did not register its own board")
    assert(Persistence.HUDFrames["Cold WarMenu"]==board,"Cold War menu position is not saved")
    local checkButton
    for _,object in ipairs(board:GetDescendants()) do
        assert(object.Name~="Fun" and object.Name~="Dev Tools", "removed Cold War category is still rendered")
        if object:IsA("TextButton") and object.Name=="Check Silent Aim" then checkButton=object end
        if object.Name=="CategoryDivider" then
            assert(object.AnchorPoint.X==0.5 and object.Position.X.Scale==0.5,"divider is not centered")
        end
        if object.Name=="SettingsButton" then
            assert(object.AnchorPoint.Y==0.5 and object.Position.Y.Scale==0.5 and object.Text=="",
                "settings icon still depends on a misaligned text glyph")
            for _,dot in ipairs(object:GetChildren()) do
                if dot.Name=="Dot" then assert(dot.Position.Y.Scale==0.5 and dot.AnchorPoint.Y==0.5) end
            end
        end
    end
    assert(checkButton==nil,"removed Cold War diagnostic card remains")
    local foundBoxes,foundOutlines,foundSpinbot,kitColumn=false,false,false,false
    for _,object in ipairs(board:GetDescendants()) do
        if object:IsA("TextButton") and object.Name=="ESP Boxes" then foundBoxes=true end
        if object:IsA("TextButton") and object.Name=="Player Outlines" then foundOutlines=true end
        if object:IsA("TextButton") and object.Name=="Spinbot" then foundSpinbot=true end
        if object.Name=="KIT" then kitColumn=true end
    end
    assert(foundBoxes and foundOutlines and foundSpinbot and not kitColumn,
        "Cold War visuals or Spinbot missing, or BedWars kit controls leaked")
    assert(findConfig("Player/Cold War/Spinbot/Spinbot"),"Cold War Spinbot settings were not created")
    local boxesControl=findConfig("Visuals/Cold War/ESP Boxes/ESP Boxes")
    local outlinesControl=findConfig("Visuals/Cold War/Player Outlines/Player Outlines")
    assert(not boxesControl.Get() and not outlinesControl.Get() and not boxesControl.GetBind(),
        "Cold War visuals/keybind enabled by default")
    local foe=combatPlayer(2,30)
    local friend=combatPlayer(1,10)
    local deadPlayer=combatPlayer(2,50,0)
    foe.Character,friend.Character,deadPlayer.Character=foe.Fighter.Entity.Model,friend.Fighter.Entity.Model,deadPlayer.Fighter.Entity.Model
    foe.Name,friend.Name,deadPlayer.Name="Enemy","Teammate","Dead"
    local function prepareBody(model,health)
        local head,torso=model:FindFirstChild("Head"),model:FindFirstChild("UpperTorso")
        head.Size,torso.Size=Vector3.new(2,1,1),Vector3.new(2,2,1)
        new("NumberValue",{Name="Health",Value=health},head)
        new("NumberValue",{Name="Health",Value=health},torso)
        model:FindFirstChildOfClass("Humanoid").Health=1
    end
    prepareBody(foe.Character,50)
    prepareBody(friend.Character,50)
    prepareBody(deadPlayer.Character,0)
    local savedPlayers=Players.GetPlayers
    Players.GetPlayers=function() return {LocalPlayer,foe,friend,deadPlayer} end
    local function liveColdWarVisuals()
        local boxes,outlines={},{}
        for _,object in ipairs(drawings.Objects) do
            if not object.Removed and object.Kind=="Square" and object.ZIndex==2 then table.insert(boxes,object) end
            if not object.Removed and object.Kind=="Square" and object.ZIndex==1 then table.insert(outlines,object) end
        end
        return boxes,outlines
    end
    local function nativeState(model)
        local state={}
        for _,part in ipairs(model:GetDescendants()) do
            state[part]={Parent=part.Parent,Size=part.Size,CFrame=part.CFrame,Health=part.Health,Value=part.Value}
        end
        return state
    end
    local nativeBefore=nativeState(foe.Character)
    boxesControl.SetBind(Enum.KeyCode.Q)
    UIS.InputBegan:Fire({UserInputType=Enum.UserInputType.Keyboard,KeyCode=Enum.KeyCode.Q},false)
    assert(boxesControl.Get(),"assigned Cold War keybind did not enable ESP")
    outlinesControl.Set(true)
    local boxes,outlines=liveColdWarVisuals()
    assert(#boxes==2 and #outlines==4,"Cold War did not filter limb death/self or include teammates")
    for _,outline in ipairs(outlines) do assert(outline.Visible and not outline.Filled) end
    local boxColor,outlineColor=color(0.4,0.5,0.8),color(0.1,0.7,0.6)
    findConfig("Visuals/Cold War/ESP Boxes/Color").Set(boxColor)
    findConfig("Visuals/Cold War/Player Outlines/Color").Set(outlineColor)
    findConfig("Visuals/Cold War/ESP Boxes/Show Names").Set(false)
    for _,box in ipairs(boxes) do
        assert(box.Visible and box.Size.X>0 and box.Size.Y>0,
            "Cold War boxes were not projected around characters")
        assert(box.Color==boxColor,"box color was ignored")
    end
    for _,object in ipairs(drawings.Objects) do
        if not object.Removed and object.Kind=="Text" and (object.Text=="Enemy" or object.Text=="Teammate") then
            assert(not object.Visible,"name setting was ignored")
        end
    end
    for _,outline in ipairs(outlines) do assert(outline.Color==outlineColor) end
    local nativeAfter=nativeState(foe.Character)
    for part,state in pairs(nativeBefore) do
        assert(nativeAfter[part],"Cold War removed a body child")
        for key,value in pairs(state) do assert(nativeAfter[part][key]==value,"Cold War modified a body property") end
    end
    for part in pairs(nativeAfter) do assert(nativeBefore[part],"Cold War added an Instance to a character") end
    local oldModel=foe.Character
    local respawn=combatPlayer(2,70)
    foe.Character=respawn.Fighter.Entity.Model
    prepareBody(foe.Character,50)
    RunService.RenderStepped:Fire(1/60)
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==2 and #outlines==4,"respawn duplicated Cold War visuals")
    assert(not oldModel:FindFirstChild("RiftColdWarOutline"),"outline was attached to a character")
    local head=foe.Character:FindFirstChild("Head")
    head.Position=Vector3.new(4000,0,100)
    head.CFrame=CFrame.new(head.Position)
    RunService.RenderStepped:Fire(1/60)
    boxes,outlines=liveColdWarVisuals()
    local hiddenBoxes=0
    for _,box in ipairs(boxes) do if not box.Visible then hiddenBoxes+=1 end end
    local hiddenOutlines=0
    for _,outline in ipairs(outlines) do if not outline.Visible then hiddenOutlines+=1 end end
    assert(hiddenBoxes==1 and hiddenOutlines==2,"off-screen Drawings were not hidden")
    head.Position=Vector3.new(70,0,100)
    head.CFrame=CFrame.new(head.Position)
    friend.Character:FindFirstChild("Head"):FindFirstChild("Health").Value=0
    RunService.RenderStepped:Fire(1/60)
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==1 and #outlines==2,"dead Cold War player kept visuals")
    foe.Character:SetAttribute("Ragdolled",true)
    RunService.RenderStepped:Fire(1/60)
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==0 and #outlines==0,"ragdolled Cold War player kept visuals")
    foe.Character:SetAttribute("Ragdolled",nil)
    RunService.RenderStepped:Fire(1/60)
    board.Visible=true
    local mode=LocalPlayer.CameraMode
    onMenuVisibility()
    assert(LocalPlayer.CameraMode==mode,"Cold War menu replaced the native camera mode")
    RunService.RenderStepped:Fire(1/60)
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==0 and #outlines==0,"Cold War visuals did not pause for the menu")
    board.Visible=false
    onMenuVisibility()
    outlinesControl.Set(false)
    RunService.RenderStepped:Fire(1/60)
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==1 and #outlines==0,"outlines could not be disabled independently")
    outlinesControl.Set(true)
    boxesControl.Set(false)
    boxes,outlines=liveColdWarVisuals()
    assert(#outlines==2 and not boxes[1].Visible,"body outlines required boxes to be on")
    outlinesControl.Set(false)
    boxesControl.Set(false)
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==0 and #outlines==0,"disabled Cold War visuals remained")
    drawings.FailKind="Text"
    boxesControl.Set(true)
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==0 and #outlines==0,"failed Drawing creation leaked partial objects")
    drawings.FailKind=nil
    Settings.ColdWarVisuals.Apply()
    for i=cleanupIndex,#connections do connections[i]:Disconnect() end
    Settings.ColdWarVisuals.Apply()
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==0 and #outlines==0,"Cold War unload left visuals or recreated them")
    ENV.Drawing={}
    local unsupportedStart=#connections+1
    Settings.SetupColdWar()
    assert(not Settings.ColdWarVisuals.Available,"missing Drawing API was accepted")
    Settings.ColdWarVisuals.BoxesOn=true
    Settings.ColdWarVisuals.OutlinesOn=true
    Settings.ColdWarVisuals.Apply()
    boxes,outlines=liveColdWarVisuals()
    assert(#boxes==0 and #outlines==0,"unsupported renderer modified the scene")
    for i=unsupportedStart,#connections do connections[i]:Disconnect() end
    ENV.Drawing=nil
    Players.GetPlayers=savedPlayers
    print("PASS Cold War Drawing: boxes/body outlines and colors, independent toggles, names/binds, limb death/ragdoll/respawn, no character edits, off-screen/menu/unload cleanup, allocation failure and missing API")
end)();

(function()
    local savedPlayers,oldDrawing=Players.GetPlayers,ENV.Drawing
    local savedFind=workspace.FindFirstChild
    local oldLocalTeam=LocalPlayer.Team
    LocalPlayer.Team={Name="NATO"}
    local foe=combatPlayer(2,30)
    local friend=combatPlayer(1,10)
    foe.Team,friend.Team={Name="PACT"},LocalPlayer.Team
    foe.Character,friend.Character=foe.Fighter.Entity.Model,friend.Fighter.Entity.Model
    foe.Name,friend.Name="ESPEnemy","ESPFriend"
    function foe:GetAttribute(name) return name=="TeamID" and 2 or name=="ClassType" and "Sniper" or nil end
    function friend:GetAttribute(name) return name=="TeamID" and 1 or nil end
    for _,p in ipairs({foe,friend}) do
        local head,torso=p.Character:FindFirstChild("Head"),p.Character:FindFirstChild("UpperTorso")
        head.Size,torso.Size=Vector3.new(2,1,1),Vector3.new(2,2,1)
        local health=new("NumberValue",{Name="Health",Value=20},head)
        health:SetAttribute("MaxHealth",100)
        local torsoHealth=new("NumberValue",{Name="Health",Value=20},torso)
        torsoHealth:SetAttribute("MaxHealth",100)
        p.Character:FindFirstChildOfClass("Humanoid").MaxHealth=100
    end
    new("Tool",{Name="Rifle"},foe.Character)
    local cv=new("Folder",{Name="CharacterValues"},foe.Character)
    new("BoolValue",{Name="Unconscious",Value=true},cv)
    Players.GetPlayers=function() return {LocalPlayer,foe,friend} end
    Window.Visible=false
    for _,board in pairs(Settings.GameBoards) do board.Visible=false end
    raycastFailure,raycastResult=false,nil
    for _,gameName in ipairs({"Cold War","Rivals","BedWars","Project Delta"}) do
        local drawings={Objects={}}
        function drawings.new(kind)
            local object={Kind=kind,Visible=false,Remove=function(self) self.Removed=true self.Visible=false end}
            table.insert(drawings.Objects,object) return object
        end
        ENV.Drawing=drawings Settings.SelectedGame=gameName
        local cleanupStart=#connections+1
        local configStart=#ConfigControls+1
        local options=Settings.SetupPlayerESP(gameName,gameName=="Rivals" and function(p) return p.Character end or nil)
        local function set(name,value)
            for i=configStart,#ConfigControls do
                local c=ConfigControls[i]
                if c.Key=="Visuals/"..gameName.."/ESP Boxes/"..name then c.Set(value) return end
            end
            error("missing ESP control "..gameName.."/"..name)
        end
        local function visible(kind,z)
            local objects={}
            for _,o in ipairs(drawings.Objects) do
                if not o.Removed and o.Visible and o.Kind==kind and (not z or o.ZIndex==z) then table.insert(objects,o) end
            end
            return objects
        end
        set("ESP Boxes",true) set("Tracers",true) set("Skeleton",true) set("Head Dot",true)
        assert(#visible("Square",2)==2 and #visible("Line")==4 and #visible("Circle")==2,
            gameName.." did not share boxes, skeletons, tracers and head dots")
        local shifted={}
        for _,part in ipairs(foe.Character:GetChildren()) do
            if part:IsA("BasePart") then
                shifted[part]=part.Position
                part.Position=part.Position+Vector3.new(4000,0,0)
                part.CFrame=CFrame.new(part.Position)
            end
        end
        options.Apply()
        local edgeFound=false
        for _,object in ipairs(visible("Text")) do
            if object.Text and object.Text:find("ESPEnemy",1,true) then
                edgeFound=object.Position.X>=0 and object.Position.X<=Camera.ViewportSize.X
            end
        end
        assert(#visible("Square",2)==1 and edgeFound,
            gameName.." lost the off-screen player instead of showing an edge indicator")
        for part,position in pairs(shifted) do
            part.Position,part.CFrame=position,CFrame.new(position)
        end
        options.Apply()
        assert(#visible("Square",2)==2,gameName.." did not restore the on-screen box")
        foe.Character:SetAttribute("IsNPC",true)
        options.Apply()
        assert(#visible("Square",2)==1,gameName.." showed an NPC-marked model")
        foe.Character:SetAttribute("IsNPC",nil)
        options.Apply()
        assert(#visible("Square",2)==2,gameName.." did not restore player ESP")
        local bar=visible("Square",5)[1]
        assert(bar and math.abs(bar.Size.Y-1.2)<1e-6,"limb max health was ignored")
        local class,weapon,downed=false,false,false
        for _,o in ipairs(visible("Text")) do
            class=class or o.Text=="Sniper"
            weapon=weapon or o.Text:find("Rifle")~=nil
            downed=downed or o.Text=="DOWNED"
        end
        assert(class and weapon and downed,"ESP metadata was missing")
        local leg=new("BasePart",{Name="Left Leg",Position=Vector3.new(15,-2,100),Size=Vector3.new(1,2,1)},foe.Character)
        options.Apply()
        local wide=false
        for _,box in ipairs(visible("Square",2)) do wide=wide or box.Size.X>=15 end
        assert(wide,"head-to-foot ESP box did not follow a sideways/prone body")
        table.remove(foe.Character.children,table.find(foe.Character.children,leg)) leg:Destroy()
        options.Apply()
        set("Draw Boxes",false)
        assert(#visible("Square",2)==0 and #visible("Line")==4,"box style disabled independent overlays")
        set("Draw Boxes",true) set("Show Teammates",false)
        if gameName=="Cold War" or gameName=="Project Delta" then
            assert(options.ShowAllPlayers and #visible("Square",2)==2,
                "Show All did not include the loaded teammate")
            set("Show All Players",false)
        end
        assert(#visible("Square",2)==1 and #visible("Line")==2,"team visibility ignored")
        local wall={IsDescendantOf=function() return false end}
        raycastResult={Instance=wall} clockNow+=1 options.Apply()
        assert(visible("Square",2)[1].Transparency==0.55,"hidden enemy was not dimmed")
        set("Visible Only",true)
        assert(#visible("Square",2)==0 and #visible("Line")==0 and #visible("Text")==0,"hidden enemy retained ESP")
        if gameName=="Cold War" then
            local priorAim=Settings.ColdWarAim
            local priorCharacter=LocalPlayer.Character
            LocalPlayer.Character=new("Model",{Name="LocalESPCharacter"})
            local rifle=new("Tool",{Name="EquippedRifle"},LocalPlayer.Character)
            local cover=new("BasePart",{Name="ThinCover",Position=Vector3.new(0,0,40)})
            Settings.ColdWarAim={PenetrationAt=function(tool)
                assert(tool)
                return 2
            end}
            raycastResult=function(origin,direction,params)
                if params.FilterType==Enum.RaycastFilterType.Include then
                    return {Instance=cover,Position=Vector3.new(0,0,41)}
                end
                if origin==Camera.CFrame.Position then
                    return {Instance=cover,Position=Vector3.new(0,0,40)}
                end
                return {Instance=foe.Character:FindFirstChild("Head"),Position=foe.Character:FindFirstChild("Head").Position}
            end
            clockNow+=1 options.Apply()
            local allowed,team,distance,direct,wallbang=options.Allow(foe,foe.Character,Camera)
            assert(#visible("Square",2)==1 and visible("Square",2)[1].Color==options.WallbangColor,
                "penetrable cover did not show the enemy in ESP: "..tostring(allowed).."/"..tostring(wallbang).."/"..#visible("Square",2))
            raycastResult=function(origin,direction,params)
                if params.FilterType==Enum.RaycastFilterType.Include then
                    return {Instance=cover,Position=Vector3.new(0,0,45)}
                end
                return {Instance=cover,Position=Vector3.new(0,0,40)}
            end
            clockNow+=1 options.Apply()
            assert(#visible("Square",2)==0,"cover thicker than penetration was marked wallbangable")
            rifle:Destroy() cover:Destroy()
            Settings.ColdWarAim=priorAim
            LocalPlayer.Character:Destroy()
            LocalPlayer.Character=priorCharacter
        end
        raycastResult=nil clockNow+=1 options.Apply()
        assert(#visible("Square",2)==1 and #visible("Line")==2,"visible enemy was not restored")
        set("Unlimited Range",false)
        set("Max Distance",25)
        assert(#visible("Square",2)==0,"maximum ESP distance ignored")
        if gameName=="Cold War" or gameName=="Project Delta" then
            set("Show All Players",true)
            assert(#visible("Square",2)==2,"Show All did not bypass distance and teammate filters")
            raycastResult={Instance=wall} clockNow+=1 options.Apply()
            assert(#visible("Square",2)==0,"Visible Only did not filter blocked players with Show All on")
            set("Visible Only",false)
            assert(#visible("Square",2)==2,"Show All did not show loaded players through terrain")
            raycastResult=nil clockNow+=1 options.Apply()
            set("Show All Players",false)
        end
        set("Max Distance",1000)
        set("Unlimited Range",true)
        local cacheCasts=#casts options.Apply() options.Apply()
        assert(#casts==cacheCasts,"visibility rays were not cached")
        clockNow+=0.02 options.Apply()
        assert(#casts>cacheCasts,"default visibility refresh still waits 120ms")
        set("Visibility Refresh",0)
        cacheCasts=#casts options.Apply()
        assert(#casts>cacheCasts,"zero visibility interval did not update every pass")
        set("Visibility Refresh",16)
        local palette={}
        for i,name in ipairs({"Name Color","Class Color","Info Color","Status Color","Tracer Color",
            "Skeleton Color","Head Dot Color","Border Color","Low Health Color","Full Health Color","Health Background Color"}) do
            palette[name]=color(i/20,0.2,0.3)
            set(name,palette[name])
        end
        assert(not options.UsePlayerColors,"choosing an element color did not disable inherited player colors")
        local nameFound=false
        for _,o in ipairs(visible("Text")) do
            if o.Text=="ESPEnemy" then assert(o.Color==palette["Name Color"]) nameFound=true end
            if o.Text=="Sniper" then assert(o.Color==palette["Class Color"]) end
            if o.Text:find("Rifle") then assert(o.Color==palette["Info Color"]) end
            if o.Text=="DOWNED" then assert(o.Color==palette["Status Color"]) end
        end
        assert(nameFound,"colored name label missing")
        for _,o in ipairs(visible("Line")) do
            assert(o.Color==palette[o.From.Y==Camera.ViewportSize.Y and "Tracer Color" or "Skeleton Color"])
        end
        for _,o in ipairs(visible("Circle")) do assert(o.Color==palette["Head Dot Color"]) end
        assert(visible("Square",0)[1].Color==palette["Border Color"])
        assert(visible("Square",4)[1].Color==palette["Health Background Color"])
        assert(visible("Square",5)[1].Color==palette["Low Health Color"])
        if gameName=="Cold War" then
            local folder=new("Folder",{Name="Vehicles"})
            local vehicle=new("Model",{Name="Tank"},folder)
            vehicle:SetAttribute("CrewTeam","PACT") vehicle:SetAttribute("VehicleType","APC")
            local root=new("BasePart",{Name="RootPart",Position=Vector3.new(40,0,100)},vehicle)
            workspace.FindFirstChild=function(_,name) return name=="Vehicles" and folder or nil end
            options.Apply()
            local vehicleColor=color(0.7,0.2,0.9)
            set("Vehicle Color",vehicleColor)
            local labeled=false
            for _,o in ipairs(visible("Text")) do
                if o.Text:find("APC") then labeled=true assert(o.Color==vehicleColor) end
            end
            assert(labeled,"Cold War vehicle label missing")
            set("Vehicles",false)
            for _,o in ipairs(visible("Text")) do assert(not o.Text:find("APC"),"disabled vehicle label remained") end
            workspace.FindFirstChild=savedFind
        end
        Window.Visible=true options.Apply()
        assert(#visible("Square")==0 and #visible("Line")==0 and #visible("Text")==0,"ESP covered menu")
        Window.Visible=false options.Apply()
        set("ESP Boxes",false)
        assert(#visible("Square")==0 and #visible("Line")==0 and #visible("Text")==0,"disable leaked ESP")
        set("ESP Boxes",true)
        for i=cleanupStart,#connections do connections[i]:Disconnect() end
        options.Apply()
        for _,o in ipairs(drawings.Objects) do assert(o.Removed,"unload leaked Drawing") end
    end
    Players.GetPlayers,ENV.Drawing,workspace.FindFirstChild=savedPlayers,oldDrawing,savedFind
    LocalPlayer.Team=oldLocalTeam
    print("PASS shared ESP: Cold War/Rivals/BedWars/Project Delta boxes, NPC filter, health/class/weapon/status, skeletons/tracers/head dots, independent styles, enemy/team colors, wall visibility/dimming/range, cached rays, vehicles, menu/disable/unload")
end)()
