local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local thread = thread
local require = require
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local type = type
local _ = _


local SDK = require("_CatLib.sdk")
local CACHE = require("_CatLib.cache")
local Utils = require("_CatLib.utils")

local _M = {}

_M.Player = nil
_M.WeaponHandling = nil
_M.MotionSupporter = nil
_M.InputCache = {}

function _M.Init()
    if _M.Player == nil then
        _M.Player = sdk.get_managed_singleton("app.PlayerManager"):getMasterPlayer():get_Character()
        _M.WeaponHandling = _M.Player:get_WeaponHandling()
        _M.MotionSupporter = _M.Player._HunterMotionSupporter
    end
end

function _M.Refresh()
    _M.Player = nil
    _M.Init()
end

SDK.HookFunc("app.GUIManager", "onPlEquipChange()", function ()
    _M.Refresh()    
end)

-------------------------------
-- Global Vars
-------------------------------

local KeyboardKeyIndex = Utils.GetEnumMap("ace.ACE_MKB_KEY.INDEX")
local KeyboardKeyIndex_ToValue = {}
for idx, name in pairs(KeyboardKeyIndex) do
    KeyboardKeyIndex_ToValue[name] = idx
end

local KeyboardManager = SDK.GetSingleton("ace.MouseKeyboardManager")
_M.KeyboardManager = KeyboardManager

---@param key string
local function KeyOn(key)
    return KeyboardManager:get_MainMouseKeyboard():isOn(KeyboardKeyIndex_ToValue[key])
end

local CheckCommandResult = SDK.TypeMethod("app.PlayerUtil", "checkCommandResult(app.cPlayerBTableCommandWork, app.HunterDef.BTABLE_COMMAND_OPTION, app.PlayerCommand.TYPE)")

local PlayerCommand_Type = Utils.GetEnumMap("app.PlayerCommand.TYPE")
local PlayerCommand_Type_ToValue = {}
for idx, name in pairs(PlayerCommand_Type) do
    PlayerCommand_Type_ToValue[name] = idx
end

local PlayerCommand_TypeFixed = Utils.GetEnumMap("app.PlayerCommand.TYPE_Fixed")
local PlayerCommand_TypeFixed_ToValue = {}
for idx, name in pairs(PlayerCommand_TypeFixed) do
    PlayerCommand_TypeFixed_ToValue[name] = idx
end

function _M.CheckCommandResult(commandWork, option, CommandType)
    return CheckCommandResult:call(nil, commandWork, option, CommandType)
end

---@param commandType string
---@param commandWork ace.btable.cCommandWork
---@param debug boolean show debug log
function _M.LogCommandResult(commandType, commandWork, debug)
    if debug then
        local CommandType = PlayerCommand_Type_ToValue[commandType]
        local NoneAtk01 = CheckCommandResult:call(nil, commandWork, 0, CommandType)
        local WatchCancelAtk01 = CheckCommandResult:call(nil, commandWork, 1, CommandType)
        local NotWatchCancelAtk01 = CheckCommandResult:call(nil, commandWork, 2, CommandType)
        log.info(string.format("CmdResult %s: %s, %s, %s [NonCancel]", PlayerCommand_Type[CommandType], tostring(NoneAtk01), tostring(WatchCancelAtk01), tostring(NotWatchCancelAtk01)))
    end
end

---@param key string
---@param cancelIndex app.ACTION_CANCEL_INDEX
---@param debug boolean show debug log
function _M.LogRawInput(key, cancelIndex, debug)
    local Pressed = KeyOn(key)
    local CachedPressed = _M.InputCache[key]

    if cancelIndex then
        if debug then
            log.info(string.format("Keyboard %s: %s (Cached: %s), PreCancel: %s, Cancel: %s", key, tostring(Pressed), tostring(CachedPressed), tostring(_M.MotionPreCancel(cancelIndex)), tostring(_M.MotionCancel(cancelIndex))))
        end
    else
        if debug then
            log.info(string.format("Keyboard %s: %s (Cached: %s)", key, tostring(Pressed), tostring(CachedPressed)))
        end
    end
end

-------------------------------
-- State Management
-------------------------------

---@param layer app.AppActionDef.LAYER
---@param actionID ace.ACTION_ID
function _M.ChangeAction(layer, actionID)
    _M.Init()
    return _M.Player:call("changeActionRequest(app.AppActionDef.LAYER, ace.ACTION_ID, System.Boolean)", layer, actionID, false)
end


-------------------------------
-- FSM
-------------------------------

---@param log_str nil|string
function _M.AbortFSM(log_str)
    local storage = thread.get_hook_storage()
    storage["retval"] = true
    if log_str then
        log.info(log_str)
    end
    return sdk.PreHookResult.SKIP_ORIGINAL
end

function _M.AbortFSMPostHook(retval)
    local storage = thread.get_hook_storage()
    local result = storage["retval"]
    storage["retval"] = nil
    if result then
        -- log.info(string.format("Skipped"))
        return sdk.to_ptr(result)
    end

    return retval
end

