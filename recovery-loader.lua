-- Recovery starts with module defaults and preserves existing saved profiles.
-- Auto reinjection, automatic startup webhook, and menu blur stay paused.
local environment = (typeof(getgenv) == "function" and getgenv()) or _G
environment.SunsetRecovery = true
local source = game:HttpGet("https://raw.githubusercontent.com/zynxstellar/sunset.wtf/ba13c49b7f768e2046c0a640711bad0b2297d6c2/loader.lua")
local chunk, err = loadstring(source, "=RIFT recovery loader")
assert(chunk, "RIFT: recovery loader failed to compile: " .. tostring(err))
chunk()
