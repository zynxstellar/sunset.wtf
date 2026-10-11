local SUNSET_BUILD = "20261011-rift-blox-movement-k376"
if game.PlaceId ~= 2753915549 and game.GameId ~= 994732206 then return end
if not game:IsLoaded() then game.Loaded:Wait() end
local ENV = (typeof(getgenv) == "function" and getgenv()) or _G
if type(ENV.SunsetUnload) == "function" then pcall(ENV.SunsetUnload) end
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer
local connections = {}
local closed = false
local function track(connection) table.insert(connections, connection) return connection end

local function makeMovement(deps)
    local options = {FlyEnabled=false, SpeedEnabled=false, FlySpeed=50, WalkSpeed=32}
    local character, humanoid, root, originalSpeed, appliedSpeed
    local flight, standing, rotating
    local function stopFlight()
        if flight then
            flight:Destroy()
            flight = nil
            if root and root.Parent then root.AssemblyLinearVelocity = deps.Zero end
            if humanoid and humanoid.Parent then humanoid.PlatformStand, humanoid.AutoRotate = standing, rotating end
        end
    end
    local function stopSpeed()
        if appliedSpeed and humanoid and humanoid.Parent and humanoid.WalkSpeed == appliedSpeed then
            humanoid.WalkSpeed = originalSpeed
        end
        originalSpeed, appliedSpeed = nil, nil
    end
    function options.Clear()
        stopFlight(); stopSpeed()
        character, humanoid, root = nil, nil, nil
    end
    function options.Step()
        local nextCharacter, nextHumanoid, nextRoot = deps.Character()
        if nextCharacter ~= character or nextHumanoid ~= humanoid or nextRoot ~= root then
            options.Clear()
            character, humanoid, root = nextCharacter, nextHumanoid, nextRoot
        end
        if not humanoid or not root or not root.Parent or humanoid.Health <= 0 then options.Clear(); return end
        if options.SpeedEnabled then
            if not appliedSpeed or humanoid.WalkSpeed ~= appliedSpeed then originalSpeed = humanoid.WalkSpeed end
            local value = tonumber(options.WalkSpeed) or 32
            if value ~= value then value = 32 end
            appliedSpeed = math.clamp(value, 1, 200)
            humanoid.WalkSpeed = appliedSpeed
        else stopSpeed() end
        if not options.FlyEnabled or root.Anchored or humanoid.SeatPart then stopFlight(); return end
        if not flight then
            standing, rotating = humanoid.PlatformStand, humanoid.AutoRotate
            flight = deps.CreateFlight(root)
            humanoid.PlatformStand, humanoid.AutoRotate = true, false
        end
        local value = tonumber(options.FlySpeed) or 50
        if value ~= value then value = 50 end
        local direction = deps.Paused() and deps.Zero or deps.Direction()
        local command = direction.Magnitude > 0.001 and direction.Unit * math.clamp(value, 1, 300) or deps.Zero
        flight:SetVelocity(command)
        root.AssemblyLinearVelocity = command
    end
    function options.SetFly(on)
        options.FlyEnabled = on == true
        if not options.FlyEnabled then stopFlight() end
    end
    function options.SetSpeed(on)
        options.SpeedEnabled = on == true
        if not options.SpeedEnabled then stopSpeed() end
    end
    function options.Close()
        options.FlyEnabled, options.SpeedEnabled = false, false
        options.Clear()
    end
    return options
end

local function new(kind, props, parent)
    local object = Instance.new(kind)
    for key, value in pairs(props) do object[key] = value end
    object.Parent = parent
    return object
end
local blue, textColor = Color3.fromRGB(0,140,255), Color3.fromRGB(235,242,255)
local gui = new("ScreenGui", {Name="RiftBloxMovement",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling}, player:WaitForChild("PlayerGui"))
local panel = new("Frame", {Name="Movement",Size=UDim2.fromOffset(320,244),Position=UDim2.new(0.5,-160,0.5,-122),
    BackgroundColor3=Color3.fromRGB(15,24,39),BorderSizePixel=0,Active=true}, gui)
