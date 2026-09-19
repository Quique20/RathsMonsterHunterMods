local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local thread = thread
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local require = require
local type = type

local LibConf = require("_CatLib.config")

local SDK = require("_CatLib.sdk")
local Utils = require("_CatLib.utils")
local FontUtils = require("_CatLib.font")
local ModCreator = require("_CatLib.mod")
local Draw = require("_CatLib.draw")
local CONST = require("_CatLib.const")
local CACHE = require("_CatLib.cache")
local D2dUtils = require("_CatLib.d2d")
local LanguageUtils = require("_CatLib.language")

local Game = require("_CatLib.game")
local Singletons = require("_CatLib.game.singletons")
local Player = require("_CatLib.game.player")
local Quest = require("_CatLib.game.quest")
local GameText = require("_CatLib.game.text")
local GameData = require("_CatLib.game.data")

local _M = {}

_M.VERSION = 0.2
function _M.CheckVersion(ver)
    if not ver or type(ver) ~= "number" then return end

    if _M.VERSION < ver then
        re.msg("Your CatLib version is not new enough! Required: " .. tostring(ver) .. ", Current: " .. tostring(_M.VERSION))
    end
end

-------------------------------
-- Utils
-------------------------------

_M.GetTypeIterateFunction = Utils.GetTypeIterateFunction
_M.IsInTable = Utils.IsInTable
_M.ForEach = Utils.ForEach
_M.ForEachBreak = Utils.ForEachBreak
_M.ForEachDict = Utils.ForEachDict
_M.TryGetDict = Utils.TryGetDict
_M.GetEnumMap = Utils.GetEnumMap
_M.EnumToFixed = Utils.EnumToFixed
_M.FixedToEnum = Utils.FixedToEnum
_M.GetTableSize = Utils.GetTableSize
_M.FloatFixed1 = Utils.FloatFixed1
_M.CSharpIntArrayEquals = Utils.CSharpIntArrayEquals
_M.StringStartsWith = Utils.StringStartsWith
_M.StringEndsWith = Utils.StringEndsWith
_M.StringContains = Utils.StringContains

function _M.HookStorage()
    return thread.get_hook_storage()
end

function _M.SetThis(this, key)
    local storage = _M.HookStorage()
    
    if key == nil then
        key = "this"
    end
    storage[key] = this
end

function _M.GetThis(this, key)
    local storage = _M.HookStorage()
    
    if key == nil then
        key = "this"
    end
    local this = storage[key]
    storage[key] = nil
    return this
end

-------------------------------
-- SDK
-------------------------------

_M.SKIP_ORIGINAL = sdk.PreHookResult.SKIP_ORIGINAL

_M.Typedef = SDK.Typedef
_M.WrapTypedef = SDK.WrapTypedef
_M.TypeMethod = SDK.TypeMethod
_M.TypeField = SDK.TypeField
_M.Typeof = SDK.Typeof

_M.Cast = SDK.Cast
_M.CastGUID = SDK.CastGUID

_M.NewWrapValueType = SDK.NewWrapValueType
_M.NewTargetAccessKey = SDK.NewTargetAccessKey
_M.NewActionID = SDK.NewActionID
_M.NewGuid = SDK.NewGuid
_M.FormatGUID = SDK.FormatGUID
_M.Ctor = SDK.Ctor
_M.NativeCtor = SDK.NativeCtor
_M.HookFunc = SDK.HookFunc
_M.DisabledHookFunc = SDK.DisabledHookFunc
_M.DerefPtr = SDK.DerefPtr
_M.OnFrame = SDK.OnFrame

-------------------------------
-- GAME SINGLETONS
-------------------------------

_M.GetSingleton = Game.GetSingleton
_M.GetNativeSingleton = Game.GetNativeSingleton
_M.GetWrapNativeSingleton = Game.GetWrapNativeSingleton
_M.GetChatManager = Game.GetChatManager
_M.GetNpcManager = Game.GetNpcManager
_M.GetOtomoManager = Game.GetOtomoManager
_M.GetPlayerManager = Game.GetPlayerManager
_M.GetPorterManager = Game.GetPorterManager
_M.GetSoundMusicManager = Game.GetSoundMusicManager
_M.GetBattleMusicManager = Game.GetBattleMusicManager
_M.GetMissionManager = Game.GetMissionManager
_M.GetCameraManager = Game.GetCameraManager
_M.GetVariousDataManager = Game.GetVariousDataManager
_M.GetGUIManager = Game.GetGUIManager
_M.GetEnemyManager = Game.GetEnemyManager
_M.GetSaveDataManager = Game.GetSaveDataManager
_M.GetNetworkManager = Game.GetNetworkManager
_M.GetSceneManager = Game.GetSceneManager
_M.NewColor = Game.NewColor

