local function isRivalsMode(name) return name=="Blox Fruits" end
Settings.SelectedGame="Blox Fruits"
Settings.StartupStage=function() end
Settings.RunCallback=function(callback,...) return callback(...) end
T.bg,T.panel,T.inner,T.element,T.border,T.gold=color(0,0,0),color(0,0,0),color(0,0,0),color(0,0,0),color(0,0,0),color(0,0,1)
local movement={FlySpeed=50,WalkSpeed=32}
movement.SetFly=function(on) movement.FlyEnabled=on end
movement.SetSpeed=function(on) movement.SpeedEnabled=on end
local function makeTab() return MainTab end
local function makeSection(column,title) return gameSection("Blox Fruits",column,title) end
-- INSERT_BLOX_UI
BedWars.BuildUI("Blox Fruits")
local board=Settings.GameBoards["Blox Fruits"]
assert(board and board:FindFirstChild("CategoryLayer"),"shared column menu missing")
local layer=board:FindFirstChild("CategoryLayer")
assert(layer:FindFirstChild("Movement").Size.Y.Offset==108,"two modules do not fit")
for _,name in ipairs({"Combat","Player","Visuals","Misc","Fun","Sunset"}) do
    assert(layer:FindFirstChild(name).Size.Y.Offset==32,"empty category is not collapsed")
end
local toggles=0
for _,control in ipairs(ConfigControls) do
    if control.Kind=="toggle" then
        toggles+=1
        control.Set(true)
    end
end
assert(toggles==2 and movement.FlyEnabled and movement.SpeedEnabled,"module toggles did not reach movement")
for _,obj in ipairs(board:GetDescendants()) do
    if obj.Name=="Fly" or obj.Name=="Speed" then
        assert(obj:IsA("TextButton") and obj.Size.Y.Offset==30,"module does not use shared row styling")
    end
end
local flySettings
for _,obj in ipairs(board:GetDescendants()) do if obj.Name=="FlySettings" then flySettings=obj end end
assert(flySettings and not flySettings.Visible,"settings should start closed")
local flyCard
for _,obj in ipairs(board:GetDescendants()) do if obj.Name=="Fly" then flyCard=obj end end
flyCard:FindFirstChild("SettingsButton").MouseButton1Click:Fire()
assert(flySettings.Visible,"shared settings expander failed")
print("PASS Blox shared UI: actual board, two movement modules, toggle wiring, expandable settings, collapsed empty categories")
