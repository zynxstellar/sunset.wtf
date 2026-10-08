local Frame = {}
Frame.__index = Frame
Frame.__mul = function(a, b) return setmetatable({ Value = a.Value + b.Value }, Frame) end
function Frame.new(value) return setmetatable({ Value = value }, Frame) end
function Frame:Inverse() return Frame.new(-self.Value) end

-- INSERT_UNIVERSAL_VIEWMODEL

local function child(kind, name, pivot, humanoid)
    local object = { Kind = kind, Name = name, CFrame = Frame.new(pivot), Humanoid = humanoid }
    function object:IsA(class) return self.Kind == class end
    function object:FindFirstChildOfClass(class)
        return class == "Humanoid" and self.Humanoid or nil
    end
    function object:GetPivot() return self.CFrame end
    function object:PivotTo(frame) self.CFrame = frame end
    return object
end
local arms = child("Model", "Arms", 10, true)
local gun = child("Model", "AK-47", 20)
local avatar = child("Model", "Character", 30, true)
local hand = child("BasePart", "LeftHand", 40)
local sky = child("BasePart", "Sky", 50)
local camera = { GetChildren = function() return { arms, gun, avatar, hand, sky } end }
moveAimViewmodel(camera, Frame.new(2), Frame.new(7))
assert(arms.CFrame.Value == 15 and gun.CFrame.Value == 25 and hand.CFrame.Value == 45,
    "hands and weapon did not follow the camera turn")
assert(avatar.CFrame.Value == 30 and sky.CFrame.Value == 50,
    "viewmodel update moved unrelated objects")
moveAimViewmodel(camera, Frame.new(7), Frame.new(12))
assert(arms.CFrame.Value == 20 and gun.CFrame.Value == 30 and hand.CFrame.Value == 50,
    "viewmodel stopped following later camera turns")
print("PASS Universal aimbot: hands and weapon follow camera, unrelated objects stay put")