-------------------------------
-- GAME UTILS
-------------------------------

_M.ClearCache = CACHE.ClearCache

_M.GetLanguage = LanguageUtils.GetLanguage
_M.IsChinese = LanguageUtils.IsChinese
_M.GetLocalizedTextConfig = LanguageUtils.GetLocalizedTextConfig

_M.IsInBattle = Player.IsInBattle
_M.IsInTrainingArea = Player.IsInTrainingArea
_M.IsWearMantle = Player.IsWearMantle
_M.GetPlayerInfo = Player.GetInfo
_M.GetPlayerCharacter = Player.GetCharacter
_M.GetPlayerWeapon = Player.GetWeapon
_M.GetPlayerSubWeapon = Player.GetSubWeapon
_M.GetPlayerWeaponType = Player.GetWeaponType
_M.GetPlayerSubWeaponType = Player.GetSubWeaponType
_M.GetPlayerWeaponHandling = Player.GetWeaponHandling
_M.GetPlayerSubWeaponHandling = Player.GetSubWeaponHandling
_M.GetPlayerGameObject = Player.GetGameObject
_M.GetPlayerCatalogHolder = Player.GetPlayerCatalogHolder

_M.IsPlayingQuest = Quest.IsPlaying
_M.IsActiveQuest = Quest.IsActive
_M.IsQuestFinishing = Quest.IsFinishing
_M.GetQuestDirector = Quest.GetQuestDirector
_M.GetQuestTimeLimit = Quest.GetTimeLimit
_M.GetQuestRemainTime = Quest.GetRemainTime
_M.GetQuestElapsedTime = Quest.GetElapsedTime
_M.GetQuestStartedTime = Quest.GetStartedTime

_M.GetLocalizedText = GameText.GetLocalizedText
_M.GetMealSkillName = GameText.GetMealSkillName
_M.GetEnemyName = GameText.GetEnemyName
_M.GetItemName = GameText.GetItemName
_M.GetPartTypeName = GameText.GetPartTypeName
_M.GetMealSkillDescription = GameText.GetMealSkillDescription
_M.GetWeaponTypeName = GameText.GetWeaponTypeName
_M.GetWeaponName = GameText.GetWeaponName
_M.GetArmorName = GameText.GetArmorName
_M.GetSkillByFixed = GameText.GetSkillByFixed
_M.GetFixedBySkill = GameText.GetFixedBySkill
_M.GetSkillName = GameText.GetSkillName
_M.GetASkillName = GameText.GetASkillName
_M.GetMusicSkillName = GameText.GetMusicSkillName
_M.GetActionNameByFixedID = GameText.GetActionNameByFixedID
_M.GetAccessoryName = GameText.GetAccessoryName
_M.GetAccessoryNameMap = GameText.GetAccessoryNameMap

_M.GetAllRandomMealSkills = GameData.GetAllRandomMealSkills
_M.GetAllMealSkills = GameData.GetAllMealSkills
_M.GetEquipSkillMaxLevel = GameData.GetEquipSkillMaxLevel
_M.GetAllArmorSkills = GameData.GetAllArmorSkills
_M.GetAllWeaponSkills = GameData.GetAllWeaponSkills

_M.ToHunterCharacter = Game.ToHunterCharacter
_M.ToOtomoCharacter = Game.ToOtomoCharacter
_M.ToEnemyCharacter = Game.ToEnemyCharacter
_M.GetQuestBossList = Game.GetQuestBossList

---@return via.Scene
function _M.GetCurrentScene()
    return Singletons.GetWrapNativeSingleton("via.SceneManager"):call("get_CurrentScene()")
end

---@return via.Component[]
function _M.FindComponents(typename)
    local scene = _M.GetCurrentScene()
    return scene:call("findComponents(System.Type)", SDK.Typeof(typename))
end

-------------------------------
-- DEV UTIL FUNCS
-------------------------------
_M.GetTime = Utils.GetTime
_M.GetElapsedTimeMs = Utils.GetElapsedTimeMs
_M.GetDeltaTime = Utils.GetDeltaTime
_M.GetTimeString = Utils.GetTimeString
_M.IsValidName = Utils.IsValidName

