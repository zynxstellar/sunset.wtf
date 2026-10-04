-- Generated tests insert the real production functions at the marker below.
local now, events = 10, {}
local os = { clock = function() return now end }
local task = {}
local function resume(thread)
    local ok, delay = coroutine.resume(thread)
    assert(ok, delay)
    if coroutine.status(thread) ~= "dead" then
        table.insert(events, { at = now + (delay or 0), thread = thread })
    end
end
function task.spawn(fn) resume(coroutine.create(fn)) end
function task.wait(seconds) return coroutine.yield(seconds or 0) end
function task.delay(seconds, fn)
    table.insert(events, { at = now + seconds, thread = coroutine.create(fn) })
end
local function advance(seconds)
    local target = now + seconds
    while true do
        table.sort(events, function(a, b) return a.at < b.at end)
        if #events == 0 or events[1].at > target then break end
        local event = table.remove(events, 1)
        now = event.at
        resume(event.thread)
    end
    now = target
end
local Vector3, Vector2 = {}, {}
local vector = {}
function Vector3.new(x, y, z) return setmetatable({ X=x or 0, Y=y or 0, Z=z or 0 }, vector) end
function Vector2.new(x, y) return Vector3.new(x, y, 0) end
function vector.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function vector.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function vector.__mul(a,b)
    if type(a) == "number" then a,b = b,a end
    return Vector3.new(a.X*b,a.Y*b,a.Z*b)
end
function vector.__div(a,b) return a * (1/b) end
function vector.__unm(a) return a * -1 end
function vector.__eq(a,b) return a.X==b.X and a.Y==b.Y and a.Z==b.Z end
function vector.__index(a,key)
    if key == "Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if key == "Unit" then return a / math.max(a.Magnitude, 1e-9) end
end
Vector3.zero = Vector3.new()
local CFrame = { new = function(p) return { Position = p } end }
local UDim2 = { new = function(xs,xo,ys,yo) return { X={Scale=xs,Offset=xo}, Y={Scale=ys,Offset=yo} } end }
function UDim2.fromOffset(x,y) return UDim2.new(0,x,0,y) end
function UDim2.fromScale(x,y) return UDim2.new(x,0,y,0) end
local UDim = { new = function() return {} end }
local Enum = {
    Material={Air="air",Water="water",Grass="grass"}, HumanoidStateType={Swimming="swim"},
    RaycastFilterType={Exclude=1}, UserInputType={MouseButton1=1}, KeyCode={Space=1},
    SortOrder={LayoutOrder=1}, VerticalAlignment={Bottom=1}, Font={GothamBold=1},
    EasingStyle={Quart=1,Quad=2}, EasingDirection={Out=1,In=2},
}
local OverlapParams = { new=function() return {} end }
local RaycastParams = { new=function() return {} end }
local Region3 = { new=function(a,b) return {Min=a,Max=b} end }
local Region3int16 = Region3
local Vector3int16 = Vector3
local Settings = { SelectedGame="BedWars" }
local BedWars = {Running=true,NoFallOn=true,NoFallMinDrop=18,ScaffoldOn=true,ScaffoldTowerOn=true,
    ScaffoldVoidRescue=true,ScaffoldTowerSpeed=38,AuraOn=true,AuraCPS=10,MusicCoverFiles={},
    VoidWaterWidth=96,VoidWaterDepth=96,WaterFightRange=14}
local Persistence = { HUDFrames={} }
local ENV = {}
local held, root, humanoid, character
local inventory = {}
local wool = {Name="wool_blue",Parent=inventory}
local sword = {Name="wood_sword",Parent=inventory}
local LocalPlayer = { GetNetworkPing=function() return 0.15 end }
local players = {LocalPlayer}
local Players = {GetPlayers=function() return players end}
function Players:GetPlayerFromCharacter(model)
    for _, p in ipairs(players) do if p.Character == model then return p end end
end
local UIS = {IsMouseButtonPressed=function() return false end,IsKeyDown=function() return false end,
    GetFocusedTextBox=function() return nil end}
