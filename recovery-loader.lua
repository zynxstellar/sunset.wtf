-- Recovery starts with module defaults and preserves existing saved profiles.
-- Auto reinjection, automatic startup webhook, and menu blur stay paused.
local environment = (typeof(getgenv) == "function" and getgenv()) or _G
environment.SunsetRecovery = true
local source = game:HttpGet("https://raw.githubusercontent.com/zynxstellar/sunset.wtf/6f0437d23eaa87f9b9f4793f4cd5cc5cbe95adaa/loader.lua")
local chunk, err = loadstring(source, "=RIFT recovery loader")
assert(chunk, "RIFT: recovery loader failed to compile: " .. tostring(err))
chunk()
