-- Previous BedWars Anti Void rescue, saved before replacing hard teleportation.
-- This is an archival snippet, not a standalone script.
--[[
if grounded then
    BedWars.LastSafeCFrame = root.CFrame
elseif BedWars.LastSafeCFrame
    and (not hit or root.Position.Y - hit.Position.Y > 20)
    and root.AssemblyLinearVelocity.Y < -8
    and root.Position.Y < BedWars.LastSafeCFrame.Position.Y - 7
    and os.clock() - (BedWars.LastVoidRescue or 0) > 0.8 then
    BedWars.LastVoidRescue = os.clock()
    root.CFrame = BedWars.LastSafeCFrame + Vector3.new(0, 2.5, 0)
    root.AssemblyLinearVelocity = Vector3.zero
    root.AssemblyAngularVelocity = Vector3.zero
end
]]
