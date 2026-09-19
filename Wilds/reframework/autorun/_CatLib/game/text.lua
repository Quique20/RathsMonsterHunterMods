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
local type = type

local Singletons = require("_CatLib.game.singletons")
local Utils = require("_CatLib.utils")
local CONST = require("_CatLib.const")
local LibConf = require("_CatLib.config")

local _M = {}

_M.MEAL_SKILL_INITED = false
---@type table<app.MealDef.SKILL, string>
_M.MEAL_SKILL_NAMES = {}
---@type table<app.MealDef.SKILL, string>
_M.MEAL_SKILL_DESC = {}
---@type table<app.EnemyDef.ID, string>
_M.ENEMY_NAMES = {}
---@type table<app.ItemDef.ID, string>
_M.ITEM_NAMES = {}
---@type table<via.Language, table<integer, string>>
_M.LANG_ACTION_NAMES = {}
---@type table<app.WeaponDef.TYPE, string>
_M.WEAPON_TYPE_NAMES = {}
---@type table<app.HunterDef.Skill, string>
_M.SKILL_NAMES = {}
---@type table<app.HunterDef.ACTIVE_SKILL, string>
_M.ASKILL_NAMES = {}
---@type table<app.Wp05Def.WP05_MUSIC_SKILL_TYPE, string>
_M.MUSIC_SKILL_NAMES = {}
---@type table<app.OtomoDef.MUSIC_SKILL_TYPE, string>
_M.OTOMO_MUSIC_SKILL_NAMES = {}
---@type table<app.EquipDef.ACCESSORY_ID, string>
_M.ACC_NAMES = {}

_M.ENEMY_PARTS_NAME_INITED = false
---@type table<app.EnemyDef.PARTS_TYPE, string>
_M.ENEMY_PARTS_NAMES = {}

local GetMsgFunc = sdk.find_type_definition("via.gui.message"):get_method("get(System.Guid)")
local GetMsgWithLanguageFunc = sdk.find_type_definition("via.gui.message"):get_method("get(System.Guid, via.Language)")

-- unlimited cache size = mem leak since guid is a valuetype
---@param guid System.Guid
---@return string
function _M.GetLocalizedText(guid, lang)
    if not guid then return "[EMPTY_GUID]" end
    -- if LIB_CACHE.LOCALIZED_TEXT == nil then
    --     LIB_CACHE.LOCALIZED_TEXT = {}
    -- end

    -- if LIB_CACHE.LOCALIZED_TEXT[guid] then
    --     return LIB_CACHE.LOCALIZED_TEXT[guid]
    -- end
    if lang and lang >= 0 then
        return GetMsgWithLanguageFunc:call(nil, guid, lang)
    end

    if LibConf.LanguageOverride then
        return GetMsgWithLanguageFunc:call(nil, guid, LibConf.Language)
    end

    return GetMsgFunc:call(nil, guid)
end

local GetMealSkillNameFunc = sdk.find_type_definition("app.MessageUtil"):get_method("getMealSkillName(app.MealDef.SKILL)")
---@param id app.MealDef.SKILL
---@return string
function _M.GetMealSkillName(id)
    if not id or id < 0 then return "[INVALID_MEAL_SKILL]" end

    local name = _M.MEAL_SKILL_NAMES[id]
    if name == nil then
        if _M.MEAL_SKILL_INITED then
            return "[UNKNOWN_MEAL_SKILL]"
        end

        local guid = GetMealSkillNameFunc:call(nil, id)
        name = _M.GetLocalizedText(guid)
        _M.MEAL_SKILL_NAMES[id] = name
    end

    return name
end

