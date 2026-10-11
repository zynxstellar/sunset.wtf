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
            if not options.FlyEnabled and not root.Anchored and not humanoid.SeatPart and not deps.Paused() then
                deps.MoveSpeed(root, humanoid, appliedSpeed)
            end
        else stopSpeed() end
        if not options.FlyEnabled or root.Anchored or humanoid.SeatPart then stopFlight(); return end
        if not flight then
            standing, rotating = humanoid.PlatformStand, humanoid.AutoRotate
            flight = deps.CreateFlight(root)
            humanoid.PlatformStand, humanoid.AutoRotate = true, false
        end
        humanoid.PlatformStand, humanoid.AutoRotate = true, false
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
    function options.AfterPhysics()
        if humanoid and root and root.Parent and humanoid.Health>0 and options.SpeedEnabled
            and not options.FlyEnabled and not root.Anchored and not humanoid.SeatPart and not deps.Paused() then
            deps.MoveSpeed(root,humanoid,appliedSpeed or math.clamp(tonumber(options.WalkSpeed) or 32,1,200))
        end
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

local movement = makeMovement({
    Zero=Vector3.zero,
    Character=function()
        local character=LocalPlayer.Character
        return character,character and character:FindFirstChildOfClass("Humanoid"),character and character:FindFirstChild("HumanoidRootPart")
    end,
    Paused=function() return Settings.ReadMenuVisible() or UIS:GetFocusedTextBox()~=nil or game:GetService("GuiService").MenuIsOpen end,
    MoveSpeed=function(root,humanoid,speed)
        local direction=humanoid.MoveDirection*Vector3.new(1,0,1)
        if direction.Magnitude>0.001 then
            local horizontal=direction.Unit*speed
            root.AssemblyLinearVelocity=Vector3.new(horizontal.X,root.AssemblyLinearVelocity.Y,horizontal.Z)
        end
    end,
    Direction=function()
        local camera=workspace.CurrentCamera
        if not camera then return Vector3.zero end
        local direction=Vector3.zero
        local frame=camera.CFrame
        if UIS:IsKeyDown(Enum.KeyCode.W) then direction+=frame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.S) then direction-=frame.LookVector end
        if UIS:IsKeyDown(Enum.KeyCode.D) then direction+=frame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.A) then direction-=frame.RightVector end
        if UIS:IsKeyDown(Enum.KeyCode.Space) then direction+=Vector3.yAxis end
        if UIS:IsKeyDown(Enum.KeyCode.LeftControl) or UIS:IsKeyDown(Enum.KeyCode.LeftShift) then direction-=Vector3.yAxis end
        return direction
    end,
    CreateFlight=function(root)
        local attachment=new("Attachment",{Name="RiftFlightAttachment"},root)
        local velocity=new("LinearVelocity",{Name="RiftFlightVelocity",Attachment0=attachment,
            RelativeTo=Enum.ActuatorRelativeTo.World,VelocityConstraintMode=Enum.VelocityConstraintMode.Vector,
            ForceLimitsEnabled=false,VectorVelocity=Vector3.zero},root)
        local hover=new("AlignPosition",{Name="RiftFlightHover",Attachment0=attachment,
            Mode=Enum.PositionAlignmentMode.OneAttachment,ApplyAtCenterOfMass=true,
            RigidityEnabled=true,Position=root.Position},root)
        local orientation=new("AlignOrientation",{Name="RiftFlightOrientation",Attachment0=attachment,
            Mode=Enum.OrientationAlignmentMode.OneAttachment,RigidityEnabled=true,CFrame=root.CFrame.Rotation},root)
        local moving=false
        return {
            SetVelocity=function(_,command)
                local nextMoving=command.Magnitude>0.001
                if moving and not nextMoving then hover.Position=root.Position end
                hover.Enabled=not nextMoving
                velocity.Enabled=nextMoving
                velocity.VectorVelocity=command
                root.AssemblyAngularVelocity=Vector3.zero
                local camera=workspace.CurrentCamera
                local look=camera and camera.CFrame.LookVector*Vector3.new(1,0,1)
                if look and look.Magnitude>0.001 then orientation.CFrame=CFrame.lookAt(Vector3.zero,look) end
                moving=nextMoving
            end,
            Destroy=function() velocity:Destroy();hover:Destroy();orientation:Destroy();attachment:Destroy() end,
        }
    end,
})
local MainTab=makeTab("Movement")
local gameSections={}
local function section(name)
    local content=makeSection(MainTab.Left,name)
    content.Parent:SetAttribute("SunsetGame","Blox Fruits")
    table.insert(gameSections,{Game="Blox Fruits",Box=content.Parent})
    return content
end
local flySection=section("Fly")
Elements.Toggle(flySection,"Fly",false,function(on) movement.SetFly(on) end)
Elements.Slider(flySection,"Fly Speed",1,300,50,"studs/s",function(value) movement.FlySpeed=value end,1)
local speedSection=section("Speed")
Elements.Toggle(speedSection,"Speed",false,function(on) movement.SetSpeed(on) end)
Elements.Slider(speedSection,"Walk Speed",1,200,32,"studs/s",function(value) movement.WalkSpeed=value end,1)
track(RunService.PreSimulation:Connect(function()
    local ok,message=pcall(movement.Step)
    if not ok then
        movement.Close()
        warn("[RIFT] Blox Fruits movement error: "..tostring(message))
    end
end))
track({Disconnect=function() movement.Close() end})
track(RunService.PostSimulation:Connect(function() movement.AfterPhysics() end))

