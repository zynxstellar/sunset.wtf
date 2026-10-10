-- Menu stability test, generated from Rift's actual UI toolkit.
-- Gameplay features remain paused. This does not load the full client.
local source = [========[
local ENV = ...
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local Camera = workspace.CurrentCamera
local SUNSET_BUILD = "20261010-rift-menu-test-1"
local BRAND = "RIFT"
local RIFT_KILL_MESSAGE = "RIFT ON TOP 10$ LIFETIME, STEAL AN EGG, RIVALS, BEDWARS, ZSA, JJS, ARSENAL!"
local SUNSET_LOCAL_SOURCE = "SunsetConfigs/SunsetCurrent.lua"




if typeof(ENV.SunsetUnload) == "function" then
    pcall(ENV.SunsetUnload)
end

do
    local previous = ENV.SunsetColdWarHitSounds
    if previous and type(previous.Restore) == "function" then pcall(previous.Restore) end
    ENV.SunsetColdWarHitSounds = nil
end


local Connections = {}
local function track(conn)
    table.insert(Connections, conn)
    return conn
end




local T = {
    bg        = Color3.fromRGB(11, 17, 28),
    panel     = Color3.fromRGB(17, 26, 42),
    inner     = Color3.fromRGB(21, 33, 51),
    element   = Color3.fromRGB(27, 43, 65),
    elementHi = Color3.fromRGB(35, 56, 84),
    border    = Color3.fromRGB(42, 63, 89),
    outer     = Color3.fromRGB(51, 80, 115),
    red       = Color3.fromRGB(64, 145, 255),
    accent    = Color3.fromRGB(64, 145, 255),
    gold      = Color3.fromRGB(112, 182, 255),
    text      = Color3.fromRGB(242, 244, 255),
    dim       = Color3.fromRGB(154, 167, 195),
    muted     = Color3.fromRGB(154, 167, 195),
    font      = Enum.Font.GothamMedium,
}
local BedWars
local bedWarsHiddenSections = {}
local bedWarsNamesToggle
local flyToggle
local zoomUnlockToggle
local spinToggle
local AutoReinject = { enabled = true }
local SUNSET_REINJECT_TICKET = "SunsetConfigs/SunsetReinjectTicket.txt"
function AutoReinject.Cancel()
    AutoReinject.enabled, AutoReinject.queued = false, false
    ENV.SunsetAutoReinject = false
    ENV.SunsetStartupToken = nil
    if typeof(writefile) == "function" then pcall(writefile, SUNSET_REINJECT_TICKET, "cancelled") end
end
local RefreshConfigList




local Settings = {
    RecoveryMode  = ENV.SunsetRecovery == true,
    IsColdWar     = false,
    GameBoards     = {},
    MenuKey        = Enum.KeyCode.RightShift,
    FlyEnabled     = false,
    FlySpeed       = 50,
    FlyCoast       = 0.5,
    NoclipEnabled  = false,
    EspEnabled     = false,
    EspNames       = true,
    EspTeamCheck   = false,
    TpTeamCheck    = true,
    AutoTp         = false,
    AutoTpDelay    = 0.5,
    TpMaxDistance  = 150,
    TpIgnoreBelow  = true,
    TpBelowLimit   = 25,
    GodMode        = false,
    EspBoxColor    = Color3.fromRGB(255, 255, 255),
    WatermarkOn    = true,
    MenuBlurOn     = true,
    ModuleListOn   = true,
    DisableMoveOpen= false,
}
local RivalsAim = { Enabled = false, FOVVisible = false, Radius = 150,
    AimPart = "Head", WallCheck = true,
    Assist = { Enabled = false, AimPart = "Head", WallCheck = true, HoldMouse = true, Strength = 8 },
    Aimbot = { Enabled = false, AimPart = "Head", WallCheck = false, HoldMouse = true, MaxDistance = 1000 },
    Available = false }
local RivalsVisuals = { BoxesOn = false, OutlinesOn = false,
    TargetHUDOn = false, TargetHUDBarTime = 0.3, MusicOverlayOn = false,
    BoxColor = Color3.fromRGB(139, 92, 246), OutlineColor = Color3.fromRGB(77, 224, 208) }
local RivalsKillChat = { Enabled = false, Cooldown = 2, Queue = {} }




local function new(class, props, parent)
    local i = Instance.new(class)
    for k, v in pairs(props) do i[k] = v end
    if Settings.IsColdWar and not Settings.RecoveryMode and class == "ScreenGui" and parent == PlayerGui then
        i.Parent = parent
    else
        i.Parent = parent
    end
    if class == "ScreenGui" or class == "BlurEffect" then
        track({ Disconnect = function() i:Destroy() end })
    end
    return i
end

local function border(parent, color, thick)
    return new("UIStroke", { Color = color or T.border, Thickness = thick or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, parent)
end

local function label(parent, text, size, color, align)
    return new("TextLabel", {
        BackgroundTransparency = 1,
        Text = text,
        Font = T.font,
        TextSize = size or 13,
        TextColor3 = color or T.text,
        TextXAlignment = align or Enum.TextXAlignment.Left,
        Size = UDim2.new(1, 0, 0, 16),
    }, parent)
end

local function riftAsset(_filename)
    -- Use drawn UI icons. Optional image registration goes through executor
    -- native code and cannot be made crash-safe with a Lua pcall.
    return nil
end

local function riftTrashFallback(parent, color)
    new("Frame", {
        Position = UDim2.fromOffset(7, 8), Size = UDim2.fromOffset(14, 2),
        BackgroundColor3 = color, BorderSizePixel = 0,
    }, parent)
    new("Frame", {
        Position = UDim2.fromOffset(11, 5), Size = UDim2.fromOffset(6, 2),
        BackgroundColor3 = color, BorderSizePixel = 0,
    }, parent)
    local bin = new("Frame", {
        Position = UDim2.fromOffset(9, 11), Size = UDim2.fromOffset(10, 13),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, parent)
    border(bin, color)
end




for _, name in ipairs({ "MenuUI", "RiftCrashDiagnostic" }) do
    local old = PlayerGui:FindFirstChild(name)
    if old then old:Destroy() end
end

ENV.SunsetAbortStartup = function()
    if BedWars then BedWars.Running = false end
    for _, connection in ipairs(Connections) do
        pcall(function() connection:Disconnect() end)
    end
    table.clear(Connections)
    pcall(function() Settings.MenuBlurEffect:Destroy() end)
    local loading = ENV.SunsetLoading
    ENV.SunsetLoading = nil
    if loading and loading.Gui then pcall(function() loading.Gui:Destroy() end) end
    pcall(function() Settings.RootGui:Destroy() end)
    ENV.SunsetAbortStartup = nil
end

local Gui = new("ScreenGui", { Name = "MenuUI", DisplayOrder = 2147483647, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, PlayerGui)
Settings.RootGui = Gui
function Settings.SetupNotifications()
    local screen = new("ScreenGui", { Name = "RiftNotifications", ResetOnSpawn = false,
        IgnoreGuiInset = true, DisplayOrder = 2147483646 }, PlayerGui)
    Settings.NotificationGui = screen
    local alive = true
    track({ Disconnect = function() alive = false screen:Destroy() end })
    local stack = new("Frame", { AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -20), Size = UDim2.fromOffset(280, 300),
        BackgroundTransparency = 1, BorderSizePixel = 0 }, screen)
    Settings.NotificationStack = stack
    new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder,
        VerticalAlignment = Enum.VerticalAlignment.Bottom }, stack)
    local slots, activeByKey, order = {}, {}, 0
    local pending = {}
    local function renderNotification(title, message, kind)
        if not alive or not screen.Parent then return end
        title, message = tostring(title), tostring(message)
        local key = title .. ":" .. message
        if activeByKey[key] and activeByKey[key].Parent then return end
        order += 1
        local color = kind == "error" and T.red or T.accent
        local duration = kind == "error" and 6 or 4.2
        local slot = new("Frame", { Size = UDim2.fromOffset(280, 66), LayoutOrder = order,
            BackgroundTransparency = 1, BorderSizePixel = 0 }, stack)
        slot:SetAttribute("NotificationKey", key)
        activeByKey[key] = slot
        table.insert(slots, slot)
        if #slots > 4 then
            local oldest = table.remove(slots, 1)
            activeByKey[oldest:GetAttribute("NotificationKey")] = nil
            oldest:Destroy()
        end
        Settings.NotificationActiveCount = #slots
        local toast = new("Frame", { Position = UDim2.fromOffset(300, 0),
            Size = UDim2.fromOffset(280, 66), BackgroundTransparency = 1, BorderSizePixel = 0 }, slot)
        local shadow = new("Frame", { Position = UDim2.fromOffset(0, 3),
            Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.bg,
            BackgroundTransparency = 0.55, BorderSizePixel = 0, ZIndex = 1 }, toast)
        new("UICorner", { CornerRadius = UDim.new(0, 8) }, shadow)
        local card = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = T.inner,
            BackgroundTransparency = 0.02, BorderSizePixel = 0, ZIndex = 2 }, toast)
        new("UICorner", { CornerRadius = UDim.new(0, 8) }, card)
        border(card, T.border).Transparency = 0.4
        local heading = label(card, title:sub(1, 36), 12, T.text)
        heading.Font, heading.ZIndex = Enum.Font.GothamBold, 3
        heading.Position, heading.Size = UDim2.fromOffset(12, 8), UDim2.new(1, -48, 0, 18)
        local badge = new("Frame", { Position = UDim2.new(1, -30, 0, 8),
            Size = UDim2.fromOffset(20, 20), BackgroundColor3 = color,
            BackgroundTransparency = 0.86, BorderSizePixel = 0, ZIndex = 3 }, card)
        new("UICorner", { CornerRadius = UDim.new(0, 8) }, badge)
        local glyph = label(badge, kind == "error" and "!" or "i", 13, color, Enum.TextXAlignment.Center)
        glyph.Font, glyph.ZIndex, glyph.Size = Enum.Font.GothamBold, 4, UDim2.fromScale(1, 1)
        local body = label(card, message:sub(1, 220), 11, T.text)
        body.Font, body.ZIndex = Enum.Font.Gotham, 3
        body.Position, body.Size = UDim2.fromOffset(12, 29), UDim2.new(1, -24, 0, 27)
        body.TextWrapped = true
        body.TextYAlignment = Enum.TextYAlignment.Top
        body.TextTruncate = Enum.TextTruncate.AtEnd
        local rail = new("Frame", { Position = UDim2.new(0, 12, 1, -5),
            Size = UDim2.new(1, -24, 0, 2), BackgroundColor3 = color,
            BackgroundTransparency = 0.88, BorderSizePixel = 0, ZIndex = 3 }, card)
        new("UICorner", { CornerRadius = UDim.new(0, 1) }, rail)
        local progress = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = color,
            BorderSizePixel = 0, ZIndex = 4 }, rail)
        new("UICorner", { CornerRadius = UDim.new(0, 1) }, progress)
        TweenService:Create(toast, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
            { Position = UDim2.fromOffset(0, 0) }):Play()
        TweenService:Create(progress, TweenInfo.new(duration, Enum.EasingStyle.Linear),
            { Size = UDim2.fromScale(0, 1) }):Play()
        task.delay(duration, function()
            if not alive or not screen.Parent or not slot.Parent then return end
            TweenService:Create(toast, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In),
                { Position = UDim2.fromOffset(300, 0) }):Play()
            task.wait(0.21)
            if not alive then return end
            activeByKey[key] = nil
            slot:Destroy()
            local index = table.find(slots, slot)
            if index then table.remove(slots, index) end
            Settings.NotificationActiveCount = #slots
        end)
        return slot
    end
    function Settings.Notify(title, message, kind)
        if not alive then return end
        -- Game callbacks enqueue plain data; only the UI-owned connection touches instances.
        if #pending >= 16 then table.remove(pending, 1) end
        table.insert(pending, { tostring(title), tostring(message), kind })
    end
    track(RunService.Heartbeat:Connect(function()
        local batch = pending
        pending = {}
        for _, item in ipairs(batch) do
            local ok, err = pcall(renderNotification, table.unpack(item))
            if not ok then warn("[Rift] Notification error: " .. tostring(err)) end
        end
    end))
    function Settings.RunCallback(callback, ...)
        local result = table.pack(pcall(callback, ...))
        if not result[1] then
            warn("[Rift] Control error: " .. tostring(result[2]))
            pcall(Settings.Notify, "Control error", result[2], "error")
            return
        end
        return table.unpack(result, 2, result.n)
    end