local game = {GetService=function() return {FindFirstChild=function() return nil end} end}
function BedWars.Inventory() return inventory end
function BedWars.FindWool() return wool end
function BedWars.HeldItem() return held end
function BedWars.Equip(item) held=item return true end
function BedWars.HoldingAbility() return false end
function BedWars.MeleeItem(item) return item == sword end
function BedWars.BestSword() return sword end
function BedWars.GearScore() return 0 end
function BedWars.Enemy(player) return player ~= LocalPlayer and not player.ally end
function BedWars.HostileNpc() return false end
function BedWars.Visible() return true end
local function newCharacter(position)
    local h={Health=100,HipHeight=2,WalkSpeed=23,FloorMaterial=Enum.Material.Grass,
        MoveDirection=Vector3.new(1,0,0),state="running"}
    function h:GetState() return self.state end
    local r={Position=position,Size=Vector3.new(2,2,1),AssemblyLinearVelocity=Vector3.new(23,0,0),Parent=true}
    r.CFrame=CFrame.new(position)
    local c={Name="test",PrimaryPart=r}
    function c:FindFirstChild(name) if name=="HumanoidRootPart" then return r end end
    function c:FindFirstChildOfClass(name) if name=="Humanoid" then return h end end
    return c,r,h
end
local blocks, calls, rpcDelay, reject = {}, {}, 0.3, false
local function key(p) return tostring(p.X)..":"..tostring(p.Y)..":"..tostring(p.Z) end
local function supported(p)
    for _,offset in ipairs({Vector3.new(1,0,0),Vector3.new(-1,0,0),Vector3.new(0,0,1),Vector3.new(0,0,-1),Vector3.new(0,-1,0)}) do
        if blocks[key(p+offset)] then return true end
    end
    return false
end
local placeRemote = {Parent=true,IsA=function(_,kind) return kind=="RemoteFunction" end}
function placeRemote:InvokeServer(payload)
    table.insert(calls, {position=payload.position, at=now})
    task.wait(rpcDelay/2)
    local accepted = not reject and supported(payload.position)
    if accepted then blocks[key(payload.position)]=true end
    task.wait(rpcDelay/2)
    return accepted
end
local attackCalls = {}
local attackRemote = {Parent=true,IsA=function(_,kind) return kind=="RemoteEvent" end}
function attackRemote:FireServer(payload) table.insert(attackCalls,{payload=payload,at=now}) end
function BedWars.Remote(name) return name=="SwordHit" and attackRemote or placeRemote end
local waterGround, swimmingGrounded, copies, restores = nil, false, 0, 0
local terrain = {}
function terrain:CopyRegion()
    copies+=1
    return {Destroy=function() end}
end
function terrain:PasteRegion() restores+=1 end
function terrain:ReadVoxels() return {{{Enum.Material.Air}}},{{{0}}} end
function terrain:WriteVoxels(region,resolution,materials)
    assert(materials[1][1][1]==Enum.Material.Water, "water not written")
    self.LastRegion=region
end
local workspace = {Terrain=terrain,Gravity=196.2}
function workspace:GetPartBoundsInBox(frame)
    local p=frame.Position/3
    return blocks[key(p)] and {{CanCollide=true}} or {}
end
function workspace:GetPartBoundsInRadius() return {} end
function workspace:Raycast(origin,direction)
    if waterGround then
        if direction.Y < 0 and origin.Y >= waterGround and origin.Y+direction.Y <= waterGround then
            local t=(waterGround-origin.Y)/direction.Y
            return {Position=origin+direction*t,Normal=Vector3.new(0,1,0),Instance=terrain}
        end
        return nil
    end
    if math.abs(direction.Y)<0.001 then
        local endGrid=(origin+direction)/3
        if blocks[key(endGrid)] then return {Position=origin+direction,Normal=Vector3.new(0,1,0)} end
    end
end
local function bedWarsSafeGround() return nil,swimmingGrounded end
local PlayerGui = {}
local T = {inner={},accent={},gold={},text={}}
local function new(class, properties, parent)
    properties.Parent=parent
    properties.ClassName=class
    function properties:Destroy() self.Parent=nil end
    return properties
