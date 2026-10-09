-- Restart Roblox first. This starts Rift with optional modules off and preserves saved settings.
local build = "20261009-rift-performance-music-k310"
assert(game.PlaceId == 13687899540 or game.GameId == 4750561026,
    "Rift crash diagnostic is for Cold War")
local url = "https://raw.githubusercontent.com/zynxstellar/sunset.wtf/3bc9da81ec561738e4a4e5b4dfbd6cbf46420e73/alua"
local ok, source = pcall(game.HttpGet, game, url)
assert(ok and type(source) == "string", "Rift diagnostic download failed")
assert(source:match('local SUNSET_BUILD = "([^"]+)"') == build, "Rift diagnostic received a different build")
local function replaceOnce(before, after)
    local first, last = source:find(before, 1, true)
    assert(first and not source:find(before, last + 1, true), "Rift diagnostic source layout changed")
    source = source:sub(1, first - 1) .. after .. source:sub(last + 1)
end
replaceOnce("    function Persistence.Save()", "    function Persistence.Save()\n        if true then return false end")
replaceOnce("    function Persistence.Restore(gameName, menuKeyControl)",
    "    function Persistence.Restore(gameName, menuKeyControl)\n        if true then return false end")
replaceOnce("    Persistence.Restore(detectedGame, menuKeyControl)", [==[
    for _, control in ipairs(ConfigControls) do
        if control.Kind == "toggle" then control.Set(false) end
    end
    for _, control in ipairs(ConfigControls) do
        if control.Key == "Visuals/Cold War/Session Info/Session Info" then control.Set(true) end
    end
    local diagnosticAge, diagnosticSample, diagnosticFrames, diagnosticFPS = 0, 0, 0, 0
    track(RunService.RenderStepped:Connect(function(dt)
        diagnosticAge += dt
        diagnosticSample += dt
        diagnosticFrames += 1
        if diagnosticSample < 2 then return end
        diagnosticFPS = math.floor(diagnosticFrames / diagnosticSample + 0.5)
        diagnosticSample, diagnosticFrames = 0, 0
        if typeof(writefile) ~= "function" then return end
        local enabled = {}
        for _, control in ipairs(ConfigControls) do
            if control.Kind == "toggle" and control.Get() == true then enabled[#enabled + 1] = control.Key end
        end
        pcall(writefile, "SunsetConfigs/RiftCrashDiagnostic.txt",
            "Build: " .. SUNSET_BUILD .. "\nDiagnostic UI start: true\nAlive seconds: "
            .. math.floor(diagnosticAge) .. "\nFPS: " .. diagnosticFPS
            .. "\nEnabled controls:\n" .. table.concat(enabled, "\n"))
    end))
    print("[Rift diagnostic] UI started; optional modules and auto reinject are off. Saved settings are untouched.")
]==])
local chunk, errorMessage = loadstring(source, "=Rift Cold War crash diagnostic")
assert(chunk, errorMessage)
print("[Rift diagnostic] Verified " .. build)
chunk()