end
Settings.SetupNotifications()

Settings.MenuBlurEffect = new("BlurEffect", { Name = "SunsetMenuBlur", Size = 0 }, Lighting)
Settings.MenuBlurTween = nil
function Settings.SetMenuBlur(size)
    if not Settings.MenuBlurEffect.Parent then return end
    if Settings.MenuBlurTween then Settings.MenuBlurTween:Cancel() end
    Settings.MenuBlurTween = TweenService:Create(Settings.MenuBlurEffect,
        TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        { Size = size })
    Settings.MenuBlurTween:Play()
end
Settings.SetMenuBlur(Settings.RecoveryMode and 0 or 20)
ENV.SunsetLoading = {}
ENV.SunsetLoading.Gui = new("ScreenGui", {
    Name = "RiftLoading", DisplayOrder = 2147483647,
    ResetOnSpawn = false, IgnoreGuiInset = true,
    ScreenInsets = Enum.ScreenInsets.None,
    ClipToDeviceSafeArea = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, PlayerGui)
ENV.SunsetLoading.Backdrop = new("Frame", {
    Name = "FullScreenBackdrop",
    Position = UDim2.fromOffset(0, -64),
    Size = UDim2.new(1, 0, 1, 128),
    BackgroundColor3 = Color3.fromRGB(16, 18, 29),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ZIndex = 999,
}, ENV.SunsetLoading.Gui)
ENV.SunsetLoading.Overlay = new("Frame", {
    Name = "SunsetLoading", Size = UDim2.fromScale(1, 1),
    BackgroundColor3 = Color3.fromRGB(16, 18, 29),
    BackgroundTransparency = 1, BorderSizePixel = 0,
    ZIndex = 1000,
}, ENV.SunsetLoading.Gui)
ENV.SunsetLoading.Logo = label(ENV.SunsetLoading.Overlay, BRAND, 45,
    Color3.fromRGB(200, 183, 255), Enum.TextXAlignment.Center)
ENV.SunsetLoading.Logo.Font = Enum.Font.GothamBold
ENV.SunsetLoading.Logo.Position = UDim2.new(0.5, -200, 0.37, 0)
ENV.SunsetLoading.Logo.Size = UDim2.fromOffset(400, 56)
ENV.SunsetLoading.Logo.ZIndex = 1001
ENV.SunsetLoading.Status = label(ENV.SunsetLoading.Overlay, "Opening Rift...", 16,
    Color3.fromRGB(242, 244, 255), Enum.TextXAlignment.Center)
ENV.SunsetLoading.Status.Font = Enum.Font.GothamMedium
ENV.SunsetLoading.Status.Position = UDim2.new(0.5, -200, 0.52, 0)
ENV.SunsetLoading.Status.Size = UDim2.fromOffset(400, 24)
ENV.SunsetLoading.Status.ZIndex = 1001
ENV.SunsetLoading.Track = new("Frame", {
    Position = UDim2.new(0.5, -150, 0.58, 0), Size = UDim2.fromOffset(300, 5),
    BackgroundColor3 = Color3.fromRGB(59, 45, 55), BorderSizePixel = 0,
    ZIndex = 1001,
}, ENV.SunsetLoading.Overlay)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, ENV.SunsetLoading.Track)
ENV.SunsetLoading.Fill = new("Frame", {
    Size = UDim2.fromScale(0.05, 1), BackgroundColor3 = T.accent,
    BorderSizePixel = 0, ZIndex = 1002,
}, ENV.SunsetLoading.Track)
new("UICorner", { CornerRadius = UDim.new(1, 0) }, ENV.SunsetLoading.Fill)
TweenService:Create(ENV.SunsetLoading.Fill, TweenInfo.new(1.2, Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out), { Size = UDim2.fromScale(0.88, 1) }):Play()
function Settings.StartupStage(message)
    if type(ENV.SunsetCheckpoint) == "function" then ENV.SunsetCheckpoint(message) end
    print("[Rift startup " .. SUNSET_BUILD .. "] " .. message)
    local loading = ENV.SunsetLoading
    if loading and loading.Status and loading.Status.Parent then loading.Status.Text = message end
