local Settings = {}
-- INSERT_HUSS_SPEED
local value, writes = nil, 0
local player = {
    GetAttribute=function(_, name) assert(name=="TrollSpeed");return value end,
    SetAttribute=function(_, name, nextValue) assert(name=="TrollSpeed");value=nextValue;writes+=1 end,
}
local base=35.616
local speed=Settings.MakeHussSpeedModifier(player,function() return base end)
speed.Tick(false,33.6)
assert(value==nil and writes==0)
speed.Tick(true,33.6)
assert(value==0.94 and value*base<=33.6)
speed.Tick(true,33.6)
assert(writes==1,"unchanged multiplier was rewritten")
base=36.96
speed.Tick(true,999)
assert(value==0.9 and value*base<=33.6,"catcher exceeded speed limit")
base=41.3952
speed.Tick(true,33.6)
assert(value*base<=33.6,"crossing bonus exceeded speed limit")
speed.Close()
assert(value==nil,"missing native attribute was not restored")
value=1.25
speed.Tick(true,33.6)
value=1.4
speed.Tick(true,33.6)
speed.Close()
assert(value==1.4,"latest native update was not restored")
speed.Tick(true,33.6)
value=1.7
speed.Close()
assert(value==1.7,"disable overwrote a newer native update")
speed.Tick(true,0/0)
assert(value*base<=33.6,"NaN limit bypassed cap")
speed.Close()
assert(value==1.7)
base=100
local ok=speed.Tick(true,33.6)
assert(not ok and value==1.7,"unsupported native minimum changed speed")
base=nil
assert(not speed.Tick(true,33.6) and value==1.7,"missing profile changed speed")
print("PASS Huss speed limit: runner/catcher/crossing caps, rounding, invalid profiles, native updates and restoration")
