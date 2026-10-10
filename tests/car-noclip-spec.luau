local function signal()
    local handlers={}
    return {Connect=function(_,fn)
        local token={active=true} handlers[token]=fn
        return {Disconnect=function() token.active=false end}
    end,Fire=function(_,part) for token,fn in pairs(handlers) do if token.active then fn(part) end end end}
end
local Settings={SelectedGame="Cold War",Notify=function() end}
local controls,connections={},{}
local RunService={PreSimulation=signal()}
local MainTab={Left={}}
local Elements={Toggle=function(_,n,_,fn) controls[n]=fn end}
local function track(c) connections[#connections+1]=c end
local function gameSection() return {} end
local function node(kind,parent)
    local object={Parent=parent,ClassName=kind,CanCollide=true,children={}}
    if parent then parent.children[#parent.children+1]=object end
    function object:IsA(k) return self.ClassName==k end
    function object:IsDescendantOf(other)
        local current=self.Parent
        while current do if current==other then return true end current=current.Parent end
        return false
    end
    function object:FindFirstChildOfClass(k)
        for _,child in ipairs(self.children) do if child:IsA(k) then return child end end
    end
    function object:GetAttribute() return self.NetId end
    function object:GetDescendants()
        local result={}
        local function scan(n) for _,c in ipairs(n.children) do result[#result+1]=c scan(c) end end
        scan(self) return result
    end
    function object:FindFirstAncestorOfClass(k)
        local current=self.Parent
        while current do if current:IsA(k) then return current end current=current.Parent end
    end
    object.DescendantAdded=signal() object.DescendantRemoving=signal()
    return object
end
local workspace=node("Workspace")
local character=node("Model",workspace)
local humanoid=node("Humanoid",character) humanoid.Health=100
local LocalPlayer={Character=character}
local car=node("Model",workspace) car.NetId=1
local chassis=node("BasePart",car)
local wheel=node("BasePart",car) wheel.CanCollide=false
local passenger=node("Model",car)
node("Humanoid",passenger)
local passengerBody=node("BasePart",passenger)
local seat=node("BasePart",car) seat.AssemblyRootPart=chassis
local activeSeat=seat
Settings.ColdWarCarFly={DriverSeat=function() return activeSeat end}
-- INSERT_CAR_NOCLIP
Settings.SetupColdWarCarNoclip()
local options=Settings.ColdWarCarNoclip
options.Step() assert(chassis.CanCollide)
controls["Car Noclip"](true) options.Step()
assert(not chassis.CanCollide and not wheel.CanCollide and passengerBody.CanCollide)
chassis.CanCollide=true options.Step() assert(not chassis.CanCollide)
local added=node("BasePart",car) car.DescendantAdded:Fire(added) assert(not added.CanCollide)
car.DescendantRemoving:Fire(added) assert(added.CanCollide)
added.Parent=workspace
controls["Car Noclip"](false)
assert(chassis.CanCollide and not wheel.CanCollide and passengerBody.CanCollide)
controls["Car Noclip"](true) options.Step()
activeSeat=nil options.Step() assert(chassis.CanCollide)
activeSeat=seat options.Step()
humanoid.Health=0 options.Step() assert(chassis.CanCollide)
humanoid.Health=100 options.Step()
Settings.SelectedGame="Rivals" options.Step() assert(chassis.CanCollide)
Settings.SelectedGame="Cold War" options.Step()
connections[#connections].Disconnect() assert(chassis.CanCollide and not wheel.CanCollide)
options.Step() assert(chassis.CanCollide)
local after=node("BasePart",car) car.DescendantAdded:Fire(after) assert(after.CanCollide)
print("PASS Car Noclip: driver-only scope, original collisions restored, passenger exclusion, added/removed parts, death/game switch/unload")
