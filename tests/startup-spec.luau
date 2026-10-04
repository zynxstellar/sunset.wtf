-- Exercise the startup gate without requiring any game modules or creating UI.
local ENV={}
local now, waits, mode=0,0,"ready"
local os={clock=function() return now end}
local fighter={}
local controllers={FindFirstChild=function(_,name) if name=="FighterController" then return fighter end end}
local scripts={FindFirstChild=function(_,name) if name=="Controllers" then return controllers end end}
local player={FindFirstChild=function(_,name) if name=="PlayerScripts" then return scripts end end}
local game={GetService=function(_,name) assert(name=="Players") return {LocalPlayer=player} end,
    IsLoaded=function() return waits>=1 end}
local workspace={CurrentCamera={}}
local task={wait=function()
    waits+=1
    now+=0.25
    if mode=="cancel" then ENV.SunsetStartupToken=nil end
end}
local getloadedmodules=function() return mode=="ready" and waits>=3 and {fighter} or {} end
local warnings={}
local function warn(message) table.insert(warnings,message) end
-- INSERT_STARTUP_PRODUCTION
assert(waitForRivalsStartup() and waits==3,"startup did not wait for native fighter initialization")
assert(ENV.SunsetStartupToken==nil and #warnings==0)
mode,now,waits="never-ready",0,0
assert(not waitForRivalsStartup() and now==120,"failed startup did not stop after timeout")
assert(#warnings==1 and ENV.SunsetStartupToken==nil)
mode,now,waits="cancel",0,0
assert(not waitForRivalsStartup() and waits==1,"cancel did not stop pending startup")
assert(#warnings==1,"cancel emitted a loading error")
print("PASS startup: native initialization required, bounded wait, pending load cancellation")
