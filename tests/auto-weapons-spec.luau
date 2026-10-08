local function instance(name,parent)
    local obj={Name=name,Kind="Instance",Parent=parent,Children={}}
    if parent then parent.Children[name]=obj end
    function obj:FindFirstChild(key) return self.Children[key] end
    function obj:FindFirstChildOfClass(key) return self.Children[key] end
    function obj:IsDescendantOf(other) return self.Parent==other end
    return obj
end
local function typeof(v) return type(v)=="table" and v.Kind or type(v) end
local vecmeta={__mul=function(a,b) return a end,__sub=function(a,b) return a end,
    __index=function(_,key) if key=="Magnitude" then return 0 end end}
local vector=setmetatable({},vecmeta)
local worldOrigin=setmetatable({},vecmeta)
local viewmodelOrigin=setmetatable({},vecmeta)
local storage=instance("Storage")
local client=instance("Client",storage)
local weaponModule=instance("Weapon",instance("Tools",client))
local viewmodelModule=instance("WeaponViewmodel",instance("controllers",weaponModule))
local wielderModule=instance("Wielder",instance("Character",client))
local inventoryModule=instance("InventoryController",client.Children.Character)
local game={GetService=function() return storage end}
local playerCharacter=instance("Me")
playerCharacter.Children.Humanoid={Health=100}
local LocalPlayer={Character=playerCharacter,Team={Name="NATO"}}
local enemyModel=instance("Enemy")
local enemy={Team={Name="PACT"},Character=enemyModel}
local allyModel=instance("Ally")
local ally={Team={Name="NATO"},Character=allyModel}
local Players={GetPlayers=function() return {LocalPlayer,enemy,ally} end}
local tool=instance("Rifle",playerCharacter)
local empty,reserve,loaded=false,true,true
local mode="Auto"
local muzzle={magazine={isEmpty=function() return empty end,hasReserve=function() return reserve end},
    chamber={isLoaded=function() return loaded end},getFireModeName=function() return mode end,
    getBulletIndex=function() return 1 end,attachment={WorldPosition=worldOrigin},
    viewmodelAttachment={WorldPosition=viewmodelOrigin}}
local current={tool=tool,currentMuzzle=muzzle,currentMuzzleIndex=1,config={{Firerate=600}}}
local starts,stops,reloads=0,0,0
local failing,yielding=false,false
local weapon={}
function weapon.equip(object,...) return "equipped",nil,3 end
function weapon.unequip(object) stops+=1 end
function weapon.startFiring(object)
    starts+=1
    if failing then error("native fire failed") end
    if yielding then coroutine.yield("native waiting") end
    return "fire",nil,42
end
function weapon.stopFiring(object) stops+=1 end
function weapon.requestReload(object) reloads+=1 end
setmetatable(current,weapon)
local canAct=true
local wielder={canAct=function() return canAct end}
local shown=true
local viewmodel={isShown=function() return shown end}
local function nativeHold() return true end
local function holsterCurrent() end
local function drawTool() end
local inventory={equip=function() end}
local upvalues={
    [inventory.equip]={[7]=holsterCurrent,[9]=drawTool},
    [holsterCurrent]={[5]=nativeHold},
    [drawTool]={[7]=nativeHold},
}
local debug={getupvalues=function(fn) return upvalues[fn] or {} end}
local hookedHold
local function hookfunction(fn,replacement)
    assert(fn==nativeHold)
    hookedHold=replacement
    return fn
end
local loadedModules=false
local function rivalsModuleLoaded() return loadedModules end
local identity=8
local function getthreadidentity() return identity end
local function setthreadidentity(value) identity=value end
local requireCount=0
local function require(module)
    assert(identity==2)
    requireCount+=1
    if module==weaponModule then return weapon end
    if module==viewmodelModule then return viewmodel end
    if module==inventoryModule then return inventory end
    return wielder
