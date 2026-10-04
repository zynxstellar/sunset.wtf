-- Run real slider callbacks with pointer/scroll mocks, without a live Roblox client.
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
local Enum = { UserInputType = { MouseButton1 = "left", MouseButton2 = "right",
    MouseMovement = "move", Touch = "touch" }, TextTruncate = { AtEnd = "end" } }
local UDim = { new = function(scale, offset) return { Scale = scale, Offset = offset } end }
local UDim2 = { new = function(xs, xo, ys, yo)
    return { X = UDim.new(xs, xo), Y = UDim.new(ys, yo) }
end }
function UDim2.fromOffset(x, y) return UDim2.new(0, x, 0, y) end
function UDim2.fromScale(x, y) return UDim2.new(x, 0, y, 0) end
local Vector2 = { new = function(x, y) return { X = x, Y = y } end }
local T = {}
local Elements, ConfigControls = {}, {}
local task = { spawn = function(fn, ...) fn(...) end }
local UIS = { InputChanged = signal(), InputEnded = signal(), WindowFocusReleased = signal() }
local Gui = { children = {} }
local function new(class, props, parent)
    local obj = { ClassName = class, Parent = parent, children = {}, ZIndex = 1,
        AbsoluteSize = Vector2.new(200, 30), AbsolutePosition = Vector2.new(100, 60),
        InputBegan = signal(), MouseButton1Click = signal(), FocusLost = signal() }
    for key, value in pairs(props) do obj[key] = value end
    function obj:IsA(kind) return self.ClassName == kind end
    if parent then table.insert(parent.children, obj) end
    return obj
end
local function label(parent, text) return new("TextLabel", { Text = text }, parent) end
local function border() end
local function track(connection) return connection end
local function configKey(_, text) return text end
-- INSERT_SLIDER_PRODUCTION
local outer = new("ScrollingFrame", { ScrollingEnabled = false }, Gui)
local scroll = new("ScrollingFrame", { ScrollingEnabled = true }, outer)
local parent = new("Frame", {}, scroll)
local last, calls
calls = 0
local holder = Elements.Slider(parent, "Radius", 50, 1500, 775, "px", function(value)
    last = value
    calls += 1
end)
local area = holder.children[2]
local bar = area.children[1]
local top = holder.children[1]
local number, plus, minus = top.children[2], top.children[3], top.children[4]
local function input(kind, x) return { UserInputType = kind, Position = Vector2.new(x, 90) } end
local function expect(value, message) assert(last == value, message .. ": " .. tostring(last)) end
expect(775, "initial callback")
-- Grab slightly off-center without jumping; pointer updates work outside the slider.
local mouse = input("left", 208)
area.InputBegan:Fire(mouse)
expect(775, "handle grab stays steady")
assert(not scroll.ScrollingEnabled and not outer.ScrollingEnabled, "drag blocks parent scrolling")
UIS.InputChanged:Fire(input("move", 258))
expect(1138, "handle offset preserved during movement")
UIS.InputChanged:Fire(input("move", 1000))
expect(1500, "drag clamps past right edge")
UIS.InputChanged:Fire(input("move", -100))
expect(50, "drag clamps past left edge")
UIS.InputEnded:Fire(input("right", 100))
assert(not scroll.ScrollingEnabled, "unrelated button release keeps dragging")
UIS.InputEnded:Fire(input("left", 100))
assert(scroll.ScrollingEnabled and not outer.ScrollingEnabled, "release restores original scrolling")
UIS.InputChanged:Fire(input("move", 300))
expect(50, "release stops updates")
-- Click anywhere in the larger area to seek, then retain a single touch pointer.
local touch = input("touch", 200)
area.InputBegan:Fire(touch)
expect(775, "track click seeks")
UIS.InputChanged:Fire(input("touch", 300))
expect(775, "second touch ignored")
UIS.InputEnded:Fire(input("touch", 300))
assert(not scroll.ScrollingEnabled, "second touch does not release drag")
touch.Position.X = 250
UIS.InputChanged:Fire(touch)
expect(1138, "captured touch drags")
UIS.WindowFocusReleased:Fire()
assert(scroll.ScrollingEnabled, "focus loss restores scrolling")
touch.Position.X = 300
UIS.InputChanged:Fire(touch)
expect(1138, "focus loss cancels drag")
-- Existing typed values, increments and saved values still use clamping/rounding.
number.Text = "900"
number.FocusLost:Fire()
expect(900, "typed value")
plus.MouseButton1Click:Fire()
expect(901, "increment")
minus.MouseButton1Click:Fire()
expect(900, "decrement")
ConfigControls[1].Set(9999)
expect(1500, "saved value clamped")
number.Text = "nan"
number.FocusLost:Fire()
expect(1500, "invalid text keeps value")
bar.AbsoluteSize.X = 0
area.InputBegan:Fire(input("left", 200))
assert(scroll.ScrollingEnabled, "hidden zero-width slider does not capture")
expect(1500, "zero width leaves value")
assert(sliderNumber(0.56, 0, 1, 0, 0.1) == 0.6, "fractional steps preserved")
local unrestricted=Elements.Slider(parent,"Speed",0,300,16,"",function() end,1,true)
local speedConfig=ConfigControls[2]
speedConfig.Set(10000)
assert(speedConfig.Get()==10000,"typed speed above slider range was capped")
speedConfig.Set(math.huge)
assert(speedConfig.Get()==10000,"infinite speed accepted")
speedConfig.Set(-1)
assert(speedConfig.Get()==0,"negative speed accepted")
print("PASS slider: steady grabs, global drag, touch capture, release/focus cleanup, saved/typed values")