_M.LoadD2dFont = FontUtils.LoadD2dFont
_M.LoadImguiCJKFont = FontUtils.LoadImguiCJKFont
_M.NewMod = ModCreator.NewMod

_M.LoadFont = Draw.LoadFont
_M.ReverseRGB = Draw.ReverseRGB

_M.GameLoaded = Game.IsLoaded
_M.SendMessage = Game.SendMessage
_M.BuildLongMessage = Game.BuildLongMessage
_M.FinishLongMessage = Game.FinishLongMessage
_M.GetTime = Game.GetTime
_M.D2dRegister = D2dUtils.D2dRegister


local SceneManagerType = _M.Typedef("via.SceneManager")

local ScreenW, ScreenH
---@return number, number w, h
function _M.GetScreenSize()
    if ScreenW and ScreenH then
        return ScreenW, ScreenH
    end

    ---@type via.SceneManager
    local mgr = Singletons.GetSceneManager()
    if not mgr then
        return 1920, 1080
    end

    ---@type via.SceneView
    local view = sdk.call_native_func(mgr, SceneManagerType,  "get_MainView")
    if not view then
        return 1920, 1080
    end

    ---@type via.Size
    local size = view:get_Size()
    if not size then
        return 1920, 1080
    end

    ScreenW, ScreenH = size.w, size.h
    return ScreenW, ScreenH
end

local GameFlowManager_IsLoading = SDK.TypeMethod("app.GameFlowManager", "get_Loading()")
function _M.IsLoading()
    local mgr = Singletons.GetGameFlowManager()
    if not mgr then
        return false
    end
    return GameFlowManager_IsLoading:call(mgr)
end

-------------------------------
-- Game Hooks
-------------------------------

local function OnPlayerReborn(preFunc, postFunc) end

--- called when: game loaded, change equip
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnPlayerChangeEquip(func, postFunc)
    SDK.HookFunc("app.GUIManager", "onPlEquipChange()", func, postFunc)
end

--- called when: accept quest, attack quest
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnAcceptQuest(func, postFunc)
    SDK.HookFunc("app.cQuestDirector", "acceptQuest(app.cActiveQuestData, app.cQuestAcceptArg, System.Boolean, System.Boolean)", func, postFunc)
end

---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnQuestStartEnter(func, postFunc)
    SDK.HookFunc("app.cQuestStart", "enter()", func, postFunc)
end

--- called when: quest playing start
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnQuestStartPlaying(func, postFunc)
    SDK.HookFunc("app.cQuestPlaying", "enter()", func, postFunc)
end
--- called when: quest cleared/return/failed, if cleared, still in quest (free play time)
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnQuestStopPlaying(func, postFunc)
    SDK.HookFunc("app.cQuestPlaying", "exit()", func, postFunc)
end

--- called when: quest cleared/return/failed, reward menu
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnQuestEnd(func, postFunc)
    -- SDK.HookFunc("app.cQuestResult", "clearMapBeaconMissionIcon()", func, postFunc)
    SDK.HookFunc("app.cQuestReward", "enter()", func, postFunc)
end

---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnQuestEnter(func, postFunc)
    SDK.HookFunc("app.cQuestPlaying", "enter()", func, postFunc)
end

---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnMemberJoinQuest(func, postFunc)
    -- 这个传入的 GUID 不是 HunterID
    -- SDK.HookFunc("app.Net_UserInfoManager", "onJoinMember(app.net_session_manager.SESSION_TYPE, System.Int32, System.Boolean, System.Guid)",
    -- func, postFunc)
    SDK.HookFunc("app.PlayerManager", "evNetJoinMember(app.net_session_manager.SESSION_TYPE, System.Int32, System.Boolean, System.Guid)",
    func, postFunc)
end

---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnMemberLeaveQuest(func, postFunc)
    -- 这个传入的 GUID 不是 HunterID
    -- SDK.HookFunc("app.Net_UserInfoManager", "onLeaveMember(app.net_session_manager.SESSION_TYPE, System.Int32, System.Guid)",
    -- func, postFunc)
    SDK.HookFunc("app.PlayerManager", "evNetLeaveMember(app.net_session_manager.SESSION_TYPE, System.Int32, System.Guid)",
    func, postFunc)
end

---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnCreateNPC(func, postFunc)
    SDK.HookFunc("app.cNpcPartnerManageControl", "create(app.cNpcPartnerCreateArg)",
    func, postFunc)
end

