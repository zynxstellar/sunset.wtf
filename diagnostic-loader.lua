-- Rift diagnostic startup: deliberately does not download or execute the full client.
-- Uses standard Roblox UI only. No game modules, Drawing objects, or executor hooks.
local Players = game:GetService("Players")
local player = Players.LocalPlayer
if not player then warn("[Rift diagnostic] Local player is not ready.") return end
local root
local function leave(message)
    pcall(function() player:Kick(message) end)
end
local ok, failure = pcall(function()
    local playerGui = player:WaitForChild("PlayerGui", 10)
    assert(playerGui, "PlayerGui did not become available")
    local previous = playerGui:FindFirstChild("RiftCrashDiagnostic")
    if previous then previous:Destroy() end
    root = Instance.new("ScreenGui")
    root.Name = "RiftCrashDiagnostic"
    root.ResetOnSpawn = false
    root.DisplayOrder = 100
    local card = Instance.new("Frame")
    card.Size = UDim2.fromOffset(320, 176)
    card.Position = UDim2.new(0.5, -160, 0.5, -88)
    card.BackgroundColor3 = Color3.fromRGB(22, 27, 41)
    card.BorderSizePixel = 0
    card.Parent = root
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = card
    local function text(message, y, height, size)
        local label = Instance.new("TextLabel")
        label.BackgroundTransparency = 1
        label.Position = UDim2.fromOffset(16, y)
        label.Size = UDim2.new(1, -32, 0, height)
        label.Font = Enum.Font.Gotham
        label.TextSize = size
        label.TextColor3 = Color3.fromRGB(242, 244, 255)
        label.TextWrapped = true
        label.Text = message
        label.Parent = card
        return label
    end
    text("RIFT / DIAGNOSTIC", 14, 24, 16).Font = Enum.Font.GothamBold
    text("Full client paused.\nThis menu has no gameplay features running.", 44, 52, 13)
    local function button(caption, x, callback)
        local button = Instance.new("TextButton")
        button.Position = UDim2.fromOffset(x, 118)
        button.Size = UDim2.fromOffset(138, 38)
        button.BackgroundColor3 = Color3.fromRGB(74, 64, 128)
        button.BorderSizePixel = 0
        button.Font = Enum.Font.GothamBold
        button.TextSize = 13
        button.TextColor3 = Color3.fromRGB(242, 244, 255)
        button.Text = caption
        button.Parent = card
        button.Activated:Connect(callback)
    end
    button("Close menu", 16, function() pcall(function() root:Destroy() end) end)
    button("Leave game", 166, function() leave("Rift diagnostic: you chose to leave the game.") end)
    root.Parent = playerGui
end)
if not ok then
    if root then pcall(function() root:Destroy() end) end
    warn("[Rift diagnostic] Startup stopped: " .. tostring(failure))
    leave("Rift diagnostic startup failed. The full client was not loaded.")
end