---@return table<app.MealDef.SKILL, string>
function _M.GetMealNames()
    if _M.MEAL_SKILL_INITED then
        return _M.MEAL_SKILL_NAMES
    end
    
    local mgr = Singletons.GetVariousDataManager()
    if mgr == nil then return end

    -- app.user_data.MealSkillData.cData[]
    local dataset = mgr._Setting._FacilitySetting._FacilityDiningSetting._MealSkill._Values

    Utils.ForEach(dataset,
    ---@param data app.user_data.MealSkillData.cData
    function (data)
        if data == nil then return end
        local skill = data:get_MealSkill()
        local name =  _M.GetMealSkillName(skill)
        if not Utils.IsValidName(name) then
            return
        end
        _M.MEAL_SKILL_NAMES[skill] = name

        local descGuid = data:get_Explain()
        _M.MEAL_SKILL_DESC[skill] = _M.GetLocalizedText(descGuid)
    end)

    _M.MEAL_SKILL_INITED = true
    return _M.MEAL_SKILL_NAMES
end

---@param id app.MealDef.SKILL
---@return string
function _M.GetMealSkillDescription(id)
    if not id or id < 0 then return "[INVALID_MEAL_SKILL]" end

    local name = _M.MEAL_SKILL_DESC[id]
    if name == nil then
        if _M.MEAL_SKILL_INITED then
            return "[UNKNOWN_MEAL_SKILL]"
        end

        _M.GetMealNames()
        name = _M.MEAL_SKILL_DESC[id]
        if name == nil then
            return "[UNKNOWN_MEAL_SKILL]"
        end
    end

    return name
end


local GetEnemyNameFunc = sdk.find_type_definition("app.EnemyDef"):get_method("EnemyName(app.EnemyDef.ID)")
---@param id app.EnemyDef.ID
---@return string
function _M.GetEnemyName(id)
    if not id or id < 0 then return "[INVALID_ENEMY_ID]" end

    local name = _M.ENEMY_NAMES[id]
    if name == nil then
        local guid = GetEnemyNameFunc:call(nil, id)
        name = _M.GetLocalizedText(guid)
        _M.ENEMY_NAMES[id] = name
    end

    return name
end

local GetItemNameFunc = sdk.find_type_definition("app.ItemDef"):get_method("RawName(app.ItemDef.ID)")
---@param id app.ItemDef.ID
---@return string
function _M.GetItemName(id, lang)
    if not id or id < 0 then return "[INVALID_ITEM_ID]" end

    if lang then
        local guid = GetItemNameFunc:call(nil, id)
        return _M.GetLocalizedText(guid, lang)
    end

    local name = _M.ITEM_NAMES[id]
    if name == nil then
        local guid = GetItemNameFunc:call(nil, id)
        name = _M.GetLocalizedText(guid)
        _M.ITEM_NAMES[id] = name
    end

    return name
end

-- local EnemyFixedPartsToPartType = sdk.find_type_definition("app.EnemyDef"):get_field("FixedToPARTS_TYPE"):get_data()
---@param type app.EnemyDef.PARTS_TYPE
function _M.GetPartTypeName(type)
    if not _M.ENEMY_PARTS_NAME_INITED then
        local mgr = Singletons.GetVariousDataManager()
        if mgr == nil then return end
    
        ---@type app.user_data.EnemyPartsTypeData.cData[]
        local dataset = mgr._Setting._EnemyPartsTypeData._Values
    
        -- local keys = EnemyFixedPartsToPartType:get_Keys()

        Utils.ForEach(dataset,
        ---@param data app.user_data.EnemyPartsTypeData.cData
        function (data)
            if data == nil then return end
            local t_fixed = data._EmPartsType
            local t = Utils.FixedToEnum("app.EnemyDef.PARTS_TYPE", t_fixed) -- Utils.TryGetDict(EnemyFixedPartsToPartType, t_fixed)
            if t ~= nil then
                local name =  _M.GetLocalizedText(data._EmPartsName)
                if not name or name == "" then
                    _M.ENEMY_PARTS_NAMES[t] = CONST.EnemyPartsTypeNames[t]
                else
                    _M.ENEMY_PARTS_NAMES[t] = name
                end
                -- log.info(tostring(t) .. "=" .. tostring(_M.ENEMY_PARTS_NAMES[t]))
            else
                log.info(tostring(t_fixed) .. " not in dict")
            end
        end)
    
        _M.ENEMY_PARTS_NAME_INITED = true
    end

    return _M.ENEMY_PARTS_NAMES[type]