---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnRemoveNPC(func, postFunc)
    SDK.HookFunc("app.cNpcPartnerManageControl", "remove(app.cNpcPartnerManageControl.REMOVE_TYPE)",
    func, postFunc)
end

-- function _M.OnMemberJoinQuest_NPC(func, postFunc)
--     SDK.HookFunc("app.NpcManager", "evNetJoinMember(app.net_session_manager.SESSION_TYPE, System.Int32, System.Boolean, System.Guid)",
--     func, postFunc)
-- end

-- function _M.OnMemberLeaveQuest_NPC(func, postFunc)
--     SDK.HookFunc("app.NpcManager", "evNetLeaveMember(app.net_session_manager.SESSION_TYPE, System.Int32, System.Guid)",
--     func, postFunc)
-- end

-- function _M.OnHostChange_NPC(func, postFunc)
--     SDK.HookFunc("app.NpcManager", "evNetHostChange(app.net_session_manager.SESSION_TYPE, System.Int32)",
--     func, postFunc)
-- end

--- called when: (seamless) quest finished (after all gui disappeared, no longer in quest)
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.AfterQuestSuccess(func, postFunc)
    SDK.HookFunc("app.cQuestClearEnd", "enter()", func, postFunc)
end

--- called when: loading
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnLoading(func, postFunc)
    -- 旧函数不能用了
    SDK.HookFunc("app.PlayerManager", "evSceneLoadEnd_FastTravel()", func, postFunc)
end

--- called when: loading end
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.AfterLoading(func, postFunc)
    return _M.OnLoading(func, postFunc)
end

--- called when load save data (not loading)
---@param func HookPreFunc
---@param postFunc HookPostFunc
function _M.OnLoadSave(func, postFunc)
    local post = postFunc
    if postFunc ~= nil then
        post = function (retval)
            local storage = thread.get_hook_storage()
            local type = storage["type"]
            storage["type"] = nil
            if type == 1 then
                return postFunc(retval)
            end
            return retval
        end
    end
    SDK.HookFunc("ace.SaveDataManagerBase", "request(ace.SaveDataManagerBase.cRequest)",
    function (args)
        local type = sdk.to_managed_object(args[3]):get_RqType()
        if type == 1 then
            local storage = thread.get_hook_storage()
            storage["type"] = type
            return func(args)
        end
    end, post)
end

_M.OnLoading(function ()
    CACHE.ClearCache()
end)

-------------------------------
-- Some uncommon Game Utils
-------------------------------

function _M.DisableAimMode()
    local ctrl = CACHE.MasterPlayerController
    if ctrl == nil then
        ctrl = _M.GetPlayerManager():getMasterPlayer():get_Entity()._ControllerEntityHolder:get_Master()
        CACHE.MasterPlayerController = ctrl
    end

    if ctrl then
        ctrl._ToggleAimPad = false
        ctrl._ToggleAimPc = false
        ctrl._ToggleAimShooting = false
    end
end

---@param uniqueId string formated guid string
---@return string
function _M.GetShortHunterIDFromUniqueID(uniqueId)
    local mgr = _M.GetNetworkManager()
    local users = mgr:get_UserInfoManager():getUserInfoList(2)._ListInfo

    log.info(string.format("Requesting ShortID of %s", uniqueId))
    local shortID = ""
    _M.ForEach(users, function (userInfo)
        if not userInfo:get_IsValid() then
            return
        end
        local param = userInfo.param
        local guid = _M.FormatGUID(param.HunterId)
        log.info(string.format("checking %s", guid))
        if guid == uniqueId then
            shortID = userInfo:get_ShortHunterId()
            return _M.ForEachBreak
        end
    end)
    return shortID
end

---@return app.cPorterManageInfo
function _M.GetMasterPorterInfo()
    if CACHE.PorterInfo == nil and _M.GetPorterManager() then
        CACHE.PorterInfo = _M.GetPorterManager():getMasterPlayerPorter()
    end
    return CACHE.PorterInfo
end

function _M.GetMasterPorterCharacter()
    if CACHE.PorterCharacter == nil and _M.GetMasterPorterInfo() then
        CACHE.PorterCharacter = _M.GetMasterPorterInfo():get_Character()
    end
    return CACHE.PorterCharacter
end

-- 获取玩家动作数据（FSM）
local ACTION_ID_TYPE = sdk.find_type_definition("ace.ACTION_ID")

