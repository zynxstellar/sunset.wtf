local Settings = {}
-- INSERT_HUSS_SPEED
local value, writes = nil, 0
local player = {
    GetAttribute=function(_, name) assert(name=="TrollSpeed");return value end,
    SetAttribute=function(_, name, nextValue) assert(name=="TrollSpeed");value=nextValue;writes+=1 end,
}
local speed=Settings.MakeHussSpeedModifier(player)
speed.Tick(false,2)
assert(value==nil and writes==0)
speed.Tick(true,2)
assert(value==2)
speed.Tick(true,2)
assert(writes==1,"unchanged multiplier was rewritten")
speed.Tick(true,9)
assert(value==3,"native profile maximum was exceeded")
speed.Tick(true,0)
assert(value==0.5)
speed.Close()
assert(value==nil,"missing native attribute was not restored")
value=1.25
speed.Tick(true,2)
value=1.4
speed.Tick(true,2.5)
speed.Close()
assert(value==1.4,"latest native update was not restored")
speed.Tick(true,2)
value=1.7
speed.Close()
assert(value==1.7,"disable overwrote a newer native update")
speed.Tick(true,0/0)
assert(value==1,"NaN was applied")
speed.Close()
assert(value==1.7)
print("PASS Huss speed modifier: native attribute, bounds, no redundant writes, external updates, disable and unload")
