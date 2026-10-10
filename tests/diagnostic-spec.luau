local objects, kicks, warnings = {}, {}, {}
local playerGui = {}
local priorDestroyed=0
function playerGui:FindFirstChild(name)
    assert(name=="RiftCrashDiagnostic")
    return {Destroy=function() priorDestroyed+=1 end}
end
local player = {WaitForChild=function(_,name,timeout)
    assert(name=="PlayerGui" and timeout==10) return playerGui
end, Kick=function(_,message) table.insert(kicks,message) end}
local game = {GetService=function(_,name)
    assert(name=="Players", "diagnostic accessed unexpected service")
    return {LocalPlayer=player}
end}
local warn = function(message) table.insert(warnings,message) end
local failClass
local Instance = {new=function(class)
    if class==failClass then error("simulated allocation failure") end
    local object={ClassName=class,Destroy=function(self) self.Destroyed=true end}
    if class=="TextButton" then
        object.Activated={Connect=function(_,callback) object.Click=callback end}
    end
    table.insert(objects,object)
    return object
end}
local UDim2={fromOffset=function() return {} end,new=function() return {} end}
local UDim={new=function() return {} end}
local Color3={fromRGB=function() return {} end}
local Enum={Font={Gotham=1,GothamBold=2}}
local function run()
    -- INSERT_DIAGNOSTIC
end
run()
assert(priorDestroyed==1 and #kicks==0 and #warnings==0)
assert(objects[1].Name=="RiftCrashDiagnostic" and objects[1].Parent==playerGui)
local close,leave
for _,object in ipairs(objects) do
    if object.Text=="Close menu" then close=object end
    if object.Text=="Leave game" then leave=object end
end
assert(close and leave)
close.Click()
assert(objects[1].Destroyed and #kicks==0)
leave.Click()
assert(#kicks==1)
failClass="Frame"
assert(pcall(run), "diagnostic allocation error escaped")
assert(#kicks==2 and #warnings==1 and objects[#objects].Destroyed)
player.WaitForChild=function() return nil end
assert(pcall(run) and #kicks==3)
print("PASS diagnostic: isolated standard UI, close/leave, replacement and startup failure cleanup/kick")
