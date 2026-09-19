local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local require = require
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table


local SDK = require("_CatLib.sdk")
local CACHE = require("_CatLib.cache")
local Singletons = require("_CatLib.game.singletons")


local _M = {}

local Get_QuestDirector = sdk.find_type_definition("app.MissionManager"):get_method("get_QuestDirector()")
local Get_IsPlayingQuest = sdk.find_type_definition("app.MissionManager"):get_method("get_IsPlayingQuest()")
local Get_IsActiveQuest = sdk.find_type_definition("app.MissionManager"):get_method("get_IsActiveQuest()")

---@return app.cQuestDirector
function _M.GetQuestDirector()
    -- TODO: CACHE this? it returns different ref everytime outside quest
    local mgr = Singletons.GetMissionManager()
    return Get_QuestDirector:call(mgr)
end

--- returns true if any enemy still alive
function _M.IsPlaying()
    local mgr = Singletons.GetMissionManager()
    if mgr == nil then
        return false
    end

    -- mgr:get_IsActiveQuest() -- Quest end time still true
    -- mgr:getAcceptQuestTargetBrowsers() ~= nil and browsers:get_Count() > 0 -- same
    return Get_IsPlayingQuest:call(mgr)
end

--- returns true if in quest, even if all enemies died.
function _M.IsActive()
    local mgr = Singletons.GetMissionManager()
    if mgr == nil then
        return false
    end
    return Get_IsActiveQuest:call(mgr)
end

--- returns true if quest is finished (last 60s)
function _M.IsFinishing()
    local mgr = Singletons.GetMissionManager()
    if mgr == nil then
        -- log.info("BattleMusicManager is nil, skipped")
        return false
    end
    return _M.IsActive() and not _M.IsPlaying()
end

local Get_ActiveTimeLimit = sdk.find_type_definition("app.cQuestDirector"):get_method("getActiveTimeLimit()")
local Get_QuestRemainTime = sdk.find_type_definition("app.cQuestDirector"):get_method("get_QuestRemainTime()")
local Get_QuestElapsedTime = sdk.find_type_definition("app.cQuestDirector"):get_method("get_QuestElapsedTime()")
local Get_QuestStartedTime = sdk.find_type_definition("app.cQuestDirector"):get_method("get_QuestStartedTime()")

function _M.GetTimeLimit()
    local director = _M.GetQuestDirector()
    if not director then return -1 end
    return Get_ActiveTimeLimit:call(director)
end

function _M.GetRemainTime()
    local director = _M.GetQuestDirector()
    if not director then return -1 end
    return Get_QuestRemainTime:call(director)
end

function _M.GetElapsedTime()
    local director = _M.GetQuestDirector()
    if not director then return -1 end
    return Get_QuestElapsedTime:call(director)
end

function _M.GetStartedTime()
    local director = _M.GetQuestDirector()
    if not director then return -1 end
    return Get_QuestStartedTime:call(director)
end

return _M