new("UICorner", {CornerRadius=UDim.new(0,7)}, panel)
new("UIStroke", {Color=Color3.fromRGB(42,63,89)}, panel)
new("TextLabel", {Size=UDim2.new(1,0,0,38),BackgroundColor3=blue,BorderSizePixel=0,
    Text="RIFT | BLOX FRUITS",Font=Enum.Font.GothamBold,TextSize=15,TextColor3=textColor}, panel)
new("TextLabel", {Position=UDim2.fromOffset(12,220),Size=UDim2.new(1,-24,0,18),BackgroundTransparency=1,
    Text="RightShift: menu   Space / Ctrl: up / down",Font=Enum.Font.Gotham,TextSize=11,TextColor3=Color3.fromRGB(150,169,195)}, panel)

local movement = makeMovement({
    Zero=Vector3.zero,
    Character=function()
        local character = player.Character
        return character, character and character:FindFirstChildOfClass("Humanoid"), character and character:FindFirstChild("HumanoidRootPart")
    end,
    Paused=function() return panel.Visible or UIS:GetFocusedTextBox() ~= nil or game:GetService("GuiService").MenuIsOpen end,
    Direction=function()
        local camera = workspace.CurrentCamera
        if not camera then return Vector3.zero end
        local direction = Vector3.zero
        local frame = camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction += frame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction -= frame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction += frame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction -= frame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction += Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) then direction -= Vector3.yAxis end
        return direction
    end,
    CreateFlight=function(root)
        local attachment = new("Attachment", {Name="RiftFlightAttachment"}, root)
        local velocity = new("LinearVelocity", {Name="RiftFlightVelocity",Attachment0=attachment,
            RelativeTo=Enum.ActuatorRelativeTo.World,VelocityConstraintMode=Enum.VelocityConstraintMode.Vector,
            ForceLimitsEnabled=false,VectorVelocity=Vector3.zero}, root)
        return {
            SetVelocity=function(_, command) velocity.VectorVelocity=command end,
            Destroy=function() velocity:Destroy();attachment:Destroy() end,
        }
    end,
})

local drag, draggingPanel
local function makeRow(name, y, initial, maximum, setEnabled, setValue)
    local row = new("Frame", {Name=name,Position=UDim2.fromOffset(10,y),Size=UDim2.new(1,-20,0,78),
        BackgroundColor3=Color3.fromRGB(21,33,51),BorderSizePixel=0}, panel)
    local enabled = false
    local toggle = new("TextButton", {Position=UDim2.fromOffset(9,10),Size=UDim2.fromOffset(20,20),
        Text="",BackgroundColor3=Color3.fromRGB(30,46,65),BorderSizePixel=0,AutoButtonColor=false}, row)
    local title = new("TextButton", {Position=UDim2.fromOffset(38,4),Size=UDim2.new(1,-46,0,32),
        BackgroundTransparency=1,Text=name,TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.GothamMedium,
        TextSize=14,TextColor3=textColor,AutoButtonColor=false}, row)
    local function toggleOn()
        enabled = not enabled
        toggle.BackgroundColor3 = enabled and blue or Color3.fromRGB(30,46,65)
        setEnabled(enabled)
    end
    track(toggle.Activated:Connect(toggleOn));track(title.Activated:Connect(toggleOn))
    new("TextLabel", {Position=UDim2.fromOffset(9,38),Size=UDim2.fromOffset(115,20),BackgroundTransparency=1,
        Text=(name=="Fly" and "Fly Speed" or "Walk Speed").." (studs/s)",TextXAlignment=Enum.TextXAlignment.Left,Font=Enum.Font.Gotham,TextSize=11,TextColor3=textColor}, row)
    local number = new("TextBox", {Position=UDim2.new(1,-66,0,37),Size=UDim2.fromOffset(56,22),
        BackgroundColor3=Color3.fromRGB(15,24,39),BorderSizePixel=0,TextColor3=textColor,Font=Enum.Font.Gotham,
        TextSize=13,ClearTextOnFocus=false,Text=tostring(initial)}, row)
    local bar = new("TextButton", {Position=UDim2.fromOffset(9,62),Size=UDim2.new(1,-18,0,10),Text="",
        BackgroundColor3=Color3.fromRGB(38,54,74),BorderSizePixel=0,AutoButtonColor=false}, row)
    local fill = new("Frame", {BackgroundColor3=blue,BorderSizePixel=0,Size=UDim2.fromScale((initial-1)/(maximum-1),1)}, bar)
    local current = initial
    local function set(value)
        value = tonumber(value)
        if not value or value ~= value or math.abs(value)==math.huge then value=current end
        current=math.clamp(math.floor(value+0.5),1,maximum)
        number.Text=tostring(current)
        fill.Size=UDim2.fromScale((current-1)/(maximum-1),1)
        setValue(current)
    end
    track(number.FocusLost:Connect(function() set(number.Text) end))
    local function pointer(x)
        if bar.AbsoluteSize.X>0 then set(1+math.clamp((x-bar.AbsolutePosition.X)/bar.AbsoluteSize.X,0,1)*(maximum-1)) end
    end
    track(bar.InputBegan:Connect(function(input)
        if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
            draggingPanel=nil
            drag={Input=input,Move=pointer}
            pointer(input.Position.X)
        end
    end))