end
Settings.StartupStage("Loading menu controls...")

local Window = new("Frame", {
    Name = "Window", Visible = false,
    Size = UDim2.fromOffset(560, 480),
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = T.bg,
    BorderSizePixel = 0,
    Active = true,
}, Gui)
local BedWarsUI
local RivalsUI
Settings.ActiveSearchBox = nil
function Settings.ReadMenuVisible()
    for _, board in pairs(Settings.GameBoards) do
        if board.Parent and board.Visible then return true end
    end
    return Window.Visible or (BedWarsUI and BedWarsUI.Visible)
        or (RivalsUI and RivalsUI.Visible) or false
end
Settings.MenuVisibleSnapshot = Settings.ReadMenuVisible()
track(RunService.Heartbeat:Connect(function()
    local ok, visible = pcall(Settings.ReadMenuVisible)
    if ok then Settings.MenuVisibleSnapshot = visible end
end))
local function anyMenuVisible()
    return Settings.MenuVisibleSnapshot
end
border(Window, T.outer, 1)
local menuScale = new("UIScale", { Scale = 1 }, Window)
local function fitMenu()
    local camera = workspace.CurrentCamera
    if camera then
        menuScale.Scale = math.max(0.2, math.min(1, (camera.ViewportSize.X-24)/560, (camera.ViewportSize.Y-24)/480))
    end
end
fitMenu()
track(RunService.Heartbeat:Connect(fitMenu))
new("UICorner", { CornerRadius = UDim.new(0, 2) }, Window)


local TitleBar = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundColor3 = T.bg, BorderSizePixel = 0 }, Window)
local Title = label(TitleBar, "  Rift", 13)
Title.Size = UDim2.new(1, 0, 1, 0)
new("Frame", { Size = UDim2.new(1, -16, 0, 2), Position = UDim2.fromOffset(8, 22), BackgroundColor3 = T.red, BorderSizePixel = 0 }, Window)

local listeningFor = nil

track(UIS.InputBegan:Connect(function(i, gp)
    if Settings.SelectedGame and not listeningFor
        and not ENV.SunsetLoading and i.KeyCode == Settings.MenuKey
        and (not UIS:GetFocusedTextBox()
            or UIS:GetFocusedTextBox() == Settings.ActiveSearchBox) then
        local board = Settings.GameBoards[Settings.SelectedGame]
        if board then
            board.Visible = not board.Visible
        else
            Window.Visible = not Window.Visible
        end
    end
end))








-- Unlock the menu cursor without intercepting every game property write.
local canHook = false
local useScriptable = false

local savedCamType, savedCamMode, camOffset = nil, nil, nil
local savedMenuInput

local function restoreMenuInput()
    if not savedMenuInput then return end
    local saved = savedMenuInput
    savedMenuInput = nil
    if savedCamType and saved.Camera then saved.Camera.CameraType = savedCamType end
    if savedCamMode then LocalPlayer.CameraMode = savedCamMode end
    savedCamType, savedCamMode, camOffset = nil, nil, nil
    UIS.MouseBehavior = saved.MouseBehavior
    UIS.MouseIconEnabled = saved.MouseIconEnabled
end

local function onMenuVisibility()
    local visible = anyMenuVisible()
    Settings.SetMenuBlur(Settings.RecoveryMode and 0 or (ENV.SunsetLoading and 20
        or (visible and Settings.MenuBlurOn and 16 or 0)))
    if Settings.ActiveSearchBox then
        if not visible then
            Settings.ActiveSearchBox.Text = ""
            Settings.ActiveSearchBox:ReleaseFocus()
        end
    end
    if visible then
        if savedMenuInput then return end
        savedMenuInput = {
            Camera = workspace.CurrentCamera,
            MouseBehavior = UIS.MouseBehavior,
            MouseIconEnabled = UIS.MouseIconEnabled,
        }
        if Settings.SelectedGame ~= "Rivals" and Settings.SelectedGame ~= "Cold War"
            and Settings.SelectedGame ~= "Project Delta" then
            savedCamMode = LocalPlayer.CameraMode
            LocalPlayer.CameraMode = Enum.CameraMode.Classic
        end
        if useScriptable and Settings.SelectedGame ~= "Rivals" and Settings.SelectedGame ~= "Cold War"
            and Settings.SelectedGame ~= "Project Delta" then
            savedCamType = Camera.CameraType
            local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            camOffset = root and root.CFrame:ToObjectSpace(Camera.CFrame) or nil
            Camera.CameraType = Enum.CameraType.Scriptable
        end
        UIS.MouseBehavior = Enum.MouseBehavior.Default
        UIS.MouseIconEnabled = true
    else
        restoreMenuInput()
    end
end
track(Window:GetPropertyChangedSignal("Visible"):Connect(onMenuVisibility))

