local controls, connections = {}, {}
local function track(c) table.insert(connections,c) end
local function gameSection() return {} end
local Elements={Label=function() end,Toggle=function(_,name,_,callback)
    controls[name]=callback return {Set=function() end} end,
    Slider=function(_,name,_,_,_,_,callback) controls[name]=callback end}
local AimTab={Left={}}
local Settings={SelectedGame="Cold War",Notify=function(_,err) error(err) end}
local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local heartbeat
local RunService={Heartbeat={Connect=function(_,fn) heartbeat=fn return {Disconnect=function() end} end}}
local Players={}
local LocalPlayer={Team=1}
local function part()
    return {Size=Vector3.new(1,2,1),CanCollide=true,Massless=false,Transparency=0,
        IsA=function(_,kind) return kind=="BasePart" end}
end
local function player(team)
    local parts={Head=part(),Torso=part(),["Left Arm"]=part(),["Right Arm"]=part()}
    local hum={Health=100}
    local character={Parent={},FindFirstChildOfClass=function() return hum end,
        FindFirstChild=function(_,name) return parts[name] end}
    return {Team=team,Character=character},parts,hum
end
local ally,allyParts=player(1)
local foe,parts,hum=player(2)
local roster={LocalPlayer,ally,foe}
function Players:GetPlayers() return roster end
-- INSERT_HITBOXES
Settings.SetupColdWarHitboxes()
local options=Settings.ColdWarHitboxes
options.Apply() assert(parts.Head.Size.X==1)
controls.Hitboxes(true)
assert(parts.Head.Size.X==20 and not parts.Head.CanCollide and parts.Head.Massless)
assert(allyParts.Head.Size.X==1 and parts.Torso.Size.X==1)
controls.Torso(true) controls["Left Arm"](true)
assert(parts.Head.Size.X==20 and parts.Torso.Size.X==20 and parts["Left Arm"].Size.X==20)
controls.Size(50) assert(parts.Head.Size.X==50 and parts.Torso.Size.X==50)
controls.Head(false) assert(parts.Head.Size.X==1 and parts.Head.CanCollide and not parts.Head.Massless)
hum.Health=0 heartbeat(0.25) assert(parts.Torso.Size.X==1)
hum.Health=100 heartbeat(0.25) assert(parts.Torso.Size.X==50)
foe.Team=1 options.Apply() assert(parts.Torso.Size.X==1)
controls["Team Check"](false) assert(parts.Torso.Size.X==50 and allyParts.Torso.Size.X==50)
local old=parts.Torso parts.Torso=part() options.Apply()
assert(old.Size.X==1 and parts.Torso.Size.X==50)
roster={LocalPlayer,ally} options.Apply() assert(parts.Torso.Size.X==1)
roster={LocalPlayer,ally,foe} options.Apply()
controls.Hitboxes(false) assert(parts.Torso.Size.X==1 and allyParts.Torso.Size.X==1)
controls.Hitboxes(true) Settings.SelectedGame="Rivals" options.Apply() assert(parts.Torso.Size.X==1)
Settings.SelectedGame="Cold War" options.Apply()
connections[#connections].Disconnect()
assert(options.Destroyed and parts.Torso.Size.X==1 and parts.Torso.Transparency==0)
print("PASS Hitboxes: multiple parts, size limit, enemy filter, death/team/replacement/leave/game/unload restoration")
