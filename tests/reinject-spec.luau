-- Exercise saved-setting migration and execute the actual queued teleport loader.
local ENV={}
local Settings={SelectedGame="Rivals",MenuKey={Name="RightShift"}}
local Enum={KeyCode={RightShift="RightShift"}}
local enabled=true
local control={Key="Sunset/All/Arena Travel/Auto Reinject",Kind="toggle",
    Get=function() return enabled end,Set=function(on) enabled=on end}
local ConfigControls={control}
local Persistence={SavedHUDPositions=function() return {} end,RestoreHUDPositions=function() end}
local RivalsAim={}
local task={spawn=function() end,wait=function() end}
local typeof=type
local detectedGame="Rivals"
local SUNSET_BUILD="test-reinject-k260"
local SUNSET_LOCAL_SOURCE="SunsetConfigs/SunsetCurrent.lua"
local AutoReinject={enabled=true,Status={}}

-- INSERT_PERSISTENCE_PRODUCTION

ENV.SunsetSettingsSnapshot={Version=5,Game="Rivals",Controls={
    {Key=control.Key,Kind="toggle",Value=false}}}
assert(Persistence.Restore("Rivals") and enabled,"legacy forced-off setting was not repaired")
assert(Persistence.Save() and ENV.SunsetSettingsSnapshot.AutoReinjectVersion==1)
control.Set(false)
Persistence.Save()
control.Set(true)
assert(Persistence.Restore("Rivals") and not enabled,"later user opt-out was overwritten")
ENV.SunsetSettingsSnapshot={Version=5,Game="BedWars",Controls={
    {Key=control.Key,Kind="toggle",Value=false}}}
control.Set(true)
assert(Persistence.Restore("BedWars") and not enabled,"BedWars setting changed during Rivals migration")

local function installQueue(queue_on_teleport)
-- INSERT_QUEUE_PRODUCTION
end
local queued={}
ENV.SunsetEmbeddedSource="-- "..SUNSET_BUILD.."\ngetgenv().Reloads=(getgenv().Reloads or 0)+1"
installQueue(function(code) table.insert(queued,code) end)
AutoReinject.enabled=false
AutoReinject.Queue()
assert(#queued==0,"disabled feature queued a loader")
AutoReinject.enabled=true
AutoReinject.Queue()
AutoReinject.Queue()
assert(#queued==1,"duplicate loader was queued")
local compiled,err=loadstring(queued[1])
assert(compiled,err)
local function runQueue(place,universe,disabled)
    local fresh={}
    if disabled then fresh.SunsetAutoReinject=false end
    local sandbox=setmetatable({getgenv=function() return fresh end,typeof=type,task=task,
        game={PlaceId=place,GameId=universe,IsLoaded=function() return true end,
            HttpGet=function() error("embedded loader unexpectedly used HTTP") end}}, {__index=getfenv()})
    sandbox.loadstring=function(source)
        local chunk,problem=loadstring(source)
        if chunk then setfenv(chunk,sandbox) end
        return chunk,problem
    end
    setfenv(compiled,sandbox)
    compiled()
    return fresh
end
assert(runQueue(17625359962,6035872082).Reloads==1,"Rivals was not reinjected")
assert(runQueue(999,6035872082).Reloads==1,"Rivals subplace was not reinjected")
assert(runQueue(6872265039,2619619496).Reloads==1,"BedWars was not reinjected")
assert(runQueue(1,2).Reloads==nil,"unsupported game loaded Rift")
assert(runQueue(17625359962,6035872082,true).Reloads==nil,"disabled destination loaded Rift")
AutoReinject.queued=false
installQueue(nil)
AutoReinject.Queue()
assert(not AutoReinject.queued and AutoReinject.Status.Text=="Executor has no teleport queue")
local attempts=0
installQueue(function()
    attempts+=1
    if attempts==1 then error("temporary queue failure") end
end)
AutoReinject.Queue()
assert(not AutoReinject.queued)
AutoReinject.Queue()
assert(AutoReinject.queued and attempts==2,"failed queue could not be retried")
print("PASS auto reinject: legacy Rivals setting repaired, opt-out retained, queued loader runs, supported games, retry")