local function forceUnlock()
    if not anyMenuVisible() then return end
    if useScriptable and Settings.SelectedGame ~= "Rivals" and Settings.SelectedGame ~= "Cold War"
        and Settings.SelectedGame ~= "Project Delta" then
        if Camera.CameraType ~= Enum.CameraType.Scriptable then
            Camera.CameraType = Enum.CameraType.Scriptable
        end

        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root and camOffset then
            Camera.CFrame = root.CFrame * camOffset
        end
    end
    if UIS.MouseBehavior ~= Enum.MouseBehavior.Default then
        UIS.MouseBehavior = Enum.MouseBehavior.Default
    end
    UIS.MouseIconEnabled = true
end


local UNLOCK_NAME = "SunsetCursorUnlock"
pcall(RunService.UnbindFromRenderStep, RunService, UNLOCK_NAME)
RunService:BindToRenderStep(UNLOCK_NAME, Enum.RenderPriority.Last.Value, forceUnlock)
track(RunService.Stepped:Connect(forceUnlock))
track(RunService.Heartbeat:Connect(forceUnlock))


track({ Disconnect = function()
    pcall(RunService.UnbindFromRenderStep, RunService, UNLOCK_NAME)
    restoreMenuInput()
end })


onMenuVisibility()


local Panel = new("Frame", {
    Size = UDim2.new(1, -16, 1, -38),
    Position = UDim2.fromOffset(8, 30),
    BackgroundColor3 = T.panel,
    BorderSizePixel = 0,
}, Window)
border(Panel, T.border)




local TabBar = new("Frame", { Size = UDim2.new(1, -16, 0, 22), Position = UDim2.fromOffset(8, 6), BackgroundTransparency = 1 }, Panel)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, TabBar)

local PageHolder = new("Frame", { Size = UDim2.new(1, -16, 1, -44), Position = UDim2.fromOffset(8, 36), BackgroundTransparency = 1 }, Panel)


local function makeDraggable(frame, handle)
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging, dragStart, startPos = true, i.Position, frame.Position
        end
    end)
    track(UIS.InputChanged:Connect(function(i)
        if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
            local d = i.Position - dragStart
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end))
    track(UIS.InputEnded:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 then dragging = false end
    end))
end