end
local ENV={getgc=function() return {current} end}
local Settings={SelectedGame="Cold War",ColdWarAim={Enabled=false,MaxDistance=1000,HitChance=100}}
local tasks={}
local task={spawn=function(fn) table.insert(tasks,fn) end}
local function finishTasks() local q=tasks tasks={} for _,f in ipairs(q) do f() end end
local menu,typing,manual=false,false,false
local function anyMenuVisible() return menu end
local UIS={GetFocusedTextBox=function() return typing end,IsMouseButtonPressed=function() return manual end}
local Enum={RaycastFilterType={Exclude=1},UserInputType={MouseButton1=1}}
local RaycastParams={new=function() return {} end}
local hit=instance("Head",enemyModel)
local workspace={CurrentCamera={CFrame={Position=vector,LookVector=vector},Focus={Position=vector}},
    FindFirstChild=function() return nil end,Raycast=function() return hit and {Instance=hit} end}
local now=0
local os={clock=function() return now end}
local warnings={}
local function warn(message) table.insert(warnings,message) end
local RunService={RenderStepped={Connect=function(_,fn) return {Disconnect=function() end} end}}
local connections={}
local function track(c) table.insert(connections,c) end
local controls={}
local AimTab={Left={}}
local VisualsTab={Left={}}
local function gameSection(_,_,name) return name end
local Elements={Toggle=function(s,n,d,fn) controls[n]=fn end,
    Slider=function(s,n,min,max,default,suffix,fn) controls[n]=fn end}
