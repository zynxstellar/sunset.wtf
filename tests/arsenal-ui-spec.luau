local IS_GENERIC, BOARD_GAME_NAME = true, "Arsenal"
local function isRivalsMode(name) return name == "Arsenal" or name == "Rivals" end
Settings.StartupStage = function() end
Settings.Notify = function() end
RunService.PostSimulation = signal()
workspace.children = {}
LocalPlayer.CharacterAdded = signal()
LocalPlayer.Character = nil
Vector3.zero, Vector3.yAxis = Vector3.new(), Vector3.new(0,1,0)
function vectors.__unm(a) return a * -1 end
local RivalsView = {Apply=function() end}
local RivalsSpeed = {Apply=function() end}
local RivalsFOV = {Apply=function() end}
local CharacterCollision
local function buildSpinbot(section)
    Elements.Toggle(section,"Spinbot",false,function() end)
end
local firing = {}
local firingWanted, stopped = nil, 0
firing.Update=function(wanted) firingWanted=wanted end
local function stopAutoFire() stopped+=1 end
local sight = true
local function aimUnobstructed() return sight end
local function focusedGame() return true end
local function aimStatus() end
function game:GetService() return {MenuIsOpen=false} end
local silentTarget
local function closestTarget() return silentTarget end
-- INSERT_IMPORTED_UI
RivalsAim.ArsenalSilentAvailable = true
RivalsAim.StopAutoFire = function() end
RivalsAim.SetEnabled = function(on) RivalsAim.Enabled = on end
RivalsAim.SetCameraEnabled = function(name,on) RivalsAim[name].Enabled = on end
RivalsAim.UpdateTargetHUD = function() end
RivalsKillChat.SetEnabled = function(on) RivalsKillChat.Enabled = on end
BedWars.SpotifyPanel = new("Frame",{Visible=false},Gui)
BedWars.MusicOverlayVisible = function() return RivalsVisuals.MusicOverlayOn end
T.bg, T.panel, T.inner, T.element, T.border, T.gold = color(0,0,0),color(0,0,0),color(0,0,0),color(0,0,0),color(0,0,0),color(0,0,1)
for _, gameName in ipairs({"Arsenal","Rivals"}) do
    IS_GENERIC, BOARD_GAME_NAME = gameName == "Arsenal", gameName
    Settings.SelectedGame = gameName
    for _, title in ipairs({"ESP Boxes","Player Outlines","Third Person","Zoom Unlocker","Hide Visuals","Preset Profiles","Named Presets"}) do
        Elements.Toggle(gameSection(gameName,VisualsTab.Left,title),title,false,function() end)
    end
    RivalsAim.BuildUI()
    local board = Settings.GameBoards[gameName]
    assert(board and board:FindFirstChild("CategoryLayer"),"new category layer missing")
    assert(board:FindFirstChild("CategoryColumns"),"new horizontal menu missing")
    local cards = {}
    for _, obj in ipairs(board:GetDescendants()) do
        assert(not obj:IsA("UIGradient"),"old gradient UI leaked")
        if obj:IsA("TextButton") then cards[obj.Name] = obj end
        assert(obj.Name ~= "Dev Tools","developer category remains")
    end
    assert(cards.Fly and cards.Noclip and cards["Auto Shoot"] and cards.Aimbot)
    assert(cards.Fly.Size.Y.Offset == 30 and cards.Noclip.Size.Y.Offset == 30, "row height disagrees with category sizing")
    local layer = board:FindFirstChild("CategoryLayer")
    assert(layer:FindFirstChild("Misc").Size.Y.Offset == 32, "empty category is not header only")
    if IS_GENERIC then assert(layer:FindFirstChild("Fun").Size.Y.Offset == 32, "empty Arsenal Fun is not header only") end
    assert(layer:FindFirstChild("Player").Size.Y.Offset == 76, "single module category has excess bottom space")
    local movement = layer:FindFirstChild("Movement")
    assert(movement.Size.Y.Offset >= 38 + 3 * 32, "movement list clips module rows")
    assert(not cards["Third Person"] and not cards["Zoom Unlocker"] and not cards["Player Outlines"])
    assert(not cards["Hide Visuals"] and not cards["Named Presets"] and not cards["Preset Profiles"])
    assert(not IS_GENERIC or not cards["Kill Chat"],"Arsenal kill chat remains")
    local function control(section,name)
        local key = (section == "Fly" or section == "Noclip") and "Movement" or "Combat"
        key ..= "/"..gameName.."/"..section.."/"..name
        for _, option in ipairs(ConfigControls) do if option.Key == key then return option end end
        error("missing "..key)
    end
    control("Aimbot","Aimbot").Set(true)
    assert(RivalsAim.Aimbot.Enabled and not RivalsAim.AutoShoot.Enabled,"aimbot enabled auto firing")
    control("Auto Shoot","Auto Shoot").Set(true)
    assert(RivalsAim.AutoShoot.Enabled)
    control("Auto Shoot","Maximum Shoot Distance").Set(321)
    assert(RivalsAim.AutoShoot.MaxDistance == 321)
    control("Aimbot","Aim Mode").Set("Legit")
    assert(RivalsAim.Aimbot.LegitMode and not RivalsAim.Aimbot.AutomaticSnap)
    control("Auto Shoot","Auto Shoot").Set(false)
    control("Aimbot","Aimbot").Set(false)
    cards.Aimbot.MouseButton2Click:Fire()
    local combat = board:FindFirstChild("CategoryLayer"):FindFirstChild("Combat")
    assert(combat:FindFirstChildOfClass("ScrollingFrame"):FindFirstChild("AimbotSettings").Visible,"settings do not expand")
    Settings.ActiveSearchBox.Text="noclip"
    Settings.ActiveSearchBox:GetPropertyChangedSignal("Text"):Fire()
    assert(cards.Noclip.Visible and not cards.Aimbot.Visible,"module search is broken")
    assert(T.accent.B == 1 and T.accent.R < 0.3,"blue accent missing")
