local function signal()
    local callbacks={}
    return {Connect=function(_,callback)
        table.insert(callbacks,callback)
        return {Disconnect=function() end}
    end,Fire=function(_,value) for _,callback in ipairs(callbacks) do callback(value) end end}
end
local Settings={IsColdWar=false}
local function model() return {IsA=function(_,kind) return kind=="Model" end} end
local first={Character=model(),CharacterAdded=signal()}
local owners={[first.Character]=first}
local Players={PlayerAdded=signal(),GetPlayers=function() return {first} end,
    GetPlayerFromCharacter=function(_,character) return owners[character] end}
local workspace=setmetatable({}, {__index=function() error("player indexing accessed the map") end})
local function track(connection) return connection end
-- INSERT_PLAYER_INDEX
assert(TargetModels[first.Character], "existing player was not indexed")
local second={Character=model(),CharacterAdded=signal()}
owners[second.Character]=second
Players.PlayerAdded:Fire(second)
assert(TargetModels[second.Character], "new player was not indexed")
local respawn=model()
owners[respawn]=second
second.CharacterAdded:Fire(respawn)
assert(TargetModels[respawn], "respawn was not indexed")
local npc=model()
registerTargetPart(npc)
assert(TargetModels[npc]==nil, "NPC entered the player-only ESP index")
assert(getmetatable(TargetModels).__mode=="k", "stale characters are retained strongly")
print("PASS player index: players, joins, respawns, NPC rejection, weak retention, zero map access")
