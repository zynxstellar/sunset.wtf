-- INSERT_DIAGNOSTIC_RELEASE
local nativeLoadstring = loadstring
local function run(download, failCompile, bedwars)
    local ran, patched = false, nil
    local game = {PlaceId = bedwars and 8560631822 or 13687899540, GameId = bedwars and 2619619496 or 4750561026,
        HttpGet = function() assert(download, "network failed") return download end}
    local loadstring = function(source)
        patched = source
        local inner = source:match("local source = %[%=%=%=%=%=%=%=%=%[(.-)%]%=%=%=%=%=%=%=%=%]")
        assert(inner, "embedded client missing")
        assert(nativeLoadstring(inner), "patched client did not compile")
        if failCompile then return nil, "mock compile failure" end
        return function() ran = true end
    end
    local success, message = pcall(function()
        -- INSERT_DIAGNOSTIC_LOADER
    end)
    return success, message, ran, patched
end
local ok, message, ran, patched = run(releaseSource)
assert(ok and ran, tostring(message))
assert(patched:find("function Persistence.Save()\n        if true then return false end", 1, true),
    "diagnostic could overwrite saved settings")
assert(patched:find("function Persistence.Restore(gameName, menuKeyControl)\n        if true then return false end", 1, true),
    "diagnostic restored suspect modules")
assert(patched:find('if control.Kind == "toggle" then control.Set(false) end', 1, true))
assert(patched:find('SunsetConfigs/RiftCrashDiagnostic.txt', 1, true))
ok, message, ran = run(releaseSource, false, true)
assert(ok and ran, "BedWars match diagnostic failed: " .. tostring(message))
ok, message, ran = run(releaseSource:gsub('20261009%-rift%-startup%-stability%-k311', 'wrong-build'))
assert(not ok and not ran, "wrong build ran")
ok, message, ran = run(nil)
assert(not ok and not ran, "download failure ran")
ok, message, ran = run(releaseSource, true)
assert(not ok and not ran, "compile failure ran")
print("PASS crash diagnostic loader: exact source, patched client compiles, settings preserved, toggles disabled, local heartbeat, failure guards")