end
print("PASS imported UI: Arsenal/Rivals flat blue menu, distinct modules, retired cards absent, settings, search, independent firing controls")
do
    local function character()
        local model = new("Model",{},workspace)
        local root = new("BasePart",{Name="HumanoidRootPart",Position=Vector3.new(0,10,0),CFrame=CFrame.new(),CanCollide=true},model)
        local hum = new("Humanoid",{Name="Humanoid",Health=100,PlatformStand=false,AutoRotate=true},model)
        function model:WaitForChild(name) return self:FindFirstChild(name) end
        return model,root,hum
    end
    local first, root = character()
    LocalPlayer.Character = first
    Settings.SelectedGame = "Arsenal"
    Settings.FlyEnabled, Settings.NoclipEnabled = false, false
    Fly.Start()
    assert(root.CanCollide,"Fly enabled noclip automatically")
    Fly.Stop()
    Settings.FlyEnabled, Settings.NoclipEnabled = true, true
    CharacterCollision.SetManual(true)
    assert(root.CanCollide,"noclip applied before flight support")
    Fly.Start()
    assert(not root.CanCollide and first:FindFirstChild("HumanoidRootPart"):FindFirstChild("RiftFlightHover"))
    local second, newRoot = character()
    LocalPlayer.Character = second
    CharacterCollision.Apply()
    assert(newRoot.CanCollide,"new character lost collision before hover was ready")
    LocalPlayer.CharacterAdded:Fire(second)
    assert(Settings.FlightReadyCharacter == second and not newRoot.CanCollide)
    CharacterCollision.SetManual(false)
    assert(newRoot.CanCollide,"Noclip disable failed while flying")
    Fly.Stop()
    Settings.FlyEnabled = false
    CharacterCollision.Reset()
