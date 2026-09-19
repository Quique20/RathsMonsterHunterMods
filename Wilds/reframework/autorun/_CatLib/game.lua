local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local ValueType = ValueType
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local require = require

local SDK = require("_CatLib.sdk")
local CACHE = require("_CatLib.cache")

local Singletons = require("_CatLib.game.singletons")
local Player = require("_CatLib.game.player")
local Quest = require("_CatLib.game.quest")
local Data = require("_CatLib.game.data")
local Text = require("_CatLib.game.text")
local Utils = require("_CatLib.utils")

local _M = {}

_M.GetSingleton = SDK.GetSingleton
_M.GetNativeSingleton = SDK.GetNativeSingleton
_M.GetWrapNativeSingleton = SDK.GetWrapNativeSingleton

_M.Singletons = Singletons
_M.Player = Player
_M.Quest = Quest
_M.Data = Data
_M.Text = Text

-------------------------------
-- Singletons quick access
-------------------------------

_M.GetChatManager = Singletons.GetChatManager
_M.GetNpcManager = Singletons.GetNpcManager
_M.GetOtomoManager = Singletons.GetOtomoManager
_M.GetPlayerManager = Singletons.GetPlayerManager
_M.GetPorterManager = Singletons.GetPorterManager
_M.GetSoundMusicManager = Singletons.GetSoundMusicManager
_M.GetBattleMusicManager = Singletons.GetBattleMusicManager
_M.GetMissionManager = Singletons.GetMissionManager
_M.GetCameraManager = Singletons.GetCameraManager
_M.GetVariousDataManager = Singletons.GetVariousDataManager
_M.GetGUIManager = Singletons.GetGUIManager
_M.GetEnemyManager = Singletons.GetEnemyManager
_M.GetSaveDataManager = Singletons.GetSaveDataManager
_M.GetNetworkManager = Singletons.GetNetworkManager
_M.GetSceneManager = Singletons.GetSceneManager

-------------------------------
-- UTIL FUNCS
-------------------------------

local TargetAccessKey_GetEnemyCharacter = SDK.TypeMethod("app.TargetAccessKeyUtil", "getEnemyCharacter(app.TARGET_ACCESS_KEY, System.Boolean)")
local getActiveQuestTargetBossList = SDK.TypeMethod("app.QuestUtil", "getActiveQuestTargetBossList()")

-- sdk.find_type_definition("app.TargetAccessKeyUtil"):get_method("getEnemyCharacter(app.TARGET_ACCESS_KEY, System.Boolean)"):call(nil, sdk.find_type_definition("app.QuestUtil"):get_method("getActiveQuestTargetBossList()"):call(nil):get_Item(0), true)._Context._Em

---@return app.EnemyCharacter[] (table) | nil
function _M.GetQuestBossList()
    local accessKeys = getActiveQuestTargetBossList:call(nil)
    if accessKeys == nil then
        return nil
    end
    local bosses = {}
   
    Utils.ForEach(accessKeys, function (accessKey)
        local enemy = TargetAccessKey_GetEnemyCharacter:call(nil, accessKey, true)
        table.insert(bosses, enemy)
    end)

    return bosses
end

---@return boolean
function _M.IsLoaded()
    if CACHE.GAME_LOADED then
        return true
    end

    CACHE.GAME_LOADED = Player.GetCharacter() ~= nil
    return CACHE.GAME_LOADED
end

---@param msg string
function _M.SendMessage(msg, ...)
    if not msg then return end
    local mgr = _M.GetChatManager()
    if mgr == nil then 
        log.info(tostring(msg))
        return
    end

    mgr:addSystemLog(string.format(tostring(msg), ...))
end

local LongMsg = ""
local LongMsgCount = 0
local MAX_NEW_LINE = 3
---@param msg string
function _M.BuildLongMessage(msg, ...)
    if not msg then return end

    local newMsg = string.format(tostring(msg), ...)
    if LongMsg == "" then
        LongMsg = newMsg
    else
        LongMsg = LongMsg .. "\n" .. newMsg
    end
    LongMsgCount = LongMsgCount + 1

    if LongMsgCount >= MAX_NEW_LINE then
        _M.FinishLongMessage()
    end
end

function _M.FinishLongMessage()
    if LongMsgCount == 0 or LongMsg == "" then
        return
    end
    local mgr = _M.GetChatManager()
    if mgr == nil then 
        log.info(tostring(LongMsg))
    else
        mgr:addSystemLog(LongMsg)
    end
    LongMsg = ""
    LongMsgCount = 0
end

local GetTimeMethod = SDK.TypeMethod("app.QuestUtil","getUTCTime()")
---@return number time in sec
function _M.GetTime()
    return GetTimeMethod:call(nil)
end

local ColorType = sdk.find_type_definition("via.Color")

---@param rgba number BGRA
---@return via.Color
function _M.NewColor(rgba)
    if not rgba then return nil end
    local color = ValueType.new(ColorType)
    sdk.set_native_field(color, ColorType, "rgba", rgba)
    return color
end

-------------------------------
-- Typed Funcs
-------------------------------

---@return app.HunterCharacter|nil
function _M.ToHunterCharacter(arg)
    return SDK.Cast(arg)
end

---@return app.OtomoCharacter|nil
function _M.ToOtomoCharacter(arg)
    return SDK.Cast(arg)
end

---@return app.EnemyCharacter|nil
function _M.ToEnemyCharacter(arg)
    return SDK.Cast(arg)
end

-------------------------------
-- Useful Game Related
-------------------------------



return _M
