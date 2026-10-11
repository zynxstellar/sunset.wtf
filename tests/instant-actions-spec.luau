local Settings={SelectedGame="Cold War",Notify=function() end}
local LocalPlayer={}
local PlayerTab={Left={}}
local connections,controls={},{}
local function track(c) connections[#connections+1]=c end
local function gameSection() return {} end
local Elements={Label=function() end,Toggle=function(_,name,_,callback)
    controls[name]=callback
    return {Set=callback}
end}
local root={GetJoints=function() return {} end}
LocalPlayer.Character={FindFirstChild=function() return root end}
local originalTracks={enter="enter",exit="exit",idle="idle"}
local poolCalls,exitCalls,doorCalls,requires=0,0,0,0
local controller={GetSeatTracks=function() return originalTracks end,
    _poolTrack=function(_,_,phase) poolCalls+=1 return phase end,
    _beginExit=function(self,...) exitCalls+=1 return self._seatTracks,... end}
local doors={waitForDoorOpen=function(_,...) doorCalls+=1 return "native",... end}
local nativeGet,nativePool,nativeExit,nativeDoor=controller.GetSeatTracks,controller._poolTrack,controller._beginExit,doors.waitForDoorOpen
local controllerModule,doorModule={},{}
local vehicle={FindFirstChild=function(_,name) return name=="VehicleController" and controllerModule or doorModule end}
local shared={FindFirstChild=function() return vehicle end}
local storage={FindFirstChild=function() return shared end}
local game={GetService=function() return storage end}
local identity=8
local function getthreadidentity() return identity end
local function setthreadidentity(n) identity=n end
local function require(module)
    requires+=1 assert(identity==2)
    return module==controllerModule and controller or doors
end
-- INSERT_INSTANT_ACTIONS
Settings.SetupColdWarInstantActions()
local options=Settings.ColdWarInstantActions
assert(requires==0 and not options.Enabled,"disabled startup required native vehicle modules")
controls["Instant Actions"](true)
assert(options.Enabled and requires==2 and identity==8)
local own={character=LocalPlayer.Character,_seatTracks=originalTracks}
local other={character={},_seatTracks=originalTracks}
local tracks=controller.GetSeatTracks(own)
assert(tracks~=originalTracks and not tracks.enter and not tracks.exit and tracks.idle=="idle")
assert(originalTracks.enter=="enter" and controller.GetSeatTracks(other)==originalTracks)
assert(controller._poolTrack(own,{},"Enter")==nil and controller._poolTrack(own,{},"Exit")==nil)
assert(controller._poolTrack(own,{},"Peek")=="Peek" and controller._poolTrack(other,{},"Enter")=="Enter")
local result=table.pack(controller._beginExit(own,nil,"tail"))
assert(result.n==3 and result[2]==nil and result[3]=="tail" and not own._seatTracks.exit)
controller._beginExit(own)
local car={}
root.GetJoints=function() return {{Part1=root,Part0={IsDescendantOf=function(_,model) return model==car end}}} end
assert(doors.waitForDoorOpen(car)==true and doorCalls==0)
assert(doors.waitForDoorOpen({})=="native" and doorCalls==1)
controls["Instant Actions"](false)
assert(not options.Enabled and controller.GetSeatTracks==nativeGet and controller._poolTrack==nativePool
    and controller._beginExit==nativeExit and doors.waitForDoorOpen==nativeDoor)
assert(own._seatTracks==originalTracks,"disable did not restore current track cache")
controls["Instant Actions"](true)
connections[#connections].Disconnect()
assert(options.Destroyed and not options.Enabled and controller._beginExit==nativeExit)
print("PASS Instant Actions: lazy require, identity restore, local-controller-only ceremony skip, native other/peek/door paths, return slots, cache and unload restoration")
