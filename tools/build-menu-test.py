"""Build an isolated test of Rift's actual UI toolkit, before gameplay initialization."""
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def build():
    source = (ROOT / 'alua').read_text(encoding='utf-8')
    start = source.index('local Players = game:GetService("Players")')
    end = source.index('local Fly = {}', start)
    ui = source[start:end]
    ui = re.sub(r'local SUNSET_BUILD = "[^"]+"',
                'local SUNSET_BUILD = "20261010-rift-menu-test-1"', ui, count=1)
    ui = ui.replace('IsColdWar     = game.PlaceId == 13687899540 or game.GameId == 4750561026,',
                    'IsColdWar     = false,', 1)
    # Test PlayerGui hosting, without calling the executor's protected UI APIs.
    a = ui.index('function Settings.ParentColdWarUI(')
    b = ui.index('local function new(', a)
    ui = ui[:a] + ui[b:]
    ui = ui.replace('        Settings.ParentColdWarUI(i)', '        i.Parent = parent', 1)
    ui = ui.replace('{ "MenuUI", "EspGui" }', '{ "MenuUI", "RiftCrashDiagnostic" }', 1)
    tail = '''
local firstTab
for _, name in ipairs({ "Combat", "Movement", "Player", "Visuals", "Misc", "Fun", "Dev Tools", "Rift" }) do
    local tab = makeTab(name)
    if not firstTab then firstTab = tab end
    local section = makeSection(tab.Left, "Menu stability test")
    Elements.Label(section, "Gameplay modules are paused.")
    Elements.Label(section, "Test tabs, dragging and RightShift.")
    if name == "Rift" then
        Elements.Keybind(section, "Menu Key")
        Elements.Button(section, "Leave game", function()
            LocalPlayer:Kick("Rift menu test: you chose to leave the game.")
        end)
    end
end
Title.Text = "  Rift | Menu stability test"
Settings.SelectedGame = "Menu Test"
if ENV.SunsetLoading and ENV.SunsetLoading.Gui then ENV.SunsetLoading.Gui:Destroy() end
ENV.SunsetLoading = nil
Window.Visible = true
Settings.MenuVisibleSnapshot = true
firstTab.Select()
onMenuVisibility()
ENV.SunsetAbortStartup = nil
print("[Rift menu test] UI ready; no gameplay modules were initialized.")
'''
    body = 'local ENV = ...\n' + ui + tail
    assert 'local Fly = {}' not in body and 'Drawing.new' not in body
    assert 'hookfunction(' not in body and 'getloadedmodules(' not in body
    return '''-- Menu stability test, generated from Rift's actual UI toolkit.
-- Gameplay features remain paused. This does not load the full client.
local source = [========[\n''' + body + ''']========]
local chunk, failure = loadstring(source, "=Rift menu stability test")
assert(chunk, failure)
local state = { SunsetRecovery = true }
local ok, message = pcall(chunk, state)
if not ok then
    if type(state.SunsetAbortStartup) == "function" then pcall(state.SunsetAbortStartup) end
    warn("[Rift menu test] " .. tostring(message))
    pcall(function()
        game:GetService("Players").LocalPlayer:Kick("Rift menu test failed during startup.")
    end)
end
'''


if __name__ == '__main__':
    (ROOT / 'menu-test-loader.lua').write_text(build(), encoding='utf-8', newline='\n')
