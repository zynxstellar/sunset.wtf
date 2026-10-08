local Settings = { SelectedGame = "Project Delta" }
local options = { OutlinesOn = false, OutlineColor = "initial" }
function options.Apply() end
function Settings.SetupPlayerESP(game)
    assert(game == "Project Delta")
    return options
end
function Settings.SetupColdWarVisibility(game)
    assert(game == "Project Delta")
end
local BedWars = { BuildUI = function(game) assert(game == "Project Delta") end }
local VisualsTab, SettingsTab = { Left = {} }, { Left = {} }
local function gameSection(game, _, name) return game .. "/" .. name end
local controls = {}
local Elements = {}
local function control(section, name, initial, callback)
    local result = { Value = initial }
    function result.Set(value) result.Value = value callback(value) end
    controls[section .. "/" .. name] = result
    return result
end
function Elements.Toggle(section, name, initial, callback)
    return control(section, name, initial, callback)
end
function Elements.Slider(section, name, minimum, maximum, initial, unit, callback)
    return control(section, name, initial, callback)
end
function Elements.ColorPicker(section, name, initial, callback)
    return control(section, name, initial, callback)
end
local camera = { FieldOfView = 70 }
local workspace = { CurrentCamera = camera }
local callbacks, cleanup = {}, {}
local RunService = { RenderStepped = { Connect = function(_, callback)
    table.insert(callbacks, callback)
    return { Disconnect = function() end }
end } }
local function track(connection) table.insert(cleanup, connection) end
-- INSERT_PROJECT_DELTA_PRODUCTION
Settings.SetupProjectDelta()
assert(controls["Project Delta/ESP Boxes/ESP Boxes"] == nil,
    "Project Delta setup should use the shared ESP controls")
controls["Project Delta/Player Outlines/Player Outlines"].Set(true)
assert(options.OutlinesOn)
controls["Project Delta/Player Outlines/Color"].Set("cyan")
assert(options.OutlineColor == "cyan")
controls["Project Delta/FOV/FOV"].Set(true)
assert(camera.FieldOfView == 80)
controls["Project Delta/FOV/Value"].Set(110)
assert(camera.FieldOfView == 110)
local nextCamera = { FieldOfView = 65 }
workspace.CurrentCamera = nextCamera
callbacks[1]()
assert(camera.FieldOfView == 70 and nextCamera.FieldOfView == 110,
    "camera replacement did not restore the old FOV")
controls["Project Delta/FOV/FOV"].Set(false)
assert(nextCamera.FieldOfView == 65)
assert(controls["Project Delta/Module List/Module List"])
print("PASS Project Delta: visuals setup, outlines, FOV, camera replacement and restore")