end
makeRow("Fly",48,50,300,function(on) movement.SetFly(on) end,function(value) movement.FlySpeed=value end)
makeRow("Speed",134,32,200,function(on) movement.SetSpeed(on) end,function(value) movement.WalkSpeed=value end)
track(panel.InputBegan:Connect(function(input)
    if input.UserInputType~=Enum.UserInputType.MouseButton1 and input.UserInputType~=Enum.UserInputType.Touch then return end
    local pointer=Vector2.new(input.Position.X,input.Position.Y)
    for _,object in ipairs(gui:GetDescendants()) do
        if object:IsA("GuiButton") or object:IsA("TextBox") then
            local position,size=object.AbsolutePosition,object.AbsoluteSize
            if pointer.X>=position.X and pointer.X<=position.X+size.X and pointer.Y>=position.Y and pointer.Y<=position.Y+size.Y then return end
        end
    end
    draggingPanel={Input=input,Pointer=pointer,Position=panel.AbsolutePosition}
end))
track(UIS.InputChanged:Connect(function(input)
    if drag and (input==drag.Input or input.UserInputType==Enum.UserInputType.MouseMovement) then drag.Move(input.Position.X) end
    if draggingPanel and (input==draggingPanel.Input or input.UserInputType==Enum.UserInputType.MouseMovement) then
        local delta=Vector2.new(input.Position.X,input.Position.Y)-draggingPanel.Pointer
        local camera=workspace.CurrentCamera
        local viewport=camera and camera.ViewportSize or Vector2.new(1920,1080)
        local point=draggingPanel.Position+delta
        panel.Position=UDim2.fromOffset(math.clamp(point.X,0,math.max(0,viewport.X-panel.AbsoluteSize.X)),
            math.clamp(point.Y,0,math.max(0,viewport.Y-panel.AbsoluteSize.Y)))
    end
end))
track(UIS.InputEnded:Connect(function(input)
    if drag and input==drag.Input then drag=nil end
    if draggingPanel and input==draggingPanel.Input then draggingPanel=nil end
end))
track(UIS.InputBegan:Connect(function(input, processed)
    if not processed and not UIS:GetFocusedTextBox() and input.KeyCode==Enum.KeyCode.RightShift then
        panel.Visible=not panel.Visible
        drag,draggingPanel=nil,nil
    end
end))
local function unload()
    if closed then return end
    closed=true
    movement.Close()
    for _,connection in ipairs(connections) do connection:Disconnect() end
    table.clear(connections)
    gui:Destroy()
    if ENV.SunsetUnload==unload then ENV.SunsetUnload=nil end
end
ENV.SunsetUnload=unload
track(RunService.PreSimulation:Connect(function()
    local ok,err=pcall(movement.Step)
    if not ok then unload();warn("[RIFT] Blox Fruits movement stopped: "..tostring(err)) end
end))
print("[RIFT] "..SUNSET_BUILD.." ready. RightShift toggles the menu.")
