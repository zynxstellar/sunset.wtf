local function run(mode)
    local environment, files = {}, {}
    local source = "mock client"
    local game = {PlaceId = 6872265039}
    local getgenv = function() return environment end
    local typeof = type
    local makefolder = function() end
    local writefile = function(path, value) files[path] = value end
    local loadstring = function()
        assert(files["SunsetConfigs/RiftStartup.txt"]:find("Compiling client", 1, true), "compile began before checkpoint")
        if mode == "compile" then return nil, "bad compile" end
        return function()
            assert(files["SunsetConfigs/RiftStartup.txt"]:find("Executing client", 1, true), "execution began before checkpoint")
            environment.SunsetStartupTrace("Loading menu controls...")
            if mode == "runtime" then error("bad runtime") end
        end
    end
    local ok = pcall(function()
        -- INSERT_STARTUP_WRAPPER
    end)
    return ok, files["SunsetConfigs/RiftStartup.txt"]
end
local ok, last = run("success")
assert(ok and last:find("Stage: Ready", 1, true))
ok, last = run("compile")
assert(not ok and last:find("Compile failed: bad compile", 1, true))
ok, last = run("runtime")
assert(not ok and last:find("Startup error:", 1, true) and last:find("bad runtime", 1, true))
print("PASS startup checkpoints: before compile/execute, ready, compile and runtime failures preserved")
