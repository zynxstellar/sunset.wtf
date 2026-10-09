local CFrame = {}
local frames = {}
function frames.__mul(a,b) return setmetatable({Position=a.Position,X=b.X,Y=b.Y,Z=b.Z},frames) end
function frames:ToOrientation() return self.X,self.Y,self.Z end
frames.__index=frames
function CFrame.new(position) return setmetatable({Position=position,X=0,Y=0,Z=0},frames) end
function CFrame.Angles(x,y,z) return setmetatable({X=x,Y=y,Z=z},frames) end
local Enum = { RenderPriority = {Camera={Value=200},Last={Value=300}} }
local Settings = {}
local hum = {Parent={},Health=100,AutoRotate=true}
local root = {Parent={},Position={},CFrame=CFrame.new({})}
local LocalPlayer = {Character={FindFirstChildOfClass=function() return hum end,
    FindFirstChild=function() return root end}}
local stepped
local RunService={Stepped={Connect=function(_,fn) stepped=fn return {Disconnect=function() end} end},Bindings={}}
function RunService:BindToRenderStep(name,priority,fn)
    assert(not self.Bindings[name],"spin camera binding collision")
    self.Bindings[name]={Priority=priority,Run=fn}
end
function RunService:UnbindFromRenderStep(name) self.Bindings[name]=nil end
local connections={}
local function track(c) table.insert(connections,c) end
local controls={}
local Elements={Toggle=function(_,name,_,callback)
    controls[name]=callback return {Set=callback}
end,Slider=function(_,name,_,_,_,_,callback) controls[name]=callback end}
-- INSERT_SPIN_PRODUCTION
local toggle=buildSpinbot({})
local before,after=RunService.Bindings.RiftSpinCamera1Before,RunService.Bindings.RiftSpinCamera1After
assert(before.Priority<200 and after.Priority>303,"spin overlaps native camera/viewmodel/aim update")
local camera={CFrame={Sentinel="native mouse look"}}
local initialCamera=camera.CFrame
toggle.Set(true)
controls["Spin Speed"](360)
local facing=0
for frame=1,4 do
    stepped(0,0.05)
    assert(not hum.AutoRotate)
    before.Run()
    local _,nativeYaw=root.CFrame:ToOrientation()
    assert(math.abs(nativeYaw-facing)<0.00001,"camera update saw the spinning body yaw")
    -- Native mouse look continues normally between the two bindings.
    facing+=0.07
    root.CFrame=CFrame.new(root.Position)*CFrame.Angles(0,facing,0)
    after.Run()
    local _,spinYaw=root.CFrame:ToOrientation()
    assert(math.abs(spinYaw-math.rad(18*frame))<0.00001,"body stopped spinning")
    assert(camera.CFrame==initialCamera,"spin overwrote the native camera")
end
local moved={}
root.Position=moved
before.Run()
assert(root.CFrame.Position==moved,"camera stabilization reset player movement")
after.Run()
toggle.Set(false)
assert(hum.AutoRotate and math.abs(select(2,root.CFrame:ToOrientation())-facing)<0.00001,
    "disable did not restore gameplay facing")
local disabledFrame=root.CFrame
before.Run() after.Run()
assert(root.CFrame==disabledFrame,"disabled spin modified root")
toggle.Set(true)
stepped(0,0.05)
Settings.FlyEnabled=true
stepped(0,0.05)
assert(hum.AutoRotate,"flight conflict did not restore body")
before.Run() after.Run()
Settings.FlyEnabled=false
stepped(0,0.05)
hum.Sit=true
stepped(0,0.05)
assert(hum.AutoRotate,"seated character kept spinning")
hum.Sit=false
buildSpinbot({})
assert(RunService.Bindings.RiftSpinCamera2Before and RunService.Bindings.RiftSpinCamera1Before,
    "multiple game modules shared camera bindings")
for _,c in ipairs(connections) do c:Disconnect() end
assert(next(RunService.Bindings)==nil and hum.AutoRotate,"unload retained spin camera bindings")
print("PASS Spinbot camera: native facing during camera/viewmodel, mouse look retained, body spin after rendering, movement, disable/seat/flight/unload, unique bindings")
