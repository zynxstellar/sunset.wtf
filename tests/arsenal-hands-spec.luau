local game = { PlaceId = 286090429 }
local Frame = {}
Frame.__index = Frame
Frame.__mul = function(a, b) return setmetatable({ Value = a.Value + b.Value }, Frame) end
function Frame.new(value) return setmetatable({ Value = value }, Frame) end
function Frame:Inverse() return Frame.new(-self.Value) end

-- INSERT_ARSENAL_VIEWMODEL

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
moveArsenalViewmodel(camera, Frame.new(2), Frame.new(7))
assert(arms.CFrame.Value == 15 and gun.CFrame.Value == 25 and hand.CFrame.Value == 45,
    "Arsenal hands and weapon did not follow the camera turn")
assert(avatar.CFrame.Value == 30 and sky.CFrame.Value == 50,
    "Arsenal viewmodel update moved unrelated objects")
game.PlaceId = 17625359962
moveArsenalViewmodel(camera, Frame.new(7), Frame.new(12))
assert(arms.CFrame.Value == 15, "Arsenal viewmodel update ran in another game")
print("PASS Arsenal aimbot: hands and weapon follow camera, unrelated objects stay put")