end
print("PASS imported movement: independent Fly/Noclip and collision held until hover after respawn")
do
    local originalSize = Vector3.new(2,1,1)
    local head = {Parent=true,Position=Vector3.new(2,0,0),Size=originalSize,CanCollide=true,CanTouch=true,Massless=false,Transparency=0,
        IsA=function(_,name) return name=="BasePart" end}
    local hum = {Health=100}
    local enemy = {Neutral=false,Team=2,Character={FindFirstChild=function() return head end,FindFirstChildOfClass=function() return hum end}}
    local owner = {Neutral=false,Team=1,Character={FindFirstChild=function() return {Position=Vector3.zero} end,FindFirstChildOfClass=function() return nil end}}
    local fakePlayers = {GetPlayers=function() return {owner,enemy} end}
    local hitboxes = RivalsAim.MakeArsenalHitboxes({Player=owner,Players=fakePlayers,Vector=Vector3})
    hitboxes.Tick(true,12,100)
    assert(head.Size.X==12 and not head.CanCollide and not head.CanTouch and head.Transparency==1)
    hum.Health=0
    hitboxes.Tick(true,12,100)
    assert(head.Size==originalSize and head.CanCollide and head.CanTouch and not head.Massless and head.Transparency==0)
    hum.Health=100
    hitboxes.Tick(true,12,100)
    hitboxes.Close()
    assert(head.Size==originalSize and head.CanCollide)
end
print("PASS imported wallbang hitboxes: enemy changes, dead-target restoration, unload cleanup")

do
    Settings.SelectedGame="Arsenal"
    Window.Visible, RivalsUI.Visible = false, false
    for _, board in pairs(Settings.GameBoards) do board.Visible=false end
    local target={Position=Vector3.new(0,0,100),IsDescendantOf=function() return true end}
    local camera={CFrame={Position=Vector3.zero,LookVector=Vector3.new(0,0,1)}}
    RivalsAim.AutoShoot.Enabled=false
    RivalsAim.Aimbot.Enabled=true
    autoFire(RivalsAim.Aimbot,nil,target,camera)
    assert(stopped>0 and firingWanted==nil,"aimbot caused shots with auto shoot off")
    RivalsAim.AutoShoot.Enabled=true
    RivalsAim.AutoShoot.MaxDistance=200
    autoFire(RivalsAim.Aimbot,nil,target,camera)
    assert(firingWanted==true,"independent trigger did not fire on aligned target")
    RivalsAim.AutoShoot.MaxDistance=50
    autoFire(RivalsAim.Aimbot,nil,target,camera)
    assert(firingWanted==false,"auto shoot ignored distance limit")
    RivalsAim.AutoShoot.MaxDistance=200
    sight=false
    autoFire(RivalsAim.Aimbot,nil,target,camera)
    assert(firingWanted==false,"auto shoot fired through blocked sight")
    sight=true
    RivalsAim.Aimbot.Enabled=false
    autoFire(RivalsAim.AutoShoot,nil,target,camera)
    assert(firingWanted==true,"trigger depended on aimbot being enabled")
    silentTarget={Position=Vector3.new(100,0,100),IsDescendantOf=function() return true end}
    RivalsAim.Enabled=true
    autoFire(RivalsAim.AutoShoot,nil,nil,camera)
    assert(firingWanted==true,"silent aim target was not used off crosshair")
    RivalsAim.AutoShoot.MaxDistance=50
    autoFire(RivalsAim.AutoShoot,nil,target,camera)
    assert(firingWanted==false,"silent target bypassed shoot distance")
    RivalsAim.Enabled=false
    RivalsAim.AutoShoot.MaxDistance=200
    autoFire(RivalsAim.AutoShoot,nil,silentTarget,camera)
    assert(firingWanted==false,"trigger ignored alignment with silent aim off")
end
print("PASS imported Auto Shoot: disabled aim never fires, independent trigger, alignment, visibility, range")
do
    local wall={IsA=function(_,kind) return kind=="BasePart" end}
    local map={}
    function workspace:FindFirstChild(name) if name=="Map" then return map end end
    raycastResult=function(origin,direction,params)
        if params.FilterDescendantsInstances[1]==map then
            if origin.Z >= 7 then return nil end
            return {Instance=wall,Position=Vector3.new(0,0,2)}
        end
        return {Instance=wall,Position=Vector3.new(0,0,origin.Z>7 and 7 or 2)}
    end
    assert(arsenalWallbangWithinDistance(Vector3.zero,Vector3.new(0,0,20),nil,10))
    assert(not arsenalWallbangWithinDistance(Vector3.zero,Vector3.new(0,0,20),nil,3),"thick wall exceeded budget")
    raycastResult=nil
end
print("PASS wallbang distance: penetrable surface accepted, thick surface rejected")
