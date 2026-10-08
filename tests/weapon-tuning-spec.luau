local meta={}
local Vector3={new=function(x,y,z) return setmetatable({X=x,Y=y,Z=z},meta) end}
function meta.__mul(v,n) return Vector3.new(v.X*n,v.Y*n,v.Z*n) end
function meta.__index(v,key)
    if key=="Magnitude" then return math.sqrt(v.X*v.X+v.Y*v.Y+v.Z*v.Z) end
    if key=="Unit" then return v*(1/v.Magnitude) end
    if key=="Lerp" then return function(_,other,t)
        return Vector3.new(v.X+(other.X-v.X)*t,v.Y+(other.Y-v.Y)*t,v.Z+(other.Z-v.Z)*t)
    end end
end
local function typeof(value) return getmetatable(value)==meta and "Vector3" or type(value) end
local function instance(name,parent)
    local value={Name=name,Children={}}
    function value:FindFirstChild(key) return self.Children[key] end
    if parent then parent.Children[name]=value end
    return value
end
local storage=instance("Storage")
local client=instance("Client",storage)
local weapon=instance("Weapon",instance("Tools",client))
local muzzle=instance("Muzzle",weapon)
local dischargeModule=instance("Discharge",muzzle)
local recoilModule=instance("RecoilController",instance("controllers",weapon))
local originalDeviate=function() return Vector3.new(0,1,0) end
local discharge={fire=function() end}
local upvalues={[discharge.fire]={[8]=originalDeviate}}
local debug={getupvalues=function(fn) return upvalues[fn] or {} end}
local springs={}
local function shove(self,impulse) self.Last=impulse end
for _,name in ipairs({"offset","rotation","handle","camera"}) do
    springs[name]={shove=shove}
end
local recoil={getSpring=function(name) return springs[name] end}
local loaded=false
local function rivalsModuleLoaded() return loaded end
local identity=8
local function getthreadidentity() return identity end
local function setthreadidentity(value) identity=value end
local function require(module)
    assert(identity==2)
    if module==dischargeModule then return discharge end
    if module==recoilModule then return recoil end
    error("unexpected module")
end
local hooks={}
local function hookfunction(original,replacement) hooks[original]=replacement return original end
local game={GetService=function(_,name) assert(name=="ReplicatedStorage") return storage end}
local ENV={}
local Settings={SelectedGame="Cold War"}
local clock=0
local os={clock=function() return clock end}
local warnings={}
local function warn(message) table.insert(warnings,message) end
local frame
local RunService={RenderStepped={Connect=function(_,fn) frame=fn return {Disconnect=function() end} end}}
local tracked={}
local function track(value) table.insert(tracked,value) end
local AimTab={Left={}}
local function gameSection(_,_,name) return name end
local controls={}
local Elements={
    Toggle=function(_,name,_,callback) controls[name]=callback end,
    Slider=function(_,name,_,_,_,_,callback) controls[name]=callback end,
}
-- INSERT_WEAPON_TUNING
Settings.SetupColdWarWeaponTuning()
local tuning=Settings.ColdWarWeaponTuning
assert(not hooks[originalDeviate] and not hooks[shove],"disabled tuning installed hooks")
controls["No Spread"](true)
assert(not hooks[originalDeviate],"unloaded firing module was initialized")
loaded=true clock=1 frame()
assert(hooks[originalDeviate],"spread hook did not install")
local direction=Vector3.new(1,0,0)
local spreadShot=hooks[originalDeviate]
assert(spreadShot(direction,1).X==1,"zero spread did not preserve aim direction")
controls["Spread Amount"](50)
local half=spreadShot(direction,1)
assert(math.abs(half.X-0.7071)<0.001 and math.abs(half.Y-0.7071)<0.001,
    "partial spread was not scaled")
controls["Spread Amount"](100)
assert(spreadShot(direction,1).Y==1,"full spread did not preserve native deviation")
controls["No Spread"](false)
assert(spreadShot(direction,1).Y==1,"disabling No Spread did not restore native deviation")
controls["No Recoil"](true)
clock=2 frame()
assert(hooks[shove],"recoil hook did not install")
local recoilShove=hooks[shove]
local impulse=Vector3.new(10,0,0)
recoilShove(springs.camera,impulse)
assert(springs.camera.Last==nil,"zero recoil still added spring impulse")
controls["Recoil Amount"](50)
recoilShove(springs.camera,impulse)
assert(springs.camera.Last.X==5,"partial recoil was not scaled")
local unrelated={shove=shove}
recoilShove(unrelated,impulse)
assert(unrelated.Last==impulse,"other spring impulse was changed")
controls["Recoil Amount"](100)
recoilShove(springs.camera,impulse)
assert(springs.camera.Last.X==10,"full recoil did not preserve native impulse")
controls["No Recoil"](false)
springs.camera.Last=nil
recoilShove(springs.camera,impulse)
assert(springs.camera.Last==impulse,"disabling No Recoil did not restore native impulse")
controls["No Spread"](true) controls["Spread Amount"](0)
controls["No Recoil"](true) controls["Recoil Amount"](0)
tuning.Restore()
springs.camera.Last=nil
assert(spreadShot(direction,1).Y==1,"unload left spread changed")
recoilShove(springs.camera,impulse)
assert(springs.camera.Last==impulse,"unload left recoil changed")
assert(#warnings==0,"weapon tuning emitted an unexpected warning")
print("PASS Cold War weapon tuning: deferred install, independent spread/recoil sliders, unrelated springs, disable and unload restoration")
