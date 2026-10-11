-- Recovery starts with module defaults and preserves existing saved profiles.
-- Auto reinjection, automatic startup webhook, and menu blur stay paused.
local environment = (typeof(getgenv) == "function" and getgenv()) or _G
environment.SunsetRecovery = true
local source = game:HttpGet("https://raw.githubusercontent.com/zynxstellar/sunset.wtf/92ee61f5f7850acd1f1efb18ea04dcbfa88d2443/loader.lua")
local chunk, err = loadstring(source, "=RIFT recovery loader")
assert(chunk, "RIFT: recovery loader failed to compile: " .. tostring(err))
chunk()
