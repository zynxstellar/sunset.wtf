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
function Vector.new(x,y) return setmetatable({X=x,Y=y},meta) end
local UDim2={new=function(xs,xo,ys,yo) return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}} end}
local Enum={UserInputType={MouseButton1="click",MouseMovement="move",Touch="touch"}}
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
-- INSERT_MENU_DRAG
Settings.MakeMenuDraggable(frame)
local function event(kind,x,y) return {UserInputType=kind,Position=Vector.new(x,y)} end
local function click(x,y) local e=event("click",x,y) UIS.InputBegan:Fire(e) return e end
local function move(x,y) UIS.InputChanged:Fire(event("move",x,y)) end
local function release() UIS.InputEnded:Fire(event("click",0,0)) end
click(110,190) move(150,240) release()
assert(frame.Position.X.Offset==40 and frame.Position.Y.Offset==50,"background dragging failed")
frame.Position=UDim2.new(0.5,0,0.5,0)
for _,point in ipairs({{150,140},{270,140},{417,250},{90,90}}) do
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
for _,c in ipairs(connections) do c:Disconnect() end
click(110,190) move(500,500)
assert(frame.Position.X.Offset==30,"unloaded drag handler still moved the window")
print("PASS menu drag: background, buttons/inputs/scrollbars, clipping, touch ownership, focus, close and unload")
