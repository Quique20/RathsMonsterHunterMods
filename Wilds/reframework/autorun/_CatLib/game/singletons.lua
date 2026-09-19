local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table

local SDK = require("_CatLib.sdk")
local CACHE = require("_CatLib.cache")

local GetSingleton = SDK.GetSingleton
local GetNativeSingleton = SDK.GetNativeSingleton
local GetWrapNativeSingleton = SDK.GetWrapNativeSingleton

local _M = {}

_M.GetSingleton = SDK.GetSingleton
_M.GetNativeSingleton = SDK.GetNativeSingleton
_M.GetWrapNativeSingleton = SDK.GetWrapNativeSingleton

---@return app.ChatManager
function _M.GetChatManager()
	return GetSingleton("app.ChatManager")
end

---@return app.NpcManager
function _M.GetNpcManager()
	return GetSingleton("app.NpcManager")
end

---@return app.OtomoManager
function _M.GetOtomoManager()
	return GetSingleton("app.OtomoManager")
end

---@return app.PlayerManager
function _M.GetPlayerManager()
    return GetSingleton("app.PlayerManager")
end

---@return app.PorterManager
function _M.GetPorterManager()
    return GetSingleton("app.PorterManager")
end

---@return app.SoundMusicManager
function _M.GetSoundMusicManager()
    return GetSingleton("app.SoundMusicManager")
end

---@return app.BattleMusicManager
function _M.GetBattleMusicManager()
    if CACHE.Singletons.BattleMusicManager == nil then
        local soundMgr = _M.GetSoundMusicManager()
        if soundMgr ~= nil then
            CACHE.Singletons.BattleMusicManager = soundMgr:get_BattleMusic()
        end
    end

	return CACHE.Singletons.BattleMusicManager
end

---@return app.MissionManager
function _M.GetMissionManager()
    return GetSingleton("app.MissionManager")
end

---@return app.CameraManager
function _M.GetCameraManager()
    return GetSingleton("app.CameraManager")
end

---@return app.VariousDataManager
function _M.GetVariousDataManager()
    return GetSingleton("app.VariousDataManager")
end

---@return app.GUIManager
function _M.GetGUIManager()
    return GetSingleton("app.GUIManager")
end

---@return app.EnemyManager
function _M.GetEnemyManager()
    return GetSingleton("app.EnemyManager")
end

---@return app.SaveDataManager
function _M.GetSaveDataManager()
    return GetSingleton("app.SaveDataManager")
end

---@return app.NetworkManager
function _M.GetNetworkManager()
    return GetSingleton("app.NetworkManager")
end

---@return app.GameFlowManager
function _M.GetGameFlowManager()
    return GetSingleton("app.GameFlowManager")
end

--------------------- Native ---------------------

---@return via.SceneManager
function _M.GetSceneManager()
    return GetNativeSingleton("via.SceneManager")
end

return _M
