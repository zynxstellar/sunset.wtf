local function object(name,parent)
    local o={Name=name,Parent=parent,Children={}}
    if parent then parent.Children[name]=o end
    function o:FindFirstChild(key) return self.Children[key] end
    function o:FindFirstAncestorOfClass() return self.Parent end
    return o
end
local LocalPlayer=object("Me") LocalPlayer.Team={Name="NATO"}
local module=object("HitReporter",object("BallisticsClient",object("PlayerScripts",LocalPlayer)))
local enemy,ally={Team={Name="PACT"}},{Team=LocalPlayer.Team}
local enemyModel,allyModel=object("Enemy"),object("Ally")
local enemyPart,allyPart=object("Head",enemyModel),object("Head",allyModel)
local Players={GetPlayerFromCharacter=function(_,model)
    return model==enemyModel and enemy or model==allyModel and ally or nil
end}
local loaded,identity,requires=false,8,0
local function rivalsModuleLoaded() return loaded end
local function getthreadidentity() return identity end
local function setthreadidentity(value) identity=value end
local calls,fail=0,false
local native=function(id,impact,...)
    calls+=1
    if fail then error("native report failed") end
    return "native",nil,3
end
local reporter={sendClaim=native}
local function require(m) assert(m==module and identity==2) requires+=1 return reporter end
local files,downloads,plays,saved,assets={},0,0,0,0
local tasks={}
local task={spawn=function(fn) table.insert(tasks,fn) end}
local function finish() local q=tasks tasks={} for _,fn in ipairs(q) do fn() end end
local audioDecodeFailure=false
local preloads=0
local game={GetService=function(_,name)
    if name=="ContentProvider" then return {PreloadAsync=function(_,list)
        preloads+=1
        for _,sound in ipairs(list) do sound.IsLoaded=not audioDecodeFailure end
    end} end
    return {}
end,HttpGet=function(_,url)
    assert(url:find("cd25bf679f5c56449332741079e304229cfd1ee5/assets/hitsounds/",1,true))
    downloads+=1 return "OggS"..string.rep("a",120)
end}
local ENV={getcustomasset=function(path) assets+=1 assert(files[path]) return "asset:"..path end,
    isfile=function(path) return files[path]~=nil end,
    writefile=function(path,data) files[path]=data saved+=1 end,makefolder=function() end}
local soundsCreated={}
local function new(kind,props,parent)
    assert(kind=="Sound")
    local s={Stop=function(self) self.Stopped=true end,Play=function(self) plays+=1 self.Played=true self.Stopped=false end,
        Destroy=function(self) self.Destroyed=true end}
    if props.Name=="RiftHitSound" then table.insert(soundsCreated,s) end
    return s
end
local Settings={SelectedGame="Cold War"}
local controls,connections={},{ }
local VisualsTab={Left={}}
local function gameSection() return {} end
local Elements={Toggle=function(_,name,default,fn) controls[name]=fn end,
    Dropdown=function(_,name,items,default,fn) assert(#items==24) controls[name]=fn end,
    Slider=function(_,name,min,max,default,suffix,fn) controls[name]=fn end,
    Button=function(_,name,fn) controls[name]=fn end}
local function track(c) table.insert(connections,c) end
local RunService={RenderStepped={Connect=function() return {Disconnect=function() end} end}}
local now=0
local os={clock=function() return now end}
local warnings={}
local function warn(message) table.insert(warnings,message) end
-- INSERT_HIT_SOUNDS
Settings.SetupColdWarHitSounds()
local hits=Settings.ColdWarHitSounds
local function step() now+=0.1 hits.Update() assert(identity==8) end
step() assert(requires==0 and downloads==0,"disabled hitsounds did work")
controls["Hit Sounds"](true)
assert(downloads==0 and #tasks==1,"audio download blocked enabling")
finish() assert(downloads==1 and hits.Asset and saved==1 and preloads==1 and hits.AudioReady)
loaded=true now+=1 step()
assert(requires==1 and reporter.sendClaim~=native)
local result=table.pack(reporter.sendClaim(1,{Instance=enemyPart},"extra"))
assert(result.n==3 and result[1]=="native" and result[3]==3 and calls==1)
step() assert(plays==1,"enemy collision did not play")
reporter.sendClaim(1,{Instance=enemyPart}) step() assert(plays==1,"duplicate pellet played twice")
reporter.sendClaim(2,{Instance=allyPart}) step() assert(plays==1,"teammate triggered hit sound")
reporter.sendClaim(3,{Instance=object("Rock",object("World"))}) step()
assert(plays==1,"world collision triggered hit sound")
enemy.Team=LocalPlayer.Team
reporter.sendClaim(4,{Instance=enemyPart}) step() assert(plays==1)
enemy.Team={Name="PACT"}
controls.Volume(30) controls.Pitch(125)
reporter.sendClaim(5,{Instance=enemyPart}) step()
assert(plays==2 and soundsCreated[2].Volume==0.3 and soundsCreated[2].PlaybackSpeed==1.25)
controls.Sound("Glass 2") assert(not hits.Asset)
controls.Preview() assert(#tasks==1,"preview duplicated pending download")
finish() assert(downloads==2 and plays==3)
controls.Sound("Bell 1") assert(downloads==2 and hits.Asset,"cached sound downloaded again")
fail=true local ok=pcall(reporter.sendClaim,6,{Instance=enemyPart}) fail=false
assert(not ok and #hits.Queue==0,"failed native report enqueued a hit")
reporter.sendClaim(7,{Instance=enemyPart})
controls["Hit Sounds"](false) step()
assert(plays==3 and reporter.sendClaim==native,"disable leaked pending hits or hook")
controls.Preview()
step()
assert(plays==4 and not soundsCreated[4].Stopped,"disabled module cut off Preview on the next frame")
controls["Hit Sounds"](true) now+=1 step()
local foreign=function() end reporter.sendClaim=foreign
hits.Restore() assert(reporter.sendClaim==foreign,"unload overwrote a foreign hook")
for _,sound in ipairs(soundsCreated) do assert(sound.Destroyed,"sound instance leaked") end
reporter.sendClaim=native
Settings.SetupColdWarHitSounds() hits=Settings.ColdWarHitSounds
controls.Sound("Punch 3") controls.Preview()
hits.Restore() finish()
assert(plays==4,"late download played after unload")
Settings.SetupColdWarHitSounds() hits=Settings.ColdWarHitSounds
audioDecodeFailure=true controls.Preview() finish()
assert(not hits.AudioReady and hits.LastError and #warnings>0,"unplayable audio was silently accepted")
hits.Restore()
print("PASS Hit Sounds: 24 choices, deferred cached assets, enemy reports, duplicate/team/world filters, native results/errors, preview/volume/pitch, disable/unload")
