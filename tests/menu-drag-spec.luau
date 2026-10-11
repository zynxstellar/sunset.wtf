local function signal()
    local handlers={}
    return {Connect=function(_,fn)
        local entry={Fn=fn,Active=true}
        table.insert(handlers,entry)
        return {Disconnect=function() entry.Active=false end}
    end,Fire=function(_,...) for _,entry in ipairs(handlers) do if entry.Active then entry.Fn(...) end end end}
end
local Vector={}
local meta={__sub=function(a,b) return Vector.new(a.X-b.X,a.Y-b.Y) end}
meta.__mul=function(a,b) return Vector.new(a.X*b,a.Y*b) end
local Vector2=Vector
local workspace={CurrentCamera={ViewportSize={X=1280,Y=720}}}
function Vector.new(x,y) return setmetatable({X=x,Y=y},meta) end
local UDim2={new=function(xs,xo,ys,yo) return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}} end}
local Enum={UserInputType={MouseButton1="click",MouseMovement="move",Touch="touch"},ScrollingDirection={X="x",Y="y"}}
local UIS={InputBegan=signal(),InputChanged=signal(),InputEnded=signal(),WindowFocusReleased=signal()}
local Settings={}
local connections={}
local function track(c) table.insert(connections,c) return c end
local frame={Visible=true,Parent={},AbsolutePosition=Vector.new(100,100),AbsoluteSize=Vector.new(500,400),
    Position=UDim2.new(0.5,0,0.5,0),Children={},Visibility=signal()}
function frame:GetDescendants() return self.Children end
function frame:GetPropertyChangedSignal() return self.Visibility end
local function child(class,x,y,w,h,parent)
    local o={Class=class,Visible=true,AbsolutePosition=Vector.new(x,y),AbsoluteSize=Vector.new(w,h),Parent=parent or frame}
    function o:IsA(kind) return kind==self.Class or kind=="GuiObject" or (kind=="GuiButton" and self.Class=="TextButton") end
    table.insert(frame.Children,o)
    return o
end
local button=child("TextButton",130,130,100,35)
local input=child("TextBox",250,130,100,35)
local scroll=child("ScrollingFrame",120,220,300,150)
scroll.ClipsDescendants=true
local clipped=child("TextButton",450,240,100,30,scroll)
local horizontal=child("ScrollingFrame",120,380,300,80)
horizontal.ScrollingDirection=Enum.ScrollingDirection.X
-- INSERT_MENU_DRAG
Settings.MakeMenuDraggable(frame)
local function event(kind,x,y) return {UserInputType=kind,Position=Vector.new(x,y)} end
local function click(x,y) local e=event("click",x,y) UIS.InputBegan:Fire(e) return e end
local function move(x,y) UIS.InputChanged:Fire(event("move",x,y)) end
local function release() UIS.InputEnded:Fire(event("click",0,0)) end
click(110,190) move(150,240) release()
assert(frame.Position.X.Offset==40 and frame.Position.Y.Offset==50,"background dragging failed")
frame.Position=UDim2.new(0.5,0,0.5,0)
for _,point in ipairs({{150,140},{270,140},{417,250},{90,90},{200,455}}) do
    click(point[1],point[2]) move(500,400) release()
    assert(frame.Position.X.Offset==0,"interactive control or outside click dragged the window")
end
click(470,250) move(480,260) release()
assert(frame.Position.X.Offset==10,"clipped button incorrectly blocked background drag")
frame.Position=UDim2.new(0.5,0,0.5,0)
local touch=event("touch",110,190)
UIS.InputBegan:Fire(touch)
UIS.InputChanged:Fire(event("touch",400,400))
assert(frame.Position.X.Offset==0,"unrelated touch stole the drag")
touch.Position=Vector.new(140,200) UIS.InputChanged:Fire(touch)
assert(frame.Position.X.Offset==30 and frame.Position.Y.Offset==10)
UIS.WindowFocusReleased:Fire()
touch.Position=Vector.new(400,400) UIS.InputChanged:Fire(touch)
assert(frame.Position.X.Offset==30,"lost focus left dragging active")
click(110,190) frame.Visible=false frame.Visibility:Fire() frame.Visible=true move(500,500)
assert(frame.Position.X.Offset==30,"menu reopening resumed an old drag")
local category=child("Frame",450,120,100,110)
category.Position=UDim2.new(0,350,0,20)
category.Visibility=signal()
function category:GetDescendants() return {} end
function category:GetPropertyChangedSignal() return self.Visibility end
Settings.MakeMenuDraggable(category,frame)
local menuX=frame.Position.X.Offset
click(470,140) move(490,170) release()
assert(category.Position.X.Offset==370 and category.Position.Y.Offset==50,
    "category did not drag independently")
assert(frame.Position.X.Offset==menuX,"dragging a category also moved the whole menu")
click(470,140)
frame.Visible=false frame.Visibility:Fire() frame.Visible=true move(550,300)
assert(category.Position.X.Offset==370,"closing menu left category drag active")
frame.Position=UDim2.new(0.5,0,0.5,0)
click(110,190) move(5000,5000) release()
assert(frame.Position.X.Offset==680 and frame.Position.Y.Offset==220,"menu escaped viewport on drag")
frame.Position=UDim2.new(0.5,0,0.5,0)
click(110,190) move(-5000,-5000) release()
assert(frame.Position.X.Offset==-100 and frame.Position.Y.Offset==-100,"drag did not clamp to top left")
frame.Position=UDim2.new(0.5,30,0.5,0)
for _,c in ipairs(connections) do c:Disconnect() end
click(110,190) move(500,500)
assert(frame.Position.X.Offset==30,"unloaded drag handler still moved the window")
print("PASS menu drag: background, buttons/inputs/scrollbars, clipping, touch ownership, focus, close and unload")