end

local ActionNameByIDInited = false
local LangActionNameByIDInited = {}

---@type table<integer, string>
_M.ACTION_NAMES_BY_FIXEDID = {}

local function InitActionNameByID(lang)
    if lang == nil and ActionNameByIDInited then
        return
    end
    ActionNameByIDInited = true

    if lang and lang >= 0 then
        if LangActionNameByIDInited[lang] then
            return
        end
        LangActionNameByIDInited[lang] = true
        if _M.LANG_ACTION_NAMES[lang] == nil then
            _M.LANG_ACTION_NAMES[lang] = {}
        end
    end

    local mgr = Singletons.GetVariousDataManager()
    if mgr == nil then return end
    local dataset = mgr._Setting._ActionGuideSetting

    local type = sdk.find_type_definition("app.ActionGuideID")
    for i = 0, 13, 1 do
        local key = string.format("_ActionGuideName_Wp%02d", i)
        local data = dataset[key]
        local values = data:getValues()

        -- local dictKey = string.format("FixedToWP%02d", i)
        -- local FixedToID = type:get_field(dictKey):get_data()
        Utils.ForEach(values, function (cData)
            local actionFixedID = cData._Action
            -- local id = Utils.TryGetDict(FixedToID, actionFixedID)
            -- if id ~= nil then
            --     _M.ACTION_NAMES[id] = _M.GetLocalizedText(cData._ActionName)
            --     log.info(string.format("WP %d, ID %d(%d) -> %s", i, id, actionFixedID, _M.ACTION_NAMES[id]))
            -- end
            _M.ACTION_NAMES_BY_FIXEDID[actionFixedID] = _M.GetLocalizedText(cData._ActionName, lang)
            if lang and lang >= 0 then
                _M.LANG_ACTION_NAMES[lang][actionFixedID] = _M.ACTION_NAMES_BY_FIXEDID[actionFixedID]
            end
            -- log.info(string.format("WP %d, ID (%d) -> %s (%s)", i, actionFixedID, _M.ACTION_NAMES[actionFixedID], _M.GetLocalizedText(cData._ActionName, CONST.LanguageType.English)))
        end)
    end
end

---@param id integer
---@return string|nil
function _M.GetActionNameByFixedID(id, lang)
    if id == -1 then
        return ""
    end
    InitActionNameByID(lang)
    if lang and lang >= 0 then
        return _M.LANG_ACTION_NAMES[lang][id] or ""
    end
    return _M.ACTION_NAMES_BY_FIXEDID[id] or ""
end

---@param guid System.Guid
---@param id integer
---@return string|nil
function _M.GetActionNameByGUID(guid, id, lang)
    if id == -1 then
        return ""
    end
    if not id then
        return _M.GetLocalizedText(guid, lang)
    end
    if lang and lang >= 0 then
        if _M.LANG_ACTION_NAMES[lang] == nil then
            _M.LANG_ACTION_NAMES[lang] = {}
        end
        _M.LANG_ACTION_NAMES[lang][id] = _M.GetLocalizedText(guid, lang)
        return _M.LANG_ACTION_NAMES[lang][id]
    else
        _M.ACTION_NAMES_BY_FIXEDID[id] = _M.GetLocalizedText(guid, lang)
        return _M.ACTION_NAMES_BY_FIXEDID[id]
    end
end

local GetSkillNameFunc = sdk.find_type_definition("app.MessageUtil"):get_method("getHunterSkillName(app.HunterDef.Skill)")
local GetLeveledSkillNameFunc = sdk.find_type_definition("app.MessageUtil"):get_method("getHunterSkillNameChatLog(app.HunterDef.Skill, System.Int32)")
local GetWeaponTypeNameGuidFunc = sdk.find_type_definition("app.WeaponUtil"):get_method("getWeaponTypeName(app.WeaponDef.TYPE)")
---@param guid app.WeaponDef.TYPE
---@return string
function _M.GetWeaponTypeName(type)
    if _M.WEAPON_TYPE_NAMES[type] then
        return _M.WEAPON_TYPE_NAMES[type]
    end

    local guid = GetWeaponTypeNameGuidFunc:call(nil, type)
    local name = _M.GetLocalizedText(guid)
    _M.WEAPON_TYPE_NAMES[type] = name
    return name
