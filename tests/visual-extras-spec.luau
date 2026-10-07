local meta = {}
local Vector3 = {new = function(x,y,z) return setmetatable({X=x,Y=y,Z=z},meta) end}
function meta.__add(a,b) return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z) end
function meta.__sub(a,b) return Vector3.new(a.X-b.X,a.Y-b.Y,a.Z-b.Z) end
function meta.__mul(a,b) return Vector3.new(a.X*b,a.Y*b,a.Z*b) end
function meta.__index(a,k)
    if k=="Magnitude" then return math.sqrt(a.X*a.X+a.Y*a.Y+a.Z*a.Z) end
    if k=="Unit" then return a*(1/a.Magnitude) end
end
local Vector2 = {new=function(x,y) return {X=x,Y=y} end}
local function typeof(v) return getmetatable(v)==meta and "Vector3" or type(v) end
local Color3={fromRGB=function(...) return {...} end}
local now=0
local os={clock=function() return now end}
local lines,connections,controls={},{},{}
local ENV={Drawing={new=function(kind)
    assert(kind=="Line")
    local line={Remove=function(self) self.Removed=true self.Visible=false end}
    table.insert(lines,line) return line
end}}
local Settings={SelectedGame="Cold War"}
local LocalPlayer={}
local RunService={RenderStepped={Connect=function(_,f) return {Disconnect=function() end} end}}
local function track(c) table.insert(connections,c) end
local VisualsTab={Left={}}
local function gameSection(_,_,name) return name end
local Elements={}
local function control(s,n,d,fn) controls[s.."/"..n]={Set=function(v) fn(v) end} end
Elements.Toggle=control Elements.ColorPicker=control
function Elements.Slider(s,n,min,max,d,units,fn) control(s,n,d,fn) end
local function camera(fov)
    return {FieldOfView=fov,WorldToViewportPoint=function(_,p) return p,true end}
end
local firstCamera=camera(70)
local collision=false
local workspace={CurrentCamera=firstCamera,Raycast=function(_,a,b,params)
    assert(params.Native)
    if collision then return {Position=a+b*0.5} end
end}
local syncs=0
Settings.ColdWarAim={Enabled=false,SetEnabled=function(on) assert(not on) syncs+=1 end,
    WeaponSource={toFireParams=function(p)
        assert(p.Owner==LocalPlayer)
        return {Weapon={MuzzleSpeed=100,K=0},RaycastParams={Native=true}}
    end},Trajectory={new=function(p) return p end,
        GetPositionAtTime=function(p,t) return p.Origin+p.Direction*(p.MuzzleSpeed*t) end}}
-- INSERT_VISUAL_EXTRAS
Settings.SetupColdWarVisualExtras()
local trails=Settings.ColdWarBulletTrails
local function fire()
    trails.Record({},1,2,Vector3.new(0,0,1),{Vector3.new(0,0,1)})
end
fire() assert(#trails.Queue==0,"disabled trail recorded")
controls["Bullet Tracers/Bullet Tracers"].Set(true)
assert(syncs==1,"trail-only enable did not synchronize firing observer")
fire() trails.Update()
assert(#trails.Paths==1 and #lines==32 and lines[1].Visible)
now=1.3 trails.Update()
assert(lines[1].Transparency>0 and lines[1].Transparency<1,"trail did not fade")
now=1.5 trails.Update()
assert(#trails.Paths==0 and lines[1].Removed,"expired drawing leaked")
collision=true fire() trails.Update()
assert(#trails.Paths[1].Points==2,"path crossed first collision")
for _=1,100 do fire() end
assert(#trails.Queue==32,"shot queue is unbounded")
trails.Update() assert(#trails.Paths==32,"path storage is unbounded")
controls["Bullet Tracers/Bullet Tracers"].Set(false)
assert(#trails.Paths==0 and #trails.Queue==0)
for _,line in ipairs(lines) do assert(line.Removed,"disable leaked drawing") end
controls["FOV/FOV"].Set(true) trails.Update()
assert(firstCamera.FieldOfView==90)
controls["FOV/Field of View"].Set(110) trails.Update()
assert(firstCamera.FieldOfView==110)
local secondCamera=camera(80) workspace.CurrentCamera=secondCamera trails.Update()
assert(firstCamera.FieldOfView==70 and secondCamera.FieldOfView==110,"camera switch did not restore old FOV")
Settings.SelectedGame="Rivals" trails.Update() assert(secondCamera.FieldOfView==80)
Settings.SelectedGame="Cold War" trails.Update() assert(secondCamera.FieldOfView==110)
controls["Bullet Tracers/Bullet Tracers"].Set(true) fire() trails.Update()
connections[#connections].Disconnect()
assert(secondCamera.FieldOfView==80 and #trails.Paths==0,"unload leaked FOV or trails")
fire() trails.Update() assert(#trails.Queue==0,"unloaded observer recorded shots")
print("PASS Cold War visuals: bounded trails, first collision, fade/expiry, disable/unload cleanup, FOV camera replacement and game switching")
local currentAtmosphere={Parent=true,Density=0.4}
local Lighting={FogEnd=500,Brightness=1,Ambient="dim",OutdoorAmbient="dark",GlobalShadows=true,
    FindFirstChildOfClass=function() return currentAtmosphere end}
-- INSERT_VISIBILITY
Settings.SetupColdWarVisibility()
local visibility=Settings.ColdWarVisibility
controls["Visibility/No Fog"].Set(true)
assert(Lighting.FogEnd==1000000 and currentAtmosphere.Density==0)
controls["Visibility/Full Bright"].Set(true)
assert(Lighting.Brightness==4 and not Lighting.GlobalShadows)
local replacement={Parent=true,Density=0.6}
currentAtmosphere=replacement visibility.Update()
assert(replacement.Density==0,"replacement atmosphere retained fog")
controls["Visibility/No Fog"].Set(false)
assert(Lighting.FogEnd==500 and replacement.Density==0.6 and Lighting.Brightness==4)
controls["Visibility/No Fog"].Set(true)
Settings.SelectedGame="Rivals" visibility.Update()
assert(Lighting.FogEnd==500 and Lighting.Brightness==1 and replacement.Density==0.6)
Settings.SelectedGame="Cold War" visibility.Update()
assert(Lighting.FogEnd==1000000 and Lighting.Brightness==4)
connections[#connections].Disconnect()
assert(Lighting.FogEnd==500 and Lighting.Brightness==1 and Lighting.GlobalShadows and replacement.Density==0.6)
print("PASS Cold War visibility: fog, brightness, atmosphere replacement, game switch, unload restoration")
