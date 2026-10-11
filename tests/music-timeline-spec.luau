local data,response
local progressBack={Visible=false}
local timeText={Visible=false}
local progressFill={}
local BedWars={SpotifyTitle={}}
local ENV={request=function() return response end}
local HttpService={JSONDecode=function() return data end}
local UDim2={fromScale=function(x,y) return {X=x,Y=y} end}
local covers=0
local function clearCover() covers+=1 end
local function clockTime(n) return tostring(n) end
-- INSERT_MUSIC_STEP
local function step(payload,status)
    data=payload
    response={StatusCode=status or 200,Body="mock"}
    BedWars.SpotifyStep()
end
step({available=true,title="Track",artist="Artist",duration=100,position=25})
assert(progressBack.Visible and timeText.Visible and progressFill.Size.X==0.25)
step({available=false})
assert(not progressBack.Visible and not timeText.Visible and progressFill.Size.X==0)
step({available=true,title="Track",duration=0})
assert(not progressBack.Visible and not timeText.Visible)
step({available=true,title="   ",duration=100})
assert(not progressBack.Visible and BedWars.SpotifyTitle.Text=="Nothing playing")
step({available=true,title="Track",duration=80,position=20})
step(nil,503)
assert(not progressBack.Visible and not timeText.Visible and progressFill.Size.X==0)
step({available=true,title="Track",duration=80,position=20})
step(nil)
assert(not progressBack.Visible and not timeText.Visible and covers==8)
print("PASS music timeline: track progress, idle/blank/unknown-duration/error cleanup")

