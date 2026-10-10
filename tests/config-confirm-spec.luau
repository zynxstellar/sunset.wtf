local now=0
local os={clock=function() return now end}
local typeof=type
local Settings={SelectedGame="Cold War",MenuKey={Name="RightShift"}}
local SettingsTab={Right={}}
local T={dim={}}
local ConfigControls={}
local Persistence={SavedHUDPositions=function() return {} end}
local writes,deletes={},{}
local function writefile(path,data) table.insert(writes,path) end
local function delfile(path) table.insert(deletes,path) end
local HttpService={JSONEncode=function() return "json" end}
local connections,buttons={},{}
local function track(c) table.insert(connections,c) end
local function makeSection() return {} end
local textChanged
local nameBox={Text="default",GetPropertyChangedSignal=function()
    return {Connect=function(_,fn) textChanged=fn return {Disconnect=function() end} end}
end}
local selector
local Elements={}
function Elements.TextBox() return {FindFirstChildOfClass=function() return nameBox end} end
function Elements.Dropdown(_,_,_,default,callback)
    selector={Value=default,SetOptions=function() end}
    selector.Set=function(value) selector.Value=value callback(value) end
    return selector
end
function Elements.Label() return {} end
function Elements.Button(_,name,callback)
    local button={Visible=true,Text=name,Click=callback}
    buttons[name]=button
    return button
end
-- INSERT_CONFIG_CONFIRM
local function click(name) buttons[name].Click() end
assert(not buttons.Confirm.Visible and not buttons.Cancel.Visible)
click("Save Config") click("Save Config")
assert(#writes==0 and buttons.Confirm.Visible,"save request wrote without confirmation")
click("Cancel") click("Confirm") assert(#writes==0)
click("Save Config") click("Confirm") click("Confirm")
assert(#writes==1 and writes[1]=="SunsetConfigs/Cold_War_default.json","save confirmation failed or repeated")
click("Delete Config") click("Delete Config") assert(#deletes==0)
click("Confirm") assert(#deletes==1 and deletes[1]==writes[1])
click("Save Config") now=16 click("Confirm") assert(#writes==1,"expired save executed")
click("Save Config") nameBox.Text="changed" textChanged() click("Confirm")
assert(#writes==1,"renamed config retained confirmation")
click("Save Config") Settings.SelectedGame="Rivals" click("Confirm") assert(#writes==1)
Settings.SelectedGame="Cold War"
click("Save Config") click("Delete Config") click("Confirm")
assert(#writes==1 and #deletes==2,"switching action executed stale save")
click("Delete Config") selector.Value="another" click("Confirm") assert(#deletes==2)
click("Save Config") click("Refresh Configs") click("Confirm") assert(#writes==1)
click("Save Config")
for _,connection in ipairs(connections) do connection:Disconnect() end
click("Confirm") assert(#writes==1,"unload retained pending confirmation")
print("PASS config confirmation: explicit save/delete confirmation, cancel, repeat, expiry, name/game/selection changes and unload")
