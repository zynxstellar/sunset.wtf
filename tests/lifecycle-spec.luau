local ENV = {SunsetRivalsAimHook={Active=true,Resolve=function() end,Select=function() end}}
local calls = {}
local function broken(name)
    return function()
        calls[name]=(calls[name] or 0)+1
        error("simulated failure: "..name)
    end
end
local Settings = {FlyEnabled=true,WatermarkOn=true,MenuBlurEffect={Destroy=broken("blur")}}
local BedWars = {Running=true,Stop=broken("bedwars")}
local Fun = {Running=true,Enabled=true}
local AutoReinject = {ready=true,Cancel=broken("reinject")}
local RivalsAim = {Enabled=true}
local Persistence = {Save=function()
    assert(Settings.FlyEnabled and Settings.WatermarkOn and RivalsAim.Enabled and Fun.Enabled,
        "unload saved disabled module settings instead of the user configuration")
    calls.save=(calls.save or 0)+1
    ENV.SunsetUnload() -- A reentrant unload must be harmless.
    error("save failure")
end}
local GhostPulse={Stop=broken("ghost")}
local clearFunEffect=broken("effects")
local setCloudRemoval=broken("clouds")
local restoreAtmosphere=broken("atmosphere")
local Fly={Stop=broken("fly")}
local ESP={Destroy=broken("esp")}
local Gui={Destroy=broken("gui")}
Settings.RootGui=Gui
local Connections={
    {Disconnect=broken("first connection")},
    {Disconnect=function() calls.lastConnection=(calls.lastConnection or 0)+1 end},
}
ENV.SunsetLoading={Gui={Destroy=broken("loading")}}
-- INSERT_UNLOAD
local unload=ENV.SunsetUnload
assert(pcall(unload), "a cleanup error escaped unload")
assert(not BedWars.Running and not Fun.Running and not Fun.Enabled)
assert(not Settings.FlyEnabled and not Settings.WatermarkOn and not RivalsAim.Enabled)
assert(not AutoReinject.ready and not ENV.SunsetRivalsAimHook.Active)
assert(ENV.SunsetRivalsAimHook.Resolve==nil and ENV.SunsetRivalsAimHook.Select==nil)
assert(#Connections==0 and ENV.SunsetLoading==nil and ENV.SunsetUnload==nil)
for _,name in ipairs({"save","reinject","ghost","effects","bedwars","clouds","atmosphere",
    "fly","esp","first connection","lastConnection","gui","blur","loading"}) do
    assert(calls[name]==1, "cleanup was skipped or repeated: "..name)
end
assert(pcall(unload) and calls.save==1, "unload was not idempotent")

BedWars.Running=true
Connections={{Disconnect=broken("early broken")},
    {Disconnect=function() calls.earlyLast=true end}}
ENV.SunsetLoading={Gui={Destroy=broken("early loading")}}
-- INSERT_EARLY_ABORT
assert(pcall(ENV.SunsetAbortStartup), "early startup cleanup threw")
assert(not BedWars.Running and #Connections==0 and calls.earlyLast)
assert(ENV.SunsetAbortStartup==nil and ENV.SunsetLoading==nil)
print("PASS lifecycle: cleanup survives individual failures, reentrancy, repeat unload and early startup failure")