local Tabs, currentTab = {}, nil
local function makeTab(name)
    local btn = new("TextButton", {
        Size = UDim2.new(1 / 8, -6, 0, 26),
        BackgroundColor3 = T.inner,
        BorderSizePixel = 0,
        Text = name,
        Font = T.font,
        TextSize = 13,
        TextColor3 = T.dim,
        AutoButtonColor = false,
    }, TabBar)
    local stroke = border(btn, T.border)

    local page = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false }, PageHolder)
    local function column(position)
        local col = new("ScrollingFrame", {
            Size = UDim2.new(0.5, -5, 1, 0), Position = position,
            BackgroundTransparency = 1, BorderSizePixel = 0,
            ScrollBarThickness = 3, ScrollBarImageColor3 = T.red,
            CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollingDirection = Enum.ScrollingDirection.Y,
        }, page)
        new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }, col)
        new("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6) }, col)
        return col
    end
    local left = column(UDim2.fromOffset(0, 0))
    local right = column(UDim2.new(0.5, 5, 0, 0))
    local tab = { Button = btn, Page = page, Left = left, Right = right, Stroke = stroke }
    Tabs[name] = tab

    function tab.Select()
        if currentTab then
            currentTab.Page.Visible = false
            currentTab.Button.TextColor3 = T.dim
            currentTab.Stroke.Color = T.border
        end
        currentTab = tab
        page.Visible = true
        btn.TextColor3 = T.text
        stroke.Color = T.red
    end

    btn.MouseButton1Click:Connect(tab.Select)
    return tab
end




local function makeSection(column, title)
    local box = new("Frame", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = T.inner,
        BorderSizePixel = 0,
        AutomaticSize = Enum.AutomaticSize.Y,
    }, column)
    border(box, T.border)

    local t = new("TextLabel", {
        Size = UDim2.fromOffset(#title * 8 + 6, 14),
        Position = UDim2.fromOffset(8, -7),
        BackgroundColor3 = T.inner,
        BorderSizePixel = 0,
        Text = title,
        Font = T.font,
        TextSize = 13,
        TextColor3 = T.text,
    }, box)

    local content = new("Frame", {
        Position = UDim2.fromOffset(8, 12),
        Size = UDim2.new(1, -16, 0, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
    }, box)
    new("UIListLayout", { Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder }, content)
    new("UIPadding", { PaddingBottom = UDim.new(0, 10) }, content)
    return content
end




local Elements = {}
local ConfigControls = {}
local Persistence = {}
Persistence.HUDFrames = {}
function Persistence.ControlApplies(control, gameName)
    if not control or type(control.Key) ~= "string" then return false end
    local tab, scope = control.Key:match("^([^/]+)/([^/]+)/")
    if scope == gameName then return true end
    if scope ~= "All" then return false end
    if gameName == "Rivals" or gameName == "Cold War" or gameName == "Project Delta" then
        return tab == "Sunset"
    end
    if control.Key:match("^Player/All/Third Person/") then return true end
    return not control.Box or not table.find(bedWarsHiddenSections, control.Box)
end
function Persistence.SavedHUDPositions()
    local positions = {}
    for name, frame in pairs(Persistence.HUDFrames) do
        if frame and frame.Parent then
            local p = frame.Position
            positions[name] = { p.X.Scale, p.X.Offset, p.Y.Scale, p.Y.Offset }
        end
    end
    return positions
end
function Persistence.RestoreHUDPositions(positions, legacyLayout)
    if type(positions) ~= "table" then return end
    for name, value in pairs(positions) do
        local frame = Persistence.HUDFrames[name]
        if name ~= "ModuleList"
            and not (legacyLayout and (name == "BedWarsMenu" or name == "RivalsMenu"))
            and frame and frame.Parent and type(value) == "table"
            and type(value[1]) == "number" and type(value[2]) == "number"
            and type(value[3]) == "number" and type(value[4]) == "number" then
            frame.Position = UDim2.new(value[1], value[2], value[3], value[4])
        end
    end
end
do
    local lastSavedJSON
    local function sessionPath(gameName)
        return "SunsetConfigs/SunsetAuto_"
            .. tostring(gameName):gsub("[^%w%-_]", "_") .. ".json"
    end
    function Persistence.Save()
        if Settings.RecoveryMode then return false end
        local gameName = Settings.SelectedGame
        if not gameName then return false end
        local saved = {}
        for _, control in ipairs(ConfigControls) do
            if Persistence.ControlApplies(control, gameName) then
                local value = control.Get()
                if control.Kind == "color" and typeof(value) == "Color3" then
                    value = { math.floor(value.R * 255 + 0.5),
                        math.floor(value.G * 255 + 0.5),
                        math.floor(value.B * 255 + 0.5) }
                end
                local bind = control.GetBind and control.GetBind()
                saved[#saved + 1] = { Key = control.Key, Kind = control.Kind,
                    Value = value, Bind = bind and bind.Name or nil }
            end
        end
        local data = { Version = 5, Game = gameName, Controls = saved,
            AutoReinjectVersion = 1,
            RiftThemeVersion = 1,
            MenuKey = Settings.MenuKey.Name, HUDPositions = Persistence.SavedHUDPositions() }
        if gameName == "Rivals" then
            data.RivalsAim = { Enabled = RivalsAim.Enabled,
                FOVVisible = RivalsAim.FOVVisible, Radius = RivalsAim.Radius }
        end
        -- Session counters belong to this injection, never to a saved config.
        ENV.SunsetSettingsSnapshot = data
        if type(ENV.SunsetSettingsSnapshots) ~= "table" then ENV.SunsetSettingsSnapshots = {} end
        ENV.SunsetSettingsSnapshots[gameName] = data
        if typeof(writefile) ~= "function" then return true end
        local ok, encoded = pcall(HttpService.JSONEncode, HttpService, data)
        if not ok then return false end
        if encoded == lastSavedJSON then return true end
        if typeof(makefolder) == "function" then
            pcall(makefolder, "SunsetConfigs")
        end
        local written = pcall(writefile, sessionPath(gameName), encoded)
        if written then lastSavedJSON = encoded end
        return written
    end
    function Persistence.Restore(gameName, menuKeyControl)
        if Settings.RecoveryMode then return false end
        local snapshots = ENV.SunsetSettingsSnapshots
        local data = ENV.SunsetSettingsSnapshot
        if (type(data) ~= "table" or data.Game ~= gameName) and type(snapshots) == "table" then
            data = snapshots[gameName]
        end
        if (type(data) ~= "table" or data.Game ~= gameName)
            and typeof(readfile) == "function" then
            local ok, decoded = pcall(function()
                return HttpService:JSONDecode(readfile(sessionPath(gameName)))
            end)
            if ok then data = decoded end
        end
        if type(data) ~= "table" or data.Game ~= gameName
            or type(data.Controls) ~= "table" then return false end
        if gameName == "Rivals" and type(data.RivalsAim) == "table" then
            for _, control in ipairs(ConfigControls) do
                if control.Key == "Combat/Rivals/Silent Aim/Silent Aim" then
                    control.Set(data.RivalsAim.Enabled == true)
                elseif control.Key == "Visuals/Rivals/FOV Circle/FOV Circle" then
                    control.Set(data.RivalsAim.FOVVisible == true)
                elseif control.Key == "Visuals/Rivals/FOV Circle/Radius" then
                    control.Set(math.clamp(tonumber(data.RivalsAim.Radius) or 150, 50, 1500))
                end
            end
        end
        -- Ignore Session in older snapshots too: reinjection starts at zero.
        local byKey = {}
        for _, control in ipairs(ConfigControls) do
            if control.Key then byKey[control.Key] = control end
        end
        local pendingToggles = {}
        for _, item in ipairs(data.Controls) do
            local key = item.Key and item.Key:gsub("Visuals/Rivals/Enemy Outlines/", "Visuals/Rivals/Player Outlines/")
            if gameName == "BedWars" and key then
                key = key:gsub("^Visuals/All/ESP Boxes/", "Visuals/BedWars/ESP Boxes/")
                if key == "Visuals/BedWars/ESP Boxes/ESP" then key = "Visuals/BedWars/ESP Boxes/ESP Boxes" end
            end
            if key == "Visuals/Rivals/Player Outlines/Enemy Outlines" then key = "Visuals/Rivals/Player Outlines/Player Outlines" end
            local control = key and byKey[key]
            if gameName == "BedWars" and item.Kind == "number"
                and item.Key == "Movement/BedWars/Speed/Speed" then
                control = byKey["Movement/BedWars/Speed/Move Speed"]
            end
            if gameName == "Rivals" and item.Kind == "number"
                and item.Key == "Combat/Rivals/Silent Aim/FOV Radius" then
                control = byKey["Visuals/Rivals/FOV Circle/Radius"]
            end
            if control and control.Kind == item.Kind
                and Persistence.ControlApplies(control, gameName) then
                local value = item.Value
                if gameName == "Rivals"
                    and control.Key == "Sunset/All/Arena Travel/Auto Reinject"
                    and data.AutoReinjectVersion ~= 1 then
                    value = true
                end
                if control.Key == "Fun/BedWars/Auto Reply/Message"
                    and value == "Sunset.wtf <3" then value = "Rift <3" end
                if control.Key == "Sunset/All/Colors/Preset"
                    and data.RiftThemeVersion ~= 1 then value = "Rift" end
                if control.Key == "Sunset/All/Colors/Accent Color"
                    and data.RiftThemeVersion ~= 1 then
                    value = { 139, 92, 246 }
                end
                if control.Kind == "color" and type(value) == "table" then
                    value = Color3.fromRGB(tonumber(value[1]) or 255,
                        tonumber(value[2]) or 255, tonumber(value[3]) or 255)
                end
                if control.Kind == "toggle" then
                    pendingToggles[#pendingToggles + 1] = { Control = control, Value = value }
                else
                    control.Set(value)
                end
                if control.SetBind then
                    control.SetBind(item.Bind and Enum.KeyCode[item.Bind] or nil)
                end
            end
        end
        -- Apply saved parameters and bindings before starting the modules that use them.
        for _, pending in ipairs(pendingToggles) do pending.Control.Set(pending.Value) end
        if data.MenuKey and Enum.KeyCode[data.MenuKey] and menuKeyControl then
            menuKeyControl.SetBind(Enum.KeyCode[data.MenuKey])
        end
        Persistence.RestoreHUDPositions(data.HUDPositions, (data.Version or 1) < 4)
        return true
    end
    function Persistence.Start()
        if Settings.RecoveryMode then return end
        task.spawn(function()
            while Gui.Parent do
                Persistence.Save()
                task.wait(1)
            end
        end)
    end
end
local function configKey(parent, text)
    local section = parent and parent.Parent
    local title = section and section:FindFirstChildOfClass("TextLabel")
    local page = section and section.Parent and section.Parent.Parent
    local tabName = "Menu"
    for name, tab in pairs(Tabs) do
        if tab.Page == page then tabName = name break end
    end
    return tabName .. "/" .. (section and section:GetAttribute("SunsetGame") or "All")
        .. "/" .. (title and title.Text or "Section") .. "/" .. text
end

function Elements.Label(parent, text, rightText)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1 }, parent)
    local l = label(row, text)
    row.AutomaticSize = Enum.AutomaticSize.Y
    l.TextWrapped = true
    l.AutomaticSize = Enum.AutomaticSize.Y
    l.Size = UDim2.new(1, 0, 0, 16)
    if rightText then
        label(row, rightText, 13, T.text, Enum.TextXAlignment.Right).Size = UDim2.new(1, 0, 1, 0)
    end
    return l
end

function Elements.Line(parent)
    new("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = T.border, BorderSizePixel = 0 }, parent)
end

function Elements.Button(parent, text, callback)
    local b = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 18),
        BackgroundColor3 = T.element,
        BorderSizePixel = 0,
        Text = text,
        Font = T.font,
        TextSize = 13,
        TextColor3 = T.text,
        AutoButtonColor = false,
    }, parent)
    border(b, T.border)
    b.MouseEnter:Connect(function() b.BackgroundColor3 = T.elementHi end)
    b.MouseLeave:Connect(function() b.BackgroundColor3 = T.element end)
    b.MouseButton1Click:Connect(function() if callback then task.spawn(Settings.RunCallback, callback) end end)
    return b
end