end

---@type table<app.user_data.WeaponData.cData, string>
_M.WEAPON_NAMES = {}
local GetWeaponNameFunc = sdk.find_type_definition("app.WeaponUtil"):get_method("getWeaponName(app.user_data.WeaponData.cData)")
---@param data app.user_data.WeaponData.cData
---@return string
function _M.GetWeaponName(data)
    if _M.WEAPON_NAMES[data] then
        return _M.WEAPON_NAMES[data]
    end

    local guid = GetWeaponNameFunc:call(nil, data)
    local name = _M.GetLocalizedText(guid)
    _M.WEAPON_NAMES[data] = name
    return name
end

---@type table<app.user_data.ArmorData.cData, string>
_M.ARMOR_NAMES = {}
---@param data app.user_data.ArmorData.cData
---@return string
function _M.GetArmorName(data)
    if _M.ARMOR_NAMES[data] then
        return _M.ARMOR_NAMES[data]
    end

    local name = _M.GetLocalizedText(data._Name)
    _M.ARMOR_NAMES[data] = name
    return name
end

-- local SkillFixedToSkill = sdk.find_type_definition("app.HunterDef"):get_field("FixedToSkill"):get_data()
local SkillIdMax = sdk.find_type_definition("app.HunterDef.Skill"):get_field("MAX"):get_data()

local SkillFixedToSkillMap = {}
local SkillToSkillFixedMap = {}
local SkillFixedToSkillMapInited = false

local function InitSkillFixedToSkillMap()
    if SkillFixedToSkillMapInited then
        return
    end
    SkillFixedToSkillMapInited = true
   
    for id = 0, SkillIdMax do
        local fixed = Utils.EnumToFixed("app.HunterDef.Skill", id)
        SkillFixedToSkillMap[fixed] = id
        SkillToSkillFixedMap[id] = fixed
    end

    -- Utils.ForEachDict(SkillFixedToSkill, function (fixed, id)
    --     if id >= SkillIdMax then
    --         return
    --     end
    --     SkillFixedToSkillMap[fixed] = id
    --     SkillToSkillFixedMap[id] = fixed
    -- end)
end

---@param app.HunterDef.Skill_Fixed
function _M.GetSkillByFixed(fixed)
    InitSkillFixedToSkillMap()

    return SkillFixedToSkillMap[fixed]
end

---@param app.HunterDef.Skill
function _M.GetFixedBySkill(skill)
    InitSkillFixedToSkillMap()

    return SkillToSkillFixedMap[skill]
end
local SkillEnumNames = Utils.GetEnumMap("app.HunterDef.Skill")
local SkillIDNone = sdk.find_type_definition("app.HunterDef.Skill"):get_field("MAX"):get_data()
local SkillIDMax = sdk.find_type_definition("app.HunterDef.Skill"):get_field("MAX"):get_data()

local SkillToGroupSkillDict = sdk.find_type_definition("app.HunterSkillDef"):get_field("SkillToGroupSkill"):get_data()

---@type table<app.HunterDef.Skill, table<integer, string>>
local SkillDataMap = {}
local SkillDataExplainMap = {}
local SkillDataMapInited = false