-------------------------------
-- Input Check
-------------------------------

---@param cancelIndex app.ACTION_CANCEL_INDEX
function _M.MotionPreCancel(cancelIndex)
    _M.Init()

    return _M.Player:call("checkPreCancelMotion(app.ACTION_CANCEL_INDEX)", cancelIndex) 
end

---@param cancelIndex app.ACTION_CANCEL_INDEX
function _M.MotionCancel(cancelIndex)
    if cancelIndex == nil then
        return true
    end
    _M.Init()

    local result = _M.Player:call("checkCancelMotion(app.ACTION_CANCEL_INDEX, System.Boolean)", cancelIndex, false)
    -- log.info(string.format("Player can cancel motion? %s", tostring(result)))

    return result
end

---@param cancelIndex app.ACTION_CANCEL_INDEX
function _M.IsValidMotionInputCache(cancelIndex)
    if cancelIndex == nil then
        return true
    end
    _M.Init()

    return _M.MotionPreCancel(cancelIndex) or _M.MotionCancel(cancelIndex)
end

function _M._CacheInputCanProcess(commandWork, key, cancelIndex)
    _M.Init()

    return _M.InputCache[key] and _M.MotionCancel(cancelIndex)
end

---@param commandWork ace.btable.cCommandWork
---@param command string
---@param state boolean
---@param cancelIndex app.ACTION_CANCEL_INDEX
function _M.CommandStateInputCancelMotion(commandWork, command, state, cancelIndex)
    _M.Init()

    local canCancel = _M.IsValidMotionInputCache(cancelIndex)

    if canCancel then
        _M.InputCache[command] = state
    else
        _M.InputCache[command] = false
    end

    return _M._CacheInputCanProcess(commandWork, command, cancelIndex)
end

---@param commandWork ace.btable.cCommandWork
---@param key string
---@param cancelIndex app.ACTION_CANCEL_INDEX
function _M.RawInputCancelMotion(commandWork, key, cancelIndex)
    _M.Init()

    local canCancel = _M.IsValidMotionInputCache(cancelIndex)

    if canCancel then
        _M.InputCache[key] = KeyOn(key)
    else
        _M.InputCache[key] = false
    end

    return _M._CacheInputCanProcess(commandWork, key, cancelIndex)
end

---@param commandWork ace.btable.cCommandWork
---@param commandName string
---@param cancelIndex app.ACTION_CANCEL_INDEX
function _M.InputCancelMotion(commandWork, commandName, cancelIndex)
    _M.Init()

    local canCancel = _M.IsValidMotionInputCache(cancelIndex)

    if canCancel then
        -- todo fixme?
        -- log.info(string.format("Input was: %s", tostring(_M.InputCache[commandName])))
        _M.InputCache[commandName] = CheckCommandResult:call(nil, commandWork, 2, PlayerCommand_Type_ToValue[commandName])
        -- log.info(string.format("Input become: %s", tostring(_M.InputCache[commandName])))
    else
        -- log.info("Not in cancel")
        _M.InputCache[commandName] = false
    end

    return _M._CacheInputCanProcess(commandWork, commandName, cancelIndex)
end

function _M.ClearInput(key)
    _M.InputCache[key] = false
end

-- function _M._CacheInputActionPhase(commandWork, commandName, ignorePhase)
--     if ignorePhase and not _M.InputCache[commandName] then
--         local NotWatchCancel = CheckCommandResult:call(nil, commandWork, 2, PlayerCommand_Type_ToValue[commandName])
--         _M.InputCache[commandName] = NotWatchCancel
--         return
--     end

--     _M.Init()
--     local phase = _M.MotionSupporter._BaseBasicMotionSeq._ActionPhase

--     -- log.info(string.format("%x", _M.MotionSupporter._BaseBasicMotionSeq:get_address()))

--     if phase == 0 then
--         _M.InputCache[commandName] = false
--     elseif phase == 1 or phase == 2 then
--         if _M.InputCache[commandName] then
--             return
--         end
    
--         local NotWatchCancel = CheckCommandResult:call(nil, commandWork, 2, PlayerCommand_Type_ToValue[commandName])
--         _M.InputCache[commandName] = NotWatchCancel
--     end
-- end

-- function _M._CacheInputActionPhaseCanProcess(commandWork, commandName, ignorePhase)
--     if ignorePhase then
--         if _M.InputCache[commandName] then
--             _M.InputCache[commandName] = nil
--             return true
--         end
--         return false
--     end

--     _M.Init()
--     local phase = _M.MotionSupporter._BaseBasicMotionSeq._ActionPhase

--     if phase == 2 and _M.InputCache[commandName] then
--         -- _M.InputCache[commandName] = nil
--         return _M.InputCache[commandName]
--     end
--     return false
-- end

-- function _M.InputActionPhase(commandWork, commandName, cancelIndex)
--     _M._CacheInputActionPhase(commandWork, commandName, cancelIndex)
--     return _M._CacheInputActionPhaseCanProcess(commandWork, commandName, cancelIndex)
-- end

return _M