local Binds = {}


local function keyName(key)
    if not key then return "-" end
    local symbols = {
        LeftBracket = "[", RightBracket = "]", Semicolon = ";",
        Quote = "'", Comma = ",", Period = ".", Slash = "/",
        BackSlash = "\\", Equals = "=", Minus = "-", Backquote = "`",
    }
    return symbols[key.Name] or ("[" .. key.Name:upper() .. "]")
end

function Elements.Toggle(parent, text, default, callback, defaultKey)
    local row = new("TextButton", { Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = "", AutoButtonColor = false }, parent)
    local box = new("Frame", { Size = UDim2.fromOffset(11, 11), Position = UDim2.fromOffset(0, 2), BackgroundColor3 = T.element, BorderSizePixel = 0 }, row)
    border(box, T.border)
    local l = label(row, text)
    l.Position = UDim2.fromOffset(18, 0)
    l.Size = UDim2.new(1, -60, 1, 0)

    local bindBtn = new("TextButton", {
        Size = UDim2.fromOffset(40, 14), Position = UDim2.new(1, -40, 0, 1),
        BackgroundColor3 = T.element, BorderSizePixel = 0,
        Text = keyName(defaultKey), Font = T.font, TextSize = 11, TextColor3 = T.dim,
        AutoButtonColor = false,
    }, row)
    border(bindBtn, T.border)
    new("UICorner", { CornerRadius = UDim.new(0, 6) }, bindBtn)
    bindBtn.Visible = true

    local obj = { _row = row }
    local state = default or false

    local function render()
        box.BackgroundColor3 = state and T.red or T.element
    end

    function obj.Set(v)
        if state == v then return end
        state = v
        render()
        if callback then task.spawn(Settings.RunCallback, callback, state) end
        if Settings.Notify then
            Settings.Notify(state and "Feature enabled" or "Feature disabled", text)
        end
    end
    function obj.Get() return state end
    function obj.GetBind() return Binds[obj] end
    function obj.SetBind(key)
        if key == Settings.MenuKey then return false end
        if key then
            for other, assigned in pairs(Binds) do
                if other ~= obj and assigned == key then other.SetBind(nil) end
            end
        end
        Binds[obj] = key
        bindBtn.Text = keyName(key)
        bindBtn.TextColor3 = key and T.text or T.dim
    end

    row.MouseButton1Click:Connect(function() obj.Set(not state) end)
    bindBtn.MouseButton1Click:Connect(function()
        if listeningFor then listeningFor.SetBind(listeningFor.GetBind()) end
        listeningFor = obj
        bindBtn.Text = "..."
        bindBtn.TextColor3 = T.red
    end)
    obj._bindBtn = bindBtn

    render()
    obj.SetBind(defaultKey)
    if callback and state then task.spawn(Settings.RunCallback, callback, state) end
    table.insert(ConfigControls, { Kind = "toggle", Key = configKey(parent, text),
        Get = obj.Get, Set = obj.Set,
        GetBind = obj.GetBind, SetBind = obj.SetBind,
        Box = parent.Parent, Row = row })
    return obj
end


track(UIS.InputBegan:Connect(function(i, gp)
    if i.UserInputType ~= Enum.UserInputType.Keyboard then return end
    if UIS:GetFocusedTextBox() then return end

    if listeningFor then
        local t = listeningFor
        listeningFor = nil
        if i.KeyCode == Enum.KeyCode.Escape
            or i.KeyCode == Enum.KeyCode.Backspace then
            t.SetBind(nil)
        elseif i.KeyCode ~= Enum.KeyCode.Unknown then
            local accepted = t.SetBind(i.KeyCode)
            if accepted == false then t.SetBind(t.GetBind()) end
        end
        return
    end

    if gp or i.KeyCode == Settings.MenuKey then return end
    for toggle, key in pairs(Binds) do
        if key == i.KeyCode then
            toggle.Set(not toggle.Get())
        end
    end
end))



function Elements.ColorPicker(parent, text, default, callback)
    local color = default or Color3.new(1, 1, 1)
    local hue, saturation, value = color:ToHSV()
    local holder = new("Frame", {
        Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1,
        ClipsDescendants = false,
    }, parent)
    local top = label(holder, text)
    top.Size = UDim2.new(1, -32, 0, 16)
    local swatch = new("TextButton", {
        Size = UDim2.fromOffset(26, 16), Position = UDim2.new(1, -26, 0, 0),
        BackgroundColor3 = color, BorderSizePixel = 0, Text = "",
        AutoButtonColor = false,
    }, holder)
    swatch:SetAttribute("UIThemeIgnore", true)
    border(swatch, T.border)
    local wheel = new("Frame", {
        Size = UDim2.fromOffset(160, 208), Position = UDim2.new(0.5, -80, 0, 22),
        BackgroundColor3 = T.panel, BorderSizePixel = 0, Visible = false,
    }, holder)
    border(wheel, T.border)
    new("UICorner", { CornerRadius = UDim.new(0, 7) }, wheel)
    local disc = new("Frame", {
        Position = UDim2.fromOffset(4, 4), Size = UDim2.fromOffset(152, 152),
        BackgroundTransparency = 1, BorderSizePixel = 0,
    }, wheel)
    local cells = {}
    local selected = new("Frame", {
        Size = UDim2.fromOffset(10, 10), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 4,
    }, disc)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, selected)
    border(selected, Color3.new(0, 0, 0), 2)
    local brightness = new("TextButton", {
        Position = UDim2.fromOffset(8, 177), Size = UDim2.fromOffset(144, 16),
        BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0,
        Text = "", AutoButtonColor = false,
    }, wheel)
    border(brightness, T.border)
    local brightnessMarker = new("Frame", {
        Size = UDim2.fromOffset(3, 20), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = T.text,
        BorderSizePixel = 0,
    }, brightness)
    local brightnessLabel = label(wheel, "BRIGHTNESS", 10, T.dim)
    brightnessLabel.Position = UDim2.fromOffset(8, 159)
    brightnessLabel.Size = UDim2.fromOffset(144, 14)
    local function repaint(notify)
        color = Color3.fromHSV(hue, saturation, value)
        swatch.BackgroundColor3 = color
        local angle = hue * math.pi * 2 - math.pi / 2
        selected.Position = UDim2.fromOffset(76 + math.cos(angle) * saturation * 72,
            76 + math.sin(angle) * saturation * 72)
        brightness.BackgroundColor3 = color
        brightnessMarker.Position = UDim2.new(1 - value, 0, 0.5, 0)
        if notify ~= false and callback then task.spawn(Settings.RunCallback, callback, color) end
    end
    for row = 0, 18 do
        for column = 0, 18 do
            local dx, dy = column - 9, row - 9
            local radius = math.sqrt(dx * dx + dy * dy) / 9
            if radius <= 1 then
                local h = (math.atan2(dy, dx) / (math.pi * 2) + 0.25) % 1
                local s = math.clamp(radius, 0, 1)
                local cell = new("TextButton", {
                    Size = UDim2.fromOffset(8, 8),
                    Position = UDim2.fromOffset(column * 8, row * 8),
                    BackgroundColor3 = Color3.fromHSV(h, s, 1),
                    BorderSizePixel = 0, Text = "", AutoButtonColor = false,
                }, disc)
                cell:SetAttribute("UIThemeIgnore", true)
                table.insert(cells, cell)
                cell.MouseButton1Down:Connect(function()
                    hue, saturation = h, s
                    repaint()
                end)
            end
        end
    end
    local draggingBrightness = false
    local function setBrightness()
        if brightness.AbsoluteSize.X <= 0 then return end
        value = 1 - math.clamp((UIS:GetMouseLocation().X - brightness.AbsolutePosition.X)
            / brightness.AbsoluteSize.X, 0, 1)
        repaint()
    end
    brightness.MouseButton1Down:Connect(function()
        draggingBrightness = true
        setBrightness()
    end)
    track(UIS.InputChanged:Connect(function(input)
        if draggingBrightness and input.UserInputType == Enum.UserInputType.MouseMovement then
            setBrightness()
        end
    end))
    track(UIS.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then draggingBrightness = false end
    end))
    swatch.MouseButton1Click:Connect(function()
        wheel.Visible = not wheel.Visible
        holder.Size = UDim2.new(1, 0, 0, wheel.Visible and 238 or 18)
    end)
    local picker = {}
    function picker.Get() return color end
    function picker.Set(nextColor)
        if typeof(nextColor) ~= "Color3" then return end
        hue, saturation, value = nextColor:ToHSV()
        repaint()
    end
    repaint(false)
    table.insert(ConfigControls, { Kind = "color", Key = configKey(parent, text),
        Get = picker.Get, Set = picker.Set,
        Box = parent.Parent })
    return picker
