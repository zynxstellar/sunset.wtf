local game={PlaceId=286090429}
local BOARD_GAME_NAME="Arsenal"
local AimTab={Right={}}
local LocalPlayer,Players,Vector3={},{},{}
local ENV={RiftArsenalDirectAimRay={Active=false}}
local installed, ticks,closed=0,{},0
local installOK=true
local RivalsAim={Enabled=false,Aimbot={Enabled=false},KillAll={Enabled=false},Wallbang={Enabled=false,HitboxSize=8,Distance=20}}
RivalsAim.StartArsenalShotAdapter=function() installed+=1;return installOK end
RivalsAim.MakeArsenalHitboxes=function() return {
    Tick=function(on,size,range) table.insert(ticks,{on,size,range}) end,
    Close=function() closed+=1 end} end
local Elements,controls={},{}
function Elements.Toggle(_,name,default,callback)
    local value=default
    local control={Set=function(on) if value==on then return end;value=on;callback(on) end}
    controls[name]=control;return control
end
function Elements.Slider(_,name,low,high,default,suffix,callback)
    controls[name]={Set=callback}
end
local function gameSection() return {} end
local function track() end
local function warn() end
local heartbeat
local RunService={Heartbeat={Connect=function(_,fn) heartbeat=fn;return {} end}}
-- INSERT_WALLBANG_TOGGLE
controls.Wallbang.Set(true)
assert(installed==1 and RivalsAim.Wallbang.Enabled and ENV.RiftArsenalDirectAimRay.Active)
assert(#ticks==1 and ticks[1][1] and ticks[1][2]==8,"enabling did not immediately expand hitboxes")
controls["Hitbox Size"].Set(17)
assert(ticks[#ticks][2]==17,"size slider did not apply immediately")
controls.Wallbang.Set(false)
assert(not RivalsAim.Wallbang.Enabled and not ENV.RiftArsenalDirectAimRay.Active and closed==1)
installOK=false;controls.Wallbang.Set(true)
assert(not RivalsAim.Wallbang.Enabled and closed==2,"failed adapter left Wallbang on")
print("PASS Arsenal Wallbang activation: starts native adapter independently, immediate/slider geometry update, disable and failed-install rollback")
