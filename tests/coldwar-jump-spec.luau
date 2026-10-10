local Vector3={new=function(x,y,z) return {X=x,Y=y,Z=z} end}
local Enum={Material={Air="air"},HumanoidStateType={Swimming="swim",Jumping="jump"}}
local workspace={Gravity=196.2}
local root={AssemblyLinearVelocity=Vector3.new(2,0,3)}
local humanoid={Health=100,FloorMaterial="ground",UseJumpPower=true,JumpPower=50,State="run",Jumps=0}
function humanoid:GetState() return self.State end
function humanoid:ChangeState(value) assert(value=="jump") self.Jumps+=1 end
local LocalPlayer={Character={FindFirstChild=function() return root end,FindFirstChildOfClass=function() return humanoid end}}
local menu,typing=false,false
local function anyMenuVisible() return menu end
local UIS={GetFocusedTextBox=function() return typing end,JumpRequest={Connect=function() return {Disconnect=function() end} end}}
local Settings={SelectedGame="Cold War"}
local MainTab={Left={}}
local function gameSection() return {} end
local controls,connections={},{}
local Elements={Toggle=function(_,name,_,fn) controls[name]=fn end}
local function track(c) table.insert(connections,c) end
-- INSERT_COLDWAR_JUMP
Settings.SetupColdWarJump()
local jump=Settings.ColdWarJump
jump.Request() assert(humanoid.Jumps==0)
controls["No Jump Delay"](true)
jump.Request() assert(humanoid.Jumps==1 and root.AssemblyLinearVelocity.Y==50 and root.AssemblyLinearVelocity.X==2)
humanoid.FloorMaterial="air" jump.Request() assert(humanoid.Jumps==1,"air jump allowed")
humanoid.FloorMaterial="ground" root.AssemblyLinearVelocity.Y=0 jump.Request()
assert(humanoid.Jumps==2,"next grounded jump was delayed")
menu=true jump.Request() menu=false
typing=true jump.Request() typing=false
humanoid.Sit=true jump.Request() humanoid.Sit=false
humanoid.Health=0 jump.Request() humanoid.Health=100
assert(humanoid.Jumps==2,"blocked input triggered a jump")
humanoid.UseJumpPower=false humanoid.JumpHeight=7 root.AssemblyLinearVelocity.Y=0 jump.Request()
assert(math.abs(root.AssemblyLinearVelocity.Y-math.sqrt(2*196.2*7))<0.01)
for _,c in ipairs(connections) do c:Disconnect() end
controls["No Jump Delay"](true) jump.Request()
assert(humanoid.Jumps==3 and jump.Destroyed and not jump.Enabled)
print("PASS Cold War No Jump Delay: grounded repeats, airborne/input/death/seating filters, jump height and unload")
