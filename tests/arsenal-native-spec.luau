local Settings={}
local V={}
local meta={}
function V.new(x,y,z) return setmetatable({X=x,Y=y,Z=z,Magnitude=math.sqrt(x*x+y*y+z*z)},meta) end
meta.__sub=function(a,b) return V.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
meta.__add=function(a,b) return V.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
-- INSERT_ARSENAL_ADAPTERS
local source={Origin=V.new(0,0,0),Direction=V.new(0,0,100)}
local corrected={Origin=source.Origin,Direction=V.new(100,0,0)}
local hit=V.new(70,0,0)
local eligible, active, failNative, failIdentify=true,true,false,false
local received, shots, calls=nil,{},0
local api={cast=function(ray,ignore,tag)
    calls+=1
    received=ray
    assert(tag=="native extra", "cast varargs lost")
    if failNative then error("native cast failed") end
    return nil,hit,nil,"tail"
end}
local original=api.cast
local adapter=Settings.MakeArsenalCastAdapter({
    IsShot=function() if failIdentify then error("unloaded weapon") end; return eligible end,
    Transform=function(ray,ignore) if active then return corrected,ignore end end,
    OnShot=function(origin,destination) table.insert(shots,{origin,destination}) end,
})
assert(adapter.Install(api) and adapter.Install(api))
local result=table.pack(api.cast(source,{},"native extra"))
assert(result.n==4 and result[1]==nil and result[2]==hit and result[3]==nil and result[4]=="tail")
assert(calls==1 and received==corrected and adapter.Redirects==1)
assert(#shots==1 and shots[1][2]==hit,"tracer used intended target instead of actual hit")
eligible=false
api.cast(source,{},"native extra")
assert(received==source and #shots==1,"non-shot query was changed or traced")
eligible,active=true,false
api.cast(source,{},"native extra")
assert(received==source and #shots==2,"normal manual shot was not traced")
failNative=true
local ok,err=pcall(api.cast,source,{},"native extra")
assert(not ok and tostring(err):find("native cast failed",1,true))
failNative=false
api.cast(source,{},"native extra")
assert(#shots==3,"native error left recursion guard stuck")
failIdentify=true
assert(pcall(api.cast,source,{},"native extra"),"adapter identification error broke native cast")
failIdentify=false
adapter.Close()
assert(api.cast==original,"unload did not restore native cast")
local newer=function() end
local second=Settings.MakeArsenalCastAdapter({IsShot=function() return false end})
assert(second.Install(api));api.cast=newer;second.Close()
assert(api.cast==newer,"unload replaced a later owner's cast")
print("PASS Arsenal native shots: supplied cast signature, exact return slots/varargs, redirected/manual hit tracers, unrelated-query rejection, failure and unload")
local state={gun={},equipped="primary",primarymode="1",ammocount=7,ammo2count=3}
local ammo=Settings.MakeArsenalAmmo({Resolve=function() return state end,Amount=function() return 99 end})
ammo.Set(true)
assert(state.ammocount==99 and state.ammo2count==3)
state.ammocount=98;ammo.Tick();ammo.Set(false)
assert(state.ammocount==98,"disable discarded latest native ammo decrement")
state.equipped="secondary";ammo.Set(true)
assert(state.ammo2count==99)
state.ammo2count=25;ammo.Set(false)
assert(state.ammo2count==25,"disable overwrote server ammo update")
state.equipped="melee";ammo.Set(true);ammo.Tick()
assert(not ammo.Applied,"melee ammo changed")
state.equipped="primary";state.primarymode="2";ammo.Tick()
assert(not ammo.Applied,"grenade mode consumed regular ammo override")
ammo.Close()
print("PASS Arsenal ammo: observed State fields, active slot only, native/server update preservation, melee/grenade exclusion and unload")
local now,destroyed=0,0
local trails=Settings.MakeBulletTracers({Now=function() return now end,Color="blue",
    Create=function() return {Destroy=function() destroyed+=1 end} end})
trails.Emit(source.Origin,hit);assert(#trails.Paths==0)
trails.Set(true)
for i=1,120 do trails.Emit(source.Origin,hit) end
assert(#trails.Paths==96 and destroyed==24,"tracers not bounded")
now=1;trails.Tick();assert(#trails.Paths==0 and destroyed==120)
trails.Emit(source.Origin,hit);trails.Set(false);assert(#trails.Paths==0)
trails.Set(true);trails.Emit(source.Origin,hit);trails.Close()
assert(#trails.Paths==0 and trails.Closed)
print("PASS bullet tracers: opt-in, bounded live paths, expiry, disable/unload cleanup")

local state={Restored=false}
local worldPosition=V.new(0,0,0)
local workspace={CurrentCamera={CFrame={Position=worldPosition}}}
local weapon={Range={Value=100}}
function weapon:FindFirstChild(name) return self[name] end
local values={equipped="primary",gun=weapon}
local RivalsAim={ResolveArsenalModule=function() return values end}
local function typeof(value) return type(value)=="table" and value.Kind or type(value) end
-- INSERT_NATIVE_ELIGIBILITY
local ray={Kind="Ray",Origin=worldPosition,Direction=V.new(0,0,100)}
assert(eligibleQuery(ray,{}),"supplied firebullet ray was not recognized")
ray.Direction=V.new(0,0,6)
assert(not eligibleQuery(ray,{}),"six-stud camera correction ray treated as a shot")
ray.Direction=V.new(0,0,100);ray.Origin=V.new(10,0,0)
assert(not eligibleQuery(ray,{}),"unrelated world ray treated as a shot")
ray.Origin=worldPosition;values.equipped="melee"
assert(not eligibleQuery(ray,{}),"melee ray redirected")
values.equipped="primary";weapon.Projectile={}
assert(not eligibleQuery(ray,{}),"physical projectile handled as hitscan")
weapon.Projectile=nil;state.Restored=true
assert(not eligibleQuery(ray,{}),"unloaded adapter still processes shots")
print("PASS Arsenal native query eligibility: exact equipped range/camera origin, melee/projectile/correction exclusion, unload")