local function _getActionData(character, get_controller_func, controller_name)
    if not character then return end
    local controller = get_controller_func(character)
    if not controller then return end
    local current_action_id = controller:get_CurrentActionID()
    if not current_action_id then return end
    local result = {
        [controller_name] = controller,
        MotionID = sdk.get_native_field(current_action_id, ACTION_ID_TYPE, "_Index"),
        MotionBankID = sdk.get_native_field(current_action_id, ACTION_ID_TYPE, "_Category"),
    }
    return result
end
-- 获取玩家主动作数据（FSM）
function _M.GetPlayerActionData()
    local HunterCharacter = Player.GetCharacter()
    return _getActionData(HunterCharacter, function(char) return char:get_BaseActionController() end, "ActionController")
end
-- 获取玩家副动作数据（FSM）
function _M.GetPlayerSubActionData()
    local HunterCharacter = Player.GetCharacter()
    return _getActionData(HunterCharacter, function(char) return char:get_SubActionController() end, "SubActionController")
end

function _M.GetPlayerMotionData()
    local motion = Player.GetMotion()
    if not motion then return end

    local layer = motion:getLayer(0)
    if not layer then return end

    local nodeCount = layer:getMotionNodeCount()
    local result = {
        Motion = motion,
        Layer = layer,
        MotionID = layer:get_MotionID(),
        MotionBankID = layer:get_MotionBankID(),
        Frame = layer:get_Frame(),
        EndFrame = layer:get_EndFrame(),
        Speed = layer:get_Speed(),
        MotionSpeed = motion:get_PlaySpeed(),

        MotionNodeCount = nodeCount,
        -- MotionNodeCtrl = node,
        -- MotionNodeName = node:get_Name(),
        -- MotionNodeMotionName = node:get_MotionName(),
    }

    
    if nodeCount > 0 then
        local node = layer:call("getMotionNode(System.UInt32)", 0)
        result.MotionNodeCtrl = node
        result.MotionNodeName = node:get_Name()
        result.MotionNodeMotionName = node:get_MotionName()
    end

    return result
end

local function _getCurrentActionName()
    -- 这个很不准，弓箭Base一直在瞄准，Sub才是发射。而且发射还容易变成蓄力，wtf
    local actionController = Player.GetCharacter():get_BaseActionController()
    local currentAction = actionController:get_CurrentAction()
    local guideID = currentAction._ActionGuideID
    if guideID and guideID ~= -1 then
        local name = GameText.GetActionNameByFixedID(guideID)
        -- log.info("GuideID: " .. tostring(guideID))
        if name then
            return name -- .. currentAction:get_type_definition():get_name() -- .. "?" 
        end
    end
    return ""
end

function _M.GetActionGuide()
    if CACHE.ActionGuide == nil then
        CACHE.ActionGuide = Singletons.GetGUIManager():get_ActionGuide()
    end
    return CACHE.ActionGuide
end

function _M.GetCurrentActionName(lang)
    local actionGuide = _M.GetActionGuide()
    if not actionGuide then
        return ""
    end

    -- app.GUI020014.app.GUI020014.updateDispActionGuide(app.ACTION_GUIDE_PL_PARAM, app.ACTION_GUIDE_PL_PARAM, System.Collections.Generic.List`1<app.ACTION_GUIDE_VIEW_PARAM>)

    -- if true then
    --     return _getCurrentActionName()
    -- end
    -- local plParam = CACHE.ActionGuide:getCurrentActionParam()
    local param = actionGuide:get_CurrentActionGuideParam()
    -- local param = CACHE.ActionGuide:get_ActionGuideViewParams()
    -- local id = param.ActionGuideID -- FixedID
    -- log.info(string.format("CurrentActionID: %d", id))

    -- 不是我踏马就搞不懂了
    -- 为什么赤刃斩连段明明有他妈的自己的 ActionGuideID
    -- 你tm就非要用直斩的呢？
    -- 然后唯一的差异是 ActionName，真nb疯了
    -- 然后抽象的来了
    -- 斩斧的三连斩经典复用二连斩动作
    -- 然后有独立的出招表动作名
    -- 但是这里的ActionName还是二连斩
    -- 我草了司马了
    -- if id == -1 then
    --     return _getCurrentActionName()
    -- end

    -- local name = GameText.GetActionNameByID(id)
    -- if name then
    --     return name
    -- end
    local nameGuid = param.ActionName
    -- return GameText.GetActionNameByGUID(nameGuid, id)
    return GameText.GetActionNameByGUID(nameGuid, nil, lang)
end

-------------------------------
-- END --
-------------------------------

return _M
