-- Exercise saved-setting migration and execute the actual queued teleport loader.
local ENV={}
local Settings={SelectedGame="Rivals",MenuKey={Name="RightShift"}}
local Enum={KeyCode={RightShift="RightShift",Q={Name="Q"},R={Name="R"}}}
local enabled=true
local control={Key="Sunset/All/Arena Travel/Auto Reinject",Kind="toggle",
    Get=function() return enabled end,Set=function(on) enabled=on end}
local ConfigControls={control}
local bedWarsHiddenSections={}
local Persistence={HUDFrames={}}
local RivalsAim={}
local task={spawn=function() end,wait=function() end}
local typeof=type
local detectedGame="Rivals"
local SUNSET_BUILD="test-reinject-k260"
local SUNSET_LOCAL_SOURCE="SunsetConfigs/SunsetCurrent.lua"
local AutoReinject={enabled=true,Status={}}
local SUNSET_REINJECT_TICKET="SunsetConfigs/SunsetReinjectTicket.txt"
local files,encodedData={},{}
local HttpService={JSONEncode=function(_,data)
    local id=tostring(#encodedData+1)
    table.insert(encodedData,data)
    return id
end,JSONDecode=function(_,id) return encodedData[tonumber(id)] end}
local writefile=function(path,data) files[path]=data end
local readfile=function(path) assert(files[path],"missing mock file") return files[path] end
local nextTicket=0
function HttpService:GenerateGUID()
    nextTicket+=1
    return "ticket-"..nextTicket
end
-- INSERT_CANCEL_PRODUCTION

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

local rivalsFly,bedwarsAura,menuBlur=true,true,true
local rivalsBind,bedwarsBind=Enum.KeyCode.Q,Enum.KeyCode.R
local hidden={Visible=false}
local rivalsControl={Key="Movement/Rivals/Fly/Fly",Kind="toggle",Box=hidden,Row=hidden,
    Get=function() return rivalsFly end,Set=function(on) rivalsFly=on end,
    GetBind=function() return rivalsBind end,SetBind=function(key) rivalsBind=key end}
local bedwarsControl={Key="Combat/BedWars/Kill Aura/Kill Aura",Kind="toggle",Box=hidden,Row=hidden,
    Get=function() return bedwarsAura end,Set=function(on) bedwarsAura=on end,
    GetBind=function() return bedwarsBind end,SetBind=function(key) bedwarsBind=key end}
local blurControl={Key="Sunset/All/Menu Blur/Enabled",Kind="toggle",Box=hidden,Row=hidden,
    Get=function() return menuBlur end,Set=function(on) menuBlur=on end}
ConfigControls={control,rivalsControl,bedwarsControl,blurControl}
Settings.SelectedGame="Rivals"
assert(Persistence.Save())
local savedRivals=ENV.SunsetSettingsSnapshot
assert(#savedRivals.Controls==3,"hidden module settings were skipped or foreign game was included")
Settings.SelectedGame="BedWars"
bedwarsAura,menuBlur=false,false
assert(Persistence.Save())
assert(#ENV.SunsetSettingsSnapshot.Controls==3)
rivalsFly,bedwarsAura,menuBlur=false,true,false
rivalsBind,bedwarsBind=nil,nil
ENV.SunsetSettingsSnapshot=nil
assert(Persistence.Restore("Rivals") and rivalsFly and menuBlur and bedwarsAura,
    "Rivals selection did not restore independently from its file")
assert(rivalsBind==Enum.KeyCode.Q and bedwarsBind==nil,"Rivals keybind did not restore independently")
ENV.SunsetSettingsSnapshot=nil
assert(Persistence.Restore("BedWars") and not bedwarsAura and not menuBlur and rivalsFly,
    "BedWars selection did not restore independently from its file")
assert(bedwarsBind==Enum.KeyCode.R and rivalsBind==Enum.KeyCode.Q,"BedWars keybind did not restore independently")
assert(files["SunsetConfigs/SunsetAuto_Rivals.json"]~=files["SunsetConfigs/SunsetAuto_BedWars.json"])
print("PASS per-game configs: hidden module settings saved, enabled selections restored, separate files and blur settings")

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
    local sandbox=setmetatable({getgenv=function() return fresh end,typeof=type,task=task,readfile=readfile,
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
AutoReinject.Cancel()
assert(ENV.SunsetAutoReinject==false and not AutoReinject.enabled and not AutoReinject.queued)
assert(runQueue(17625359962,6035872082).Reloads==nil,
    "Unload did not cancel the already-queued loader in a fresh destination environment")
AutoReinject.enabled=true
AutoReinject.Queue()
assert(#queued==2,"explicit re-enable did not queue a fresh ticket")
assert(runQueue(17625359962,6035872082).Reloads==nil,"old loader revived after re-enable")
compiled=assert(loadstring(queued[2]))
assert(runQueue(17625359962,6035872082).Reloads==1,"fresh loader failed after explicit re-enable")
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
print("PASS auto reinject: migration, queued loader, fresh-environment unload cancellation, stale tickets, re-enable, retry")
