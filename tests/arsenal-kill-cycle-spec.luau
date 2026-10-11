local Settings={}
-- INSERT_KILL_CYCLE
local a,b={},{}
local first={Player=a,Part={},Root={}}
local second={Player=b,Part={},Root={}}
local candidates={first,second}
local now,opened,closed,stopped=0,0,0,0
local moved={}
local mode=Settings.MakeArsenalKillCycle({Now=function() return now end,Timeout=function() return 2 end,
    Candidates=function() return candidates end,
    OpenView=function() opened+=1 end,CloseView=function() closed+=1 end,
    StopFire=function() stopped+=1 end,MoveBehind=function(target) table.insert(moved,target.Player) end})
mode.Tick();assert(#moved==0)
mode.Set(true);assert(opened==1)
mode.Tick();assert(mode.Target.Player==a and moved[1]==a)
now=0.2;mode.Tick();assert(mode.Target.Player==a,"switched away from a live target too early")
now=2.01;mode.Tick();assert(mode.Target.Player==b,"stalled target did not time out")
candidates={first};mode.Tick();assert(mode.Target.Player==a,"removed/dead target was retained")
candidates={};mode.Tick();assert(mode.Target==nil and stopped>0,"empty lobby kept firing")
candidates={second};mode.Tick();assert(mode.Target.Player==b,"respawn/new enemy did not resume selection")
mode.Set(false);assert(closed==1 and mode.Target==nil)
local before=#moved;mode.Tick();assert(#moved==before)
mode.Set(true);mode.Tick();mode.Close();assert(closed==2 and not mode.Enabled and mode.Closed)
mode.Set(true);mode.Tick();assert(opened==2,"unloaded mode reactivated")
print("PASS Arsenal Kill All: sequential target retention, timeout, death/removal/empty-lobby release, resume, detached view lifecycle and unload")