local function InitSkillDataMap()
    if SkillDataMapInited then
        return
    end
    SkillDataMapInited = true

    if false then
        Utils.ForEachDict(SkillToGroupSkillDict, function (k, v)
            log.info(string.format("SkillToGroupSkillDict [%d: %s] => %d: %s", k, SkillEnumNames[k], v, SkillEnumNames[v]))
        end)
    
        local function _log_skill(skill, lv)
            local guid
            if lv then
                guid = GetLeveledSkillNameFunc:call(nil, skill, lv)
            else
                guid = GetSkillNameFunc:call(nil, skill)
            end
            local name = _M.GetLocalizedText(guid)
            local lvText = ""
            if lv then
                lvText = string.format("Lv%d", lv)
            end
            log.info(string.format("_log_skill [%d%s] %s", skill, lvText, name))
        end
        _log_skill(168)
        _log_skill(168, 1)
        _log_skill(168, 2)
        _log_skill(168, 3)
        _log_skill(168, 4)
        _log_skill(199)
        _log_skill(199, 1)
        _log_skill(199, 2)
        _log_skill(199, 3)
        _log_skill(199, 4)
        
        for id, enumName in pairs(SkillEnumNames) do
            if id ~= SkillIDNone and id ~= SkillIDMax then
                local name = _M.GetLocalizedText(GetSkillNameFunc:call(nil, id))
                log.info(string.format("%d [%s]: %s", id, enumName, name))
            end
        end
    end

    -- 初始化套装技能映射
    -- 对于套装技能，例如辟兽之力（186），它实际生效的 Skill 为 152（大力士）
    -- 然而，大力士这个技能并不像昏厥耐性那样有自己单独的本地化文本
    -- 而是根据辟兽之力的等级分为 【大力士 I】和【大力士 II】
    -- 因此需要做出映射

    local mgr = Singletons.GetVariousDataManager()
    if mgr == nil then return end
    local dataset = mgr._Setting._SkillData._Values

    log.info("Initing SkillDataMap")
    Utils.ForEach(dataset,
    ---@param data app.user_data.SkillData.cData
    function (data)
        local mapName = _M.GetLocalizedText(data._skillName)
        if not mapName or mapName == "" then
            return
        end
        local skillId = data:get_skillId()
        -- log.info(string.format("Init skill id: [%d:%s] to %s", skillId, SkillEnumNames[skillId], mapName))
        local mismatch = {}
        local openSkillLength = data._openSkill:get_Count()
        Utils.ForEach(data._openSkill, function (fixedSkill)
            local skill = Utils.FixedToEnum("app.HunterDef.Skill", fixedSkill)
            if skill ~= nil then
                if skill <= 0 then
                    return
                end
                local name =  _M.GetLocalizedText(GetSkillNameFunc:call(nil, skill))
                if not name or name == "" then
                    table.insert(mismatch, skill)
                end
                -- log.info(string.format("[%d] Open Skill [%s]: [%d:%s]", skillId, tostring(name), skill, SkillEnumNames[skill]))
            else
                log.info(tostring(fixedSkill) .. " not in dict")
            end
        end)

        if #mismatch > 0 then
            -- log.info("mismatched: " .. tostring(#mismatch))
            local lv = data._SkillLv
            for _, skill in pairs(mismatch) do
                if SkillDataMap[skill] and SkillDataMap[skill][lv] then
                    -- log.error(string.format("duplicated skill data map: skill %d at lv %d, have %s, want to write: %s", skill, lv, mapName, SkillDataMap[skill][lv]))
                end
                if SkillDataMap[skill] == nil then
                    SkillDataMap[skill] = {}
                    SkillDataExplainMap[skill] = {}
                end
                SkillDataMap[skill][lv] = mapName
                SkillDataExplainMap[skill][lv] = _M.GetLocalizedText(data._skillExplain)
                -- log.info(string.format("skill data map: skill %d at lv %d, map as: %s", skill, lv, mapName, SkillDataMap[skill][lv]))
            end
        end
    end)
end

local SkillToGroupSkillFunc = sdk.find_type_definition("app.HunterSkillDef"):get_method("convertSkillToGroupSkill(app.HunterDef.Skill)")
local GetSkillDataFunc = sdk.find_type_definition("app.HunterDef"):get_method("SkillData(app.HunterDef.Skill)")

local SkillToGroupSkillMap = {}

local function _getSkillName(skill, lv)
    if not skill or skill < 0 then
        return "[INVALID_SKILL_NAME]"
    end
    if skill >= SkillIdMax then
        return
    end
    if skill == 0 then
        return "NONE"
    end
    local name = _M.SKILL_NAMES[skill]
    if name ~= nil then
       return _M.SKILL_NAMES[skill] 
    end

    local converted = SkillToGroupSkillFunc:call(nil, skill)
    if converted > 0 then
        skill = converted
    end

    local guid
    if lv then
        guid = GetLeveledSkillNameFunc:call(nil, skill, lv)
        name = _M.GetLocalizedText(guid)
        if Utils.StringContains(name, "Rejected") or name == "－－－－－－" then
            guid = GetSkillNameFunc:call(nil, skill)
        else
            return name
        end
    else
        guid = GetSkillNameFunc:call(nil, skill)
    end
    
    -- local cData = GetSkillDataFunc:call(nil, skill)._SkillCommonData
    -- if not cData then
    --     _M.SKILL_NAMES[skill] = "NO_CDATA"
    --     return _M.SKILL_NAMES[skill]
    -- end
    -- local guid = cData._skillName
    name = _M.GetLocalizedText(guid)
    _M.SKILL_NAMES[skill] = name
    -- log.info(string.format("skill enum to name: skill %d: %s", skill, name))
    return name
end

local AllSkillNames = {}
local AllSkillNamesInited = false
function _M.GetAllSkillNames()
    if AllSkillNamesInited then
        return AllSkillNames
    end
    AllSkillNamesInited = true

    InitSkillFixedToSkillMap()

    for _, skill in pairs(SkillFixedToSkillMap) do
        log.info(string.format("[%s] %d", SkillEnumNames[skill], skill))
        AllSkillNames[skill] = _getSkillName(skill)
        log.info(string.format("[%s] %d: %s", SkillEnumNames[skill], skill, AllSkillNames[skill]))
    end
    
    return AllSkillNames
end

-- mod.HookFunc("app.cHunterSkillParamInfo", "beginSkillLog(app.HunterDef.Skill)",
-- function (args)
--     local id = sdk.to_int64(args[3])
--     Core.SendMessage("Start Skill %d", id)
-- end)

-- mod.HookFunc("app.MessageUtil", "getHunterSkillNameChatLog(app.HunterDef.Skill, System.Int32)",
-- function (args)
--     local id = sdk.to_int64(args[3])
--     local lv = sdk.to_int64(args[4])
--     Core.SendMessage("Skill Name %d lv %d", id, lv)
-- end)

local CacheSkillName = {}
local CacheLeveledSkillName = {}

function _M.GetSkillName(skill, lv)
    -- 技能名存在两张表里
    -- SkillCommon 里有珠子的技能名（如纳刀术），和套装的技能名（如XXX之力），该表没有技能等级，以及套装技能的实际生效技能（SkillCommonXXXX）。
    -- 可以通过 SkillToGroupSkillFunc 来将实际生效技能转为套装技能
    -- 另一张表 SkillData 里有套装的生效技能名（如【大力士 I】和【大力士 II】）该表有技能等级
    -- _M.GetAllSkillNames()
    InitSkillDataMap()
    -- InitSkillDataMap()
    -- local name = ""
    if lv then
        if CacheLeveledSkillName[skill] == nil then
            CacheLeveledSkillName[skill] = {}
        end
        local name = CacheLeveledSkillName[skill][lv]
        if not name then
            name = _getSkillName(skill, lv)
            CacheLeveledSkillName[skill][lv] = name
        end
        return name
    else
        local name = CacheSkillName[skill]
        if not name then
            name = _getSkillName(skill)
            CacheSkillName[skill] = name
        end
        return name
    end
    -- local name = _getSkillName(skill, lv)
    -- if name == "" then 
    --     if lv ~= nil then
    --         InitSkillDataMap()
    --         if SkillDataMap[skill] and SkillDataMap[skill][lv] then
    --             return SkillDataMap[skill][lv]
    --         end
    --         if SkillToGroupSkillMap[skill] == nil then
    --             SkillToGroupSkillMap[skill] = SkillToGroupSkillFunc:call(nil, skill)
    --         end
    --         if SkillToGroupSkillMap[skill] > 0 then
    --             local name = _getSkillName(SkillToGroupSkillMap[skill])
    --             if name and name ~= "" then
    --                 return name
    --             end
    --         end
    --         return _getSkillName(skill, lv)
    --     else
    --         if SkillToGroupSkillMap[skill] == nil then
    --             SkillToGroupSkillMap[skill] = SkillToGroupSkillFunc:call(nil, skill)
    --         end
    --         if SkillToGroupSkillMap[skill] > 0 then
    --             return _getSkillName(SkillToGroupSkillMap[skill])
    --         end
    --     end
    -- end
    -- return name
end

-- 孩子们，不要问我为什么不是 get_method("ItemId(app.HunterDef.ACTIVE_SKILL)")，它返回空
local GetASkillItemIDFunc = sdk.find_type_definition("app.HunterDef"):get_method("getItemIDFromActiveSkill(app.HunterDef.ACTIVE_SKILL)")
function _M.GetASkillName(askill)
    if _M.ASKILL_NAMES[askill] then
       return _M.ASKILL_NAMES[askill] 
    end
    local itemID = GetASkillItemIDFunc:call(nil, askill)
    _M.ASKILL_NAMES[askill] = _M.GetItemName(itemID)
    return _M.ASKILL_NAMES[askill]
end

local GetMusicSkillNameGuidFunc = sdk.find_type_definition("app.Wp05Def"):get_method("MusicSkillName(app.Wp05Def.WP05_MUSIC_SKILL_TYPE)")
function _M.GetMusicSkillName(music)
    if _M.MUSIC_SKILL_NAMES[music] then
       return _M.MUSIC_SKILL_NAMES[music] 
    end
    local guid = GetMusicSkillNameGuidFunc:call(nil, music)
    _M.MUSIC_SKILL_NAMES[music] = _M.GetLocalizedText(guid)
    return _M.MUSIC_SKILL_NAMES[music]
end

-- local GetOtomoSkillNameGuidFunc = sdk.find_type_definition("app.Wp05Def"):get_method("MusicSkillName(app.Wp05Def.WP05_MUSIC_SKILL_TYPE)")
function _M.GetOtomoSkillName(music)
    if true then
        return 
    end
    -- if _M.OTOMO_MUSIC_SKILL_NAMES[music] then
    --    return _M.OTOMO_MUSIC_SKILL_NAMES[music] 
    -- end
    -- local guid = GetOtomoSkillNameGuidFunc:call(nil, music)
    -- _M.OTOMO_MUSIC_SKILL_NAMES[music] = _M.GetLocalizedText(guid)
    -- return _M.OTOMO_MUSIC_SKILL_NAMES[music]
end

local GetAccessoryNameFunc = sdk.find_type_definition("app.EquipDef"):get_method("Name(app.EquipDef.ACCESSORY_ID)")
---@param id app.EquipDef.ACCESSORY_ID
---@return string
function _M.GetAccessoryName(id)
    if not id or id < 0 then return "[INVALID_ACC_ID]" end

    local name = _M.ACC_NAMES[id]
    if name == nil then
        local guid = GetAccessoryNameFunc:call(nil, id)
        name = _M.GetLocalizedText(guid)
        _M.ACC_NAMES[id] = name
    end

    return name
end

local AccessoryNameMapInited = false
local function InitAccessoryNameMap()
    if AccessoryNameMapInited then
        return _M.ACC_NAMES
    end

    local start = sdk.find_type_definition("app.EquipDef.ACCESSORY_ID"):get_field("ACC_ID_0000"):get_data()
    local max = sdk.find_type_definition("app.EquipDef.ACCESSORY_ID"):get_field("MAX"):get_data()
    
    for i = start, max - 1 do
        _M.GetAccessoryName(i)
    end

    AccessoryNameMapInited = true
end

function _M.GetAccessoryNameMap()
    InitAccessoryNameMap()
    local data = {}
    for id, name in pairs(_M.ACC_NAMES) do
        if Utils.IsValidName(name) then
            data[id] = name
        end
    end

    return data
end

return _M