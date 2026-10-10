local Color3 = {}
function Color3.new(r,g,b)
    return {R=r,G=g,B=b,Lerp=function(self,other,t)
        return Color3.new(self.R+(other.R-self.R)*t,self.G+(other.G-self.G)*t,self.B+(other.B-self.B)*t)
    end}
end
function Color3.fromRGB(r,g,b) return Color3.new(r/255,g/255,b/255) end
local children, connections, controls = {}, {}, {}
local Lighting = {ClockTime=9,Brightness=1,Ambient="old ambient",OutdoorAmbient="old outdoor",FogColor="old fog",FogEnd=500}
function Lighting:FindFirstChildOfClass(kind)
    for _,child in ipairs(children) do if child.ClassName==kind and child.Parent==self then return child end end
end
local function new(kind, props, parent)
    local obj={ClassName=kind,Parent=parent}
    for k,v in pairs(props) do obj[k]=v end
    function obj:Destroy() self.Parent=nil self.Destroyed=true end
    table.insert(children,obj)
    return obj
end
local function track(c) table.insert(connections,c) return c end
local workspace={FindFirstChildOfClass=function() return nil end}
local Elements={}
function Elements.Dropdown(_,name,_,_,fn) controls[name]=fn end
function Elements.Toggle(_,name,_,fn) controls[name]=fn end
Elements.ColorPicker=Elements.Toggle
function Elements.Slider(_,name,_,_,_,_,fn) controls[name]=fn end
-- INSERT_ATMOSPHERE
local originalSky=new("Sky",{},Lighting)
for _,property in ipairs(skyProperties) do originalSky[property]="original "..property end
local oldAtmosphere=new("Atmosphere",{},Lighting)
for _,property in ipairs(atmosphereProperties) do oldAtmosphere[property]=0.1 end
atmosphereColorControls({})
controls.Sky("Purple")
assert(not atmosphereEnabled and not activeSky,"disabled options edited world")
setAtmosphereEnabled(true)
assert(activeSky==originalSky and activeSky.SkyboxBk=="rbxassetid://159454299")
assert(atmosphereCorrection.Saturation==0.45 and atmosphereCorrection.Brightness==0.1)
assert(atmosphereCorrection.Enabled and atmosphereCorrection.TintColor.G<0.5,"purple mood not applied")
controls["Custom Ambient"](true)
controls["Ambient Color"]("custom ambient")
controls["Outdoor Ambient"]("custom outdoor")
assert(Lighting.Ambient=="custom ambient" and Lighting.OutdoorAmbient=="custom outdoor")
controls["Screen Tint"](true)
controls["Tint Color"](Color3.new(0,0,1))
controls["Tint Strength"](100)
assert(atmosphereCorrection.TintColor.R==0 and atmosphereCorrection.TintColor.B==1)
controls.Sky("Original")
assert(originalSky.SkyboxBk=="original SkyboxBk" and originalSky.Parent==Lighting)
controls.Sky("Blue")
local cc=atmosphereCorrection
setAtmosphereEnabled(false)
assert(Lighting.ClockTime==9 and Lighting.Ambient=="old ambient" and Lighting.FogEnd==500)
assert(originalSky.SkyboxUp=="original SkyboxUp" and cc.Destroyed)
assert(oldAtmosphere.Density==0.1)
originalSky:Destroy() oldAtmosphere:Destroy()
setAtmosphereEnabled(true)
local sky, atmos, correction=activeSky,activeAtmosphere,atmosphereCorrection
restoreAtmosphere()
assert(sky.Destroyed and atmos.Destroyed and correction.Destroyed,"created effects leaked")
assert(not controls["Custom Time"] and not controls["Time of Day"])
print("PASS atmosphere: disabled options, sky replacement/restoration, ambient colors, whole-screen tint, cleanup")
