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
local CFrame={new=function(p) return {Position=p} end}
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
local function track(c) return c end
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
local mouse={}
local LocalPlayer={CameraMode="LockFirstPerson",GetMouse=function() return mouse end}
local Players={GetPlayers=function() return {LocalPlayer} end}
local UIS={MouseBehavior="LockCenter",MouseIconEnabled=false,TouchEnabled=false,
    IsMouseButtonPressed=function() return false end,GetMouseLocation=function() return Vector2.new(100,100) end}
local ENV={}
local useScriptable=true
local function anyMenuVisible() return Window.Visible or RivalsUI and RivalsUI.Visible or false end
local RivalsAim={Enabled=false,FOVVisible=false,Radius=150}
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
function Elements.Toggle(p,t,d,cb) return addControl(p,t,"toggle",d,cb) end
function Elements.Slider(p,t,a,b,d,s,cb) return addControl(p,t,"number",d,cb) end
Elements.Label=label
local BRAND,SUNSET_BUILD="RIFT","test-k255"
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

RivalsAim.Setup()
assert(hookInstalls==0,"disabled aim installed hooks")
RivalsAim.SetEnabled(true)
assert(RivalsAim.Enabled and hookInstalls==2)
local state=ENV.SunsetRivalsAimHook
state.Active=true
state.Resolve=function() error("target disappeared") end
local result=table.pack(hooks.__namecall(workspace,Vector3.new(),Vector3.new(0,0,100),nil,"last"))
assert(result.n==3 and result[1]=="original result" and result[3]=="third result")
local call=originalCalls[#originalCalls]
assert(call.Args.n==4 and call.Args[3]==nil and call.Args[4]=="last","fallback changed original arguments")
state.Select=function() error("target disappeared") end
assert(hooks.__index(mouse,"Hit")=="original property")
RivalsAim.SetEnabled(false)
hooks.__namecall(workspace,"unchanged",nil)
assert(not state.Active and originalCalls[#originalCalls].Args.n==2)
RivalsAim.SetEnabled(true)
assert(hookInstalls==2,"toggle stacked duplicate hooks")
print("PASS Rivals hooks: lazy install, disabled pass-through, errors preserve calls/results/nil arguments")

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
local radius
for _,c in ipairs(ConfigControls) do if c.Key=="Combat/Rivals/Silent Aim/FOV Radius" then radius=c end end
assert(radius and radius.Kind=="number")
radius.Set(275)
assert(RivalsAim.Radius==275)
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
for _,o in ipairs(BedWarsUI:GetChildren()) do if o.Name=="KIT" then kitColumn=o end end
assert(kitColumn,"shared renderer lost BedWars kit column")
print("PASS BedWars board: original dimensions and kit column retained")
