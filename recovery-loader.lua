-- Recovery starts with module defaults and preserves existing saved profiles.
-- Auto reinjection, automatic startup webhook, and menu blur stay paused.
local environment = (typeof(getgenv) == "function" and getgenv()) or _G
environment.SunsetRecovery = true
local source = game:HttpGet("https://raw.githubusercontent.com/zynxstellar/sunset.wtf/56d12642c7c6e5ba1272f342a4f4224075ba2ecf/loader.lua")
local chunk, err = loadstring(source, "=RIFT recovery loader")
assert(chunk, "RIFT: recovery loader failed to compile: " .. tostring(err))
chunk()