local function model(player) return not player.Dead and player.Character end
-- INSERT_AUTO_WEAPONS
Settings.SetupColdWarAutoWeapons(model)
local auto=Settings.ColdWarAutoWeapons
controls["Ammo Saver"](false)
local function step() now+=0.1 auto.Update() assert(identity==8,"native action leaked identity") end
step() assert(requireCount==0,"disabled modules were initialized")
controls["Auto Shoot"](true) step() assert(requireCount==0)
loadedModules=true now+=2 step()
assert(starts==1,"existing equipped weapon was not recovered")
for _=1,5 do step() end
assert(starts==1,"automatic trigger was spammed")
hit=nil step() assert(stops==1,"target loss did not release owned trigger")
hit=instance("Head",allyModel) step() assert(starts==1,"teammate triggered firing")
hit=instance("Wall") step() assert(starts==1,"wall triggered firing")
hit=instance("Head",enemyModel) enemy.Dead=true step() assert(starts==1)
enemy.Dead=false menu=true step() assert(starts==1)
menu=false typing=true step() assert(starts==1)
typing=false manual=true step() assert(starts==1,"manual trigger was taken over")
manual=false step() assert(starts==2)
menu=true step() assert(stops==2,"menu did not release trigger") menu=false
mode="Semi" step() assert(starts==3)
step() assert(stops==3,"semi trigger was not released")
step() assert(starts==4,"semi trigger was not pulled again")
controls["Auto Reload"](true)
empty=true loaded=false step() finishTasks() assert(reloads==1)
for _=1,5 do step() finishTasks() end
assert(reloads==1,"empty magazine caused reload spam")
now+=2 reserve=false step() finishTasks() assert(reloads==1,"no-reserve reload requested")
reserve=true loaded=true step() finishTasks() assert(reloads==1,"chambered round discarded")
loaded=false step() assert(#tasks==1)
controls["Auto Reload"](false) finishTasks() assert(reloads==1,"disabled pending reload ran")
empty=false loaded=true mode="Auto"
local beforeAim=starts
Settings.ColdWarAim.Enabled=true Settings.ColdWarAim.Available=true
local aimTarget=false
local arcClear=false
local resolvedOrigin
Settings.ColdWarAim.Resolve=function(t,mi,bi,o,d,strict)
    assert(strict==true,"Auto Shoot did not require a clear ballistic path")
    assert(t==tool and mi==1 and bi==1)
    resolvedOrigin=o
    if aimTarget and (hit~=nil and hit:IsDescendantOf(enemyModel) or arcClear) then
        return vector,nil,enemyModel,{Position=vector}
    end
end
step() assert(starts==beforeAim,"missing Silent Aim target triggered a shot")
aimTarget=true hit=instance("Ground") step()
assert(starts==beforeAim,"Auto Shoot fired through the ground")
shown=false
arcClear=true now+=1 step()
assert(starts==beforeAim+1,"valid ballistic arc was rejected by an extra straight ray")
assert(resolvedOrigin==worldOrigin,"sprint did not use the native world muzzle")
shown=true
arcClear=false
hit=nil step()
hit=instance("Head",enemyModel)
aimTarget=true step() assert(starts==beforeAim+2,"Silent Aim target did not trigger")
controls["Auto Shoot"](false)
local nativeEquip=weapon.equip
assert(auto.Current==nil,"disabled observer retained weapon")
controls["Auto Shoot"](true) now+=2 step()
yielding=true
local thread=coroutine.create(function()
    local result=table.pack(weapon.startFiring(current))
    assert(result.n==3 and result[1]=="fire" and result[2]==nil and result[3]==42)
end)
local ok,value=coroutine.resume(thread) assert(ok and value=="native waiting")
assert(coroutine.resume(thread)) yielding=false
local foreign=function() end weapon.equip=foreign
auto.Restore()
assert(weapon.equip==foreign,"foreign hook overwritten on unload")
assert(not auto.ShootEnabled and not auto.ReloadEnabled)
local count=starts step() assert(starts==count,"unloaded automation ran")
weapon.equip=nativeEquip
ENV.getgc=nil
Settings.SetupColdWarAutoWeapons(model) auto=Settings.ColdWarAutoWeapons
controls["Ammo Saver"](false)
controls["Auto Shoot"](true) now+=2 step()
assert(auto.Current==nil,"instance was invented without enumeration")
local result=table.pack(weapon.equip(current))
assert(result.n==3 and result[3]==3 and auto.Current==current,"native equip capture/returns changed")
step()
local previousEmpty=muzzle.magazine.isEmpty
muzzle.magazine.isEmpty=function() error("ammo unavailable") end
local beforeWarning=#warnings
step() step()
assert(#warnings==beforeWarning+1,"ammo failure escaped or spammed warnings")
muzzle.magazine.isEmpty=previousEmpty
weapon.unequip(current) assert(auto.Current==nil,"unequip retained active gun")
weapon.equip(current)
local reloadThread=coroutine.create(function() end)
muzzle.config={ReloadTime=2}
muzzle.reloadController={_thread=reloadThread}
controls["Reload Timer"](true) step()
assert(auto.ReloadRemaining==2,"reload timer did not follow the native reload thread")
now+=1 step() assert(math.abs(auto.ReloadRemaining-0.9)<0.01,"reload timer did not count down")
assert(coroutine.resume(reloadThread))
step() assert(auto.TimerEnabled and auto.Current==current,"completed reload disrupted weapon capture")
controls["Reload Timer"](false)
controls["Ammo Saver"](true)
local priorStops=stops
for _=1,4 do step() end
assert(stops>priorStops,"Ammo Saver did not release an automatic burst")
local priorStarts=starts
step() assert(starts==priorStarts,"Ammo Saver ignored the burst pause")
auto.Restore()
Settings.SetupColdWarAutoWeapons(model) auto=Settings.ColdWarAutoWeapons
controls["Instant Equip"](true)
now+=2 step()
assert(hookedHold and hookedHold()==false,"equip animation wait was not bypassed")
controls["Instant Equip"](false)
assert(hookedHold()==true,"native equip timing was not restored when disabled")
controls["Instant Equip"](true)
auto.Restore()
assert(hookedHold()==true,"native equip timing was not restored on unload")
print("PASS auto weapons: deferred loaded modules, existing/equipped gun capture, native returns/yields, auto/semi trigger, target/team/wall/menu/input filters, chamber/reserve checks, reload throttle/cancellation, identity restoration, foreign-hook-safe unload")