end

local function sliderNumber(raw, low, high, previous, step)
    local number = tonumber(raw)
    if not number or number ~= number or number == math.huge or number == -math.huge then return previous end
    step = step or 1
    local rounded = low + math.floor((number - low) / step + 0.5) * step
    return math.clamp(tonumber(string.format("%.4f", rounded)), low, high)
end
function Elements.Slider(parent, text, min, max, default, suffix, callback, step, unlimitedInput)
    local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1 }, parent)
    local value = sliderNumber(default or min, min, max, min, step)
    local top = new("Frame", { Size = UDim2.new(1, 0, 0, 22), BackgroundTransparency = 1 }, holder)
    local title = label(top, text .. ((suffix and suffix ~= "") and (" (" .. suffix:match("^%s*(.-)%s*$") .. ")") or ""), 12)
    title.Size = UDim2.new(1, -98, 1, 0)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    local number = new("TextBox", {
        Size = UDim2.fromOffset(66, 20), Position = UDim2.new(1, -96, 0, 0),
        BackgroundColor3 = T.element, BorderSizePixel = 0, Font = T.font,
        TextSize = 13, TextColor3 = T.text, ClearTextOnFocus = false,
        Text = tostring(value), PlaceholderText = tostring(min) .. "-" .. tostring(max),
    }, top)
    border(number, T.border)
    local plus = new("TextButton", { Size = UDim2.fromOffset(12, 20), Position = UDim2.new(1, -26, 0, 0), BackgroundTransparency = 1, Text = "+", Font = T.font, TextSize = 13, TextColor3 = T.text }, top)
    local minus = new("TextButton", { Size = UDim2.fromOffset(12, 20), Position = UDim2.new(1, -12, 0, 0), BackgroundTransparency = 1, Text = "-", Font = T.font, TextSize = 13, TextColor3 = T.text }, top)
    local hitArea = new("TextButton", {
        Name = "SliderDragArea", Size = UDim2.new(1, 0, 0, 30),
        Position = UDim2.fromOffset(0, 22), BackgroundTransparency = 1,
        BorderSizePixel = 0, Text = "", AutoButtonColor = false,
    }, holder)
    local bar = new("Frame", {
        Size = UDim2.new(1, -16, 0, 8), Position = UDim2.fromOffset(8, 11),
        BackgroundColor3 = T.element, BorderSizePixel = 0,
    }, hitArea)
    border(bar, T.border)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, bar)
    local fill = new("Frame", { Size = UDim2.fromScale(0, 1), BackgroundColor3 = T.red, BorderSizePixel = 0 }, bar)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, fill)
    local knob = new("Frame", {
        Size = UDim2.fromOffset(18, 18), AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = T.red,
        BorderSizePixel = 0, ZIndex = bar.ZIndex + 2,
    }, bar)
    new("UICorner", { CornerRadius = UDim.new(1, 0) }, knob)
    local function set(raw, initial)
        local updated = sliderNumber(raw, min, unlimitedInput and math.huge or max, value, step)
        local changed = updated ~= value
        value = updated
        number.Text = tostring(value)
        local fraction = max > min and math.clamp((value - min) / (max - min), 0, 1) or 0
        fill.Size = UDim2.fromScale(fraction, 1)
        knob.Position = UDim2.fromScale(fraction, 0.5)
        if callback and (changed or initial) then task.spawn(Settings.RunCallback, callback, value) end
    end
    number.FocusLost:Connect(function() set(number.Text) end)
    local dragInput, grabOffset, scrollParents = nil, 0, {}
    local function stopDrag()
        dragInput = nil
        for scroll, enabled in pairs(scrollParents) do scroll.ScrollingEnabled = enabled end
        table.clear(scrollParents)
    end
    local function fromPointer(x)
        if bar.AbsoluteSize.X <= 0 then return end
        local ratio = (x - grabOffset - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
        set(min + math.clamp(ratio, 0, 1) * (max - min))
    end
    hitArea.InputBegan:Connect(function(input)
        if dragInput or (input.UserInputType ~= Enum.UserInputType.MouseButton1
            and input.UserInputType ~= Enum.UserInputType.Touch) then return end
        if bar.AbsoluteSize.X <= 0 then return end
        dragInput = input
        local fraction = max > min and math.clamp((value - min) / (max - min), 0, 1) or 0
        local offset = input.Position.X - (bar.AbsolutePosition.X + fraction * bar.AbsoluteSize.X)
        -- Keep the value steady when grabbing the handle; clicks elsewhere jump to that spot.
        grabOffset = math.abs(offset) <= 12 and offset or 0
        local ancestor = holder.Parent
        while ancestor and ancestor ~= Gui do
            if ancestor:IsA("ScrollingFrame") then
                scrollParents[ancestor] = ancestor.ScrollingEnabled
                ancestor.ScrollingEnabled = false
            end
            ancestor = ancestor.Parent
        end
        fromPointer(input.Position.X)
    end)
    track(UIS.InputChanged:Connect(function(input)
        if dragInput and (input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseMovement)) then
            fromPointer(input.Position.X)
        end
    end))
    track(UIS.InputEnded:Connect(function(input)
        if dragInput and (input == dragInput or (dragInput.UserInputType == Enum.UserInputType.MouseButton1
            and input.UserInputType == Enum.UserInputType.MouseButton1)) then stopDrag() end
    end))
    track(UIS.WindowFocusReleased:Connect(stopDrag))
    plus.MouseButton1Click:Connect(function() set(value + (step or 1)) end)
    minus.MouseButton1Click:Connect(function() set(value - (step or 1)) end)
    set(value, true)
    table.insert(ConfigControls, { Kind = "number", Key = configKey(parent, text),
        Get = function() return value end,
        Set = function(nextValue) set(nextValue) end, Box = parent.Parent })
    return holder