end
local function label() return {} end
local function border() end
local TweenInfo = {new=function() return {} end}
local TweenService = {Create=function(_,object,info,properties)
    return {Play=function() for k,v in pairs(properties) do object[k]=v end end}
end}

-- INSERT_PRODUCTION_FUNCTIONS

local function setupScaffold()
    advance(4)
    blocks={ [key(Vector3.zero)]=true }
    calls={}
    reject=false
    rpcDelay=0.3
    waterGround=nil
    BedWars.ScaffoldOn=true
    BedWars.ItemBusy=false
    BedWars.ResetScaffold()
    character,root,humanoid=newCharacter(Vector3.new(0,4.5,0))
    LocalPlayer.Character=character
    held=wool
end
setupScaffold()
for _=1,40 do bedWarsScaffoldStep() advance(0.01) end
assert(#calls>=3, "scaffold still serializes every block behind the reply")
assert(calls[2].at-calls[1].at < rpcDelay, "placement did not pipeline")
local seen={}
for _,call in ipairs(calls) do
    assert(not seen[key(call.position)], "duplicate placement while in flight")
    seen[key(call.position)]=true
end
advance(2)
assert(BedWars.ScaffoldPending==0, "pending slots leaked")
setupScaffold()
humanoid.MoveDirection=Vector3.new(1,0,1).Unit
for _=1,80 do bedWarsScaffoldStep() advance(0.01) end
assert(#calls>=4, "diagonal bridge did not fill connectors")
for _,call in ipairs(calls) do assert(blocks[key(call.position)], "diagonal placement rejected") end
setupScaffold()
reject=true
bedWarsScaffoldStep()
advance(0.35)
bedWarsScaffoldStep()
assert(#calls==2 and calls[1].position==calls[2].position, "rejected cell was not retried")
setupScaffold()
rpcDelay=3
for _=1,100 do bedWarsScaffoldStep() advance(0.01) end
assert(BedWars.ScaffoldPending<=6, "unbounded pending placement requests")
BedWars.ResetScaffold()
advance(4)
assert(BedWars.ScaffoldPending==0 and next(BedWars.ScaffoldConfirmed)==nil, "late reply changed a reset session")
for _,direction in ipairs({Vector3.new(1,0,0),Vector3.new(1,0,1).Unit}) do
    setupScaffold()
    humanoid.MoveDirection=direction
    root.AssemblyLinearVelocity=direction*23
    for step=1,300 do
        bedWarsScaffoldStep()
        advance(0.01)
        root.Position+=root.AssemblyLinearVelocity*0.01
        local under=Vector3.new(math.round(root.Position.X/3),0,math.round(root.Position.Z/3))
        humanoid.FloorMaterial=blocks[key(under)] and Enum.Material.Grass or Enum.Material.Air
        if step>50 then assert(blocks[key(under)], "moving player outran scaffold") end
    end
end
print("PASS scaffold: latency pipeline, duplicate suppression, diagonals, rejection retry, timeout/reset")

advance(4)
waterGround=0
character,root,humanoid=newCharacter(Vector3.new(0,30,0))
LocalPlayer.Character=character
humanoid.FloorMaterial=Enum.Material.Air
root.AssemblyLinearVelocity=Vector3.new(40,-70,0)
BedWars.NoFallOn=true
BedWars.NoFallPeakY=60
waterStep()
assert(BedWars.VoidWater.Mode()=="NoFall", "damaging fall did not place water")
assert(terrain.LastRegion.Max.Y>=12 and terrain.LastRegion.Max.Y-terrain.LastRegion.Min.Y==24, "cushion too shallow")
local savedCopies=copies
humanoid.state=Enum.HumanoidStateType.Swimming
for _=1,20 do advance(0.1) waterStep() end
assert(BedWars.VoidWater.Mode()=="NoFall", "water disappeared while swimming")
humanoid.state="running"
humanoid.FloorMaterial=Enum.Material.Grass
root.Position=Vector3.new(0,3,0)
root.AssemblyLinearVelocity=Vector3.zero
swimmingGrounded=true
advance(1)
waterStep()
assert(BedWars.VoidWater.Mode()==nil and restores>0, "water did not restore after landing")
swimmingGrounded=false
humanoid.FloorMaterial=Enum.Material.Air
root.Position=Vector3.new(0,8,0)
root.AssemblyLinearVelocity=Vector3.new(0,-25,0)
BedWars.NoFallPeakY=10
waterStep()
assert(copies==savedCopies, "short safe drop created water")
root.Position=Vector3.new(0,30,0)
root.AssemblyLinearVelocity=Vector3.new(0,-70,0)
BedWars.NoFallPeakY=60
waterStep()
humanoid.Health=0
waterStep()
assert(BedWars.VoidWater.Mode()==nil, "death left water behind")
print("PASS NoFall: damaging/short drops, deep cushion, swimming retention, landing/death cleanup")

waterGround=nil
character,root,humanoid=newCharacter(Vector3.new(0,3,0))
LocalPlayer.Character=character
held=sword
BedWars.ItemBusy=false
BedWars.ScaffoldOn=false
BedWars.ReachOn=true
BedWars.ReachDistance=18
local enemy,enemyRoot,enemyHumanoid=newCharacter(Vector3.new(18,3,0))
enemy.Name="enemy"
players={LocalPlayer,{Character=enemy}}
local payload=BedWars.AuraPayload(sword,root,enemyRoot,enemy)
assert(payload and math.abs((payload.validate.selfPosition.value-enemyRoot.Position).Magnitude-14.399)<0.001, "reach validation not aligned with reference")
enemyRoot.Position=Vector3.new(18.1,3,0)
assert(BedWars.AuraPayload(sword,root,enemyRoot,enemy)==nil, "target beyond configured reach")
enemyRoot.Position=Vector3.new(16,3,0)
bedWarsAuraStep()
assert(#attackCalls==1, "enemy in Reach range was ignored")
for _=1,100 do advance(0.01) bedWarsAuraStep() end
assert(#attackCalls>=9 and #attackCalls<=11, "aura cadence is not approximately 10 APS")
BedWars.ReachOn=false
assert(BedWars.AuraPayload(sword,root,enemyRoot,enemy)==nil, "Reach-off retained extended targeting")
enemyRoot.Position=Vector3.new(10,3,0)
payload=BedWars.AuraPayload(sword,root,enemyRoot,enemy)
assert(payload.validate.selfPosition.value==root.Position, "Reach-off changed source position")
held=wool
BedWars.LastAuraAttack=nil
bedWarsAuraStep()
assert(held==sword and attackCalls[#attackCalls].payload.weapon==sword, "auto-equip skipped the immediate attack")
local count=#attackCalls
enemyHumanoid.Health=0
advance(1)
bedWarsAuraStep()
assert(#attackCalls==count, "aura attacked a dead target")
enemyHumanoid.Health=100
players[2].ally=true
bedWarsAuraStep()
assert(#attackCalls==count, "aura attacked an ally")
print("PASS aura: configured Reach, bounded validation, immediate equip attack, cadence, dead/ally filters")

local listFrame={Parent=true,Position=UDim2.new(1,-14,0,38)}
local hudFrame={Parent=true,Position=UDim2.new(0,0,0,0)}
Persistence.HUDFrames={ModuleList=listFrame,TargetHUD=hudFrame}
Persistence.RestoreHUDPositions({ModuleList={1,-310,0,38},TargetHUD={0,50,0,60}},false)
assert(listFrame.Position.X.Offset==-14 and hudFrame.Position.X.Offset==50, "saved shifted module position was restored")
BedWars.Notify("Feature enabled","Scaffold",true)
assert(BedWars.NotifyStack.AnchorPoint.X==0 and BedWars.NotifyStack.Position.X.Scale==0
    and BedWars.NotifyStack.Position.Y.Scale==1, "notifications are not bottom-left")
assert(Persistence.SavedHUDPositions().ModuleList[2]==-14, "saved list position drifted")
advance(5)
assert(BedWars.NotifyActiveCount==0, "expired toast was not removed")
print("PASS UI: bottom-left toast, expiry, shifted-config repair, other HUD positions preserved")