end
function Elements.Dropdown(parent, text, options, default, callback, noConfig)
    local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, ZIndex = 5 }, parent)
    label(holder, text)
    local btn = new("TextButton", {
        Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 18),
        BackgroundColor3 = T.element, BorderSizePixel = 0,
        Text = "  " .. (default or options[1]), Font = T.font, TextSize = 13, TextColor3 = T.text,
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 5,
    }, holder)
    border(btn, T.border)
    label(btn, "+ ", 13, T.text, Enum.TextXAlignment.Right).Size = UDim2.new(1, 0, 1, 0)

    local list = new("ScrollingFrame", {
        ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
        Size = UDim2.new(1, 0, 0, math.min(#options, 7) * 18), Position = UDim2.fromOffset(0, 36),
        BackgroundColor3 = T.element, BorderSizePixel = 0, Visible = false, ZIndex = 10,
    }, holder)
    border(list, T.border)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)

    local obj = { Value = default or options[1] }
    local currentOptions = options

    function obj.Set(value)
        if not table.find(currentOptions, value) then return end
        obj.Value = value
        btn.Text = "  " .. value
        list.Visible = false
        holder.Size = UDim2.new(1, 0, 0, 36)
        if callback then task.spawn(Settings.RunCallback, callback, value) end
    end

    function obj.SetOptions(newOptions)
        currentOptions = newOptions
        for _, c in ipairs(list:GetChildren()) do
            if c:IsA("TextButton") then c:Destroy() end
        end
        list.Size = UDim2.new(1, 0, 0, math.min(math.max(#newOptions, 1), 7) * 18)
        holder.Size = UDim2.new(1, 0, 0, list.Visible and 40 + list.Size.Y.Offset or 36)
        for _, opt in ipairs(newOptions) do
            local o = new("TextButton", {
                Size = UDim2.new(1, 0, 0, 18), BackgroundColor3 = T.element, BorderSizePixel = 0,
                Text = "  " .. opt, Font = T.font, TextSize = 13, TextColor3 = T.text,
                TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false, ZIndex = 10,
            }, list)
            o.MouseEnter:Connect(function() o.BackgroundColor3 = T.elementHi end)
            o.MouseLeave:Connect(function() o.BackgroundColor3 = T.element end)
            o.MouseButton1Click:Connect(function()
                obj.Value = opt
                btn.Text = "  " .. opt
                list.Visible = false
                holder.Size = UDim2.new(1, 0, 0, 36)
                if callback then task.spawn(Settings.RunCallback, callback, opt) end
            end)
        end

        if not table.find(newOptions, obj.Value) then
            obj.Value = newOptions[1] or "none"
            btn.Text = "  " .. obj.Value
        end
    end

    obj.SetOptions(options)
    btn.MouseButton1Click:Connect(function() list.Visible = not list.Visible holder.Size = UDim2.new(1, 0, 0, list.Visible and 40 + list.Size.Y.Offset or 36) end)
    if not noConfig then
        table.insert(ConfigControls, { Kind = "choice", Key = configKey(parent, text),
            Get = function() return obj.Value end,
            Set = obj.Set, Box = parent.Parent })
    end
    return obj
end

function Elements.MultiSelect(parent, text, options, callback)
    local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, parent)
    label(holder, text)
    local button = new("TextButton", {
        Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 18),
        BackgroundColor3 = T.element, BorderSizePixel = 0, Text = "  Select gear +",
        TextColor3 = T.text, Font = T.font, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, AutoButtonColor = false,
    }, holder)
    border(button, T.border)
    local list = new("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 36), Size = UDim2.new(1, 0, 0, math.min(#options, 6) * 20),
        BackgroundColor3 = T.element, BorderSizePixel = 0, Visible = false,
        ScrollBarThickness = 3, CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y,
    }, holder)
    border(list, T.border)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, list)
    local selected = {}
    local function update()
        local names = {}
        for _, option in ipairs(options) do
            if selected[option] then table.insert(names, option) end
        end
        button.Text = #names == 0 and "  Select gear +" or ("  " .. table.concat(names, ", "))
        if callback then callback(names) end
    end
    for _, option in ipairs(options) do
        local row = new("TextButton", {
            Size = UDim2.new(1, 0, 0, 20), BackgroundColor3 = T.element,
            BorderSizePixel = 0, TextColor3 = T.text, Font = T.font,
            TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left,
            AutoButtonColor = false,
        }, list)
        local function render() row.Text = (selected[option] and "  [x] " or "  [ ] ") .. option end
        render()
        row.MouseButton1Click:Connect(function()
            selected[option] = not selected[option]
            render()
            update()
        end)
    end
    button.MouseButton1Click:Connect(function()
        list.Visible = not list.Visible
        holder.Size = UDim2.new(1, 0, 0, list.Visible and 36 + list.Size.Y.Offset or 36)
    end)
    return holder
end

function Elements.TextBox(parent, text, placeholder, callback, default, saveValue)
    local holder = new("Frame", { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 }, parent)
    label(holder, text)
    local box = new("TextBox", {
        Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 18),
        BackgroundColor3 = T.element, BorderSizePixel = 0,
        Text = default or "", PlaceholderText = placeholder or "", PlaceholderColor3 = T.dim,
        Font = T.font, TextSize = 13, TextColor3 = T.text, ClearTextOnFocus = false,
    }, holder)
    border(box, T.border)
    new("UIPadding", { PaddingLeft = UDim.new(0, 4) }, box)
    box.FocusLost:Connect(function() if callback then task.spawn(Settings.RunCallback, callback, box.Text) end end)
    if saveValue then
        table.insert(ConfigControls, { Kind = "text", Key = configKey(parent, text),
            Get = function() return box.Text end,
            Set = function(value)
                if type(value) ~= "string" then return end
                box.Text = value
                if callback then task.spawn(Settings.RunCallback, callback, value) end
            end, Box = parent.Parent })
    end
    return holder
end

function Elements.Keybind(parent, text)
    local row = new("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1 }, parent)
    local title = label(row, text)
    title.Size = UDim2.new(1, -106, 1, 0)
    local button = new("TextButton", {
        Size = UDim2.fromOffset(102, 22), Position = UDim2.new(1, -102, 0, 0),
        BackgroundColor3 = T.element, BorderSizePixel = 0, Font = T.font,
        TextSize = 12, TextColor3 = T.text, Text = keyName(Settings.MenuKey),
    }, row)
    border(button, T.border)
    new("UICorner", { CornerRadius = UDim.new(0, 7) }, button)
    local object = {}
    function object.GetBind() return Settings.MenuKey end
    function object.SetBind(key)
        key = key or Enum.KeyCode.RightShift
        for toggle, assigned in pairs(Binds) do
            if assigned == key then toggle.SetBind(nil) end
        end
        Settings.MenuKey = key
        button.Text = keyName(key)
        button.TextColor3 = T.text
        return true
    end
    button.MouseButton1Click:Connect(function()
        if listeningFor then listeningFor.SetBind(listeningFor.GetBind()) end
        listeningFor = object
        button.Text = "[PRESS KEY]"
        button.TextColor3 = T.red
    end)
    return object
end





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
]========]
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
