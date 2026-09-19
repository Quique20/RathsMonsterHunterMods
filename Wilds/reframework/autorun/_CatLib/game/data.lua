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
local GameText = require("_CatLib.game.text")
local Utils = require("_CatLib.utils")

local _M = {}

---@type table<app.MealDef.SKILL, string>
_M.RandomMealSkills = nil

-- returns Dict<SkillID: int, Name: string> ->
function _M.GetAllRandomMealSkills()
    if _M.RandomMealSkills ~= nil then
        return _M.RandomMealSkills
    end

    local mgr = Singletons.GetVariousDataManager()
    if mgr == nil then return end

    -- app.user_data.MealSkillRandomTable.cData[]
    local randomTable = mgr._Setting._FacilitySetting._FacilityDiningSetting._MealSkillRandomTable._Values
    local skills = {}

    Utils.ForEach(randomTable,
    ---@param data app.user_data.MealSkillData.cData
    function (data)
        if data == nil then return end
        local skill = data:get_MealSkill()
        local name = GameText.GetMealSkillName(skill)
        if not Utils.IsValidName(name) then
            return
        end
        skills[skill] = name
    end)

    _M.RandomMealSkills = skills
    return skills
end

function _M.GetAllMealSkills()
    return GameText.GetMealNames()
end

---@class EquipSkillData
---@field SkillId number
---@field FixedSkillId number
---@field Index number
---@field MaxLevel number
---@field Category number

---@class LeveledSkillData
---@field SkillId number
---@field SkillLevel number
---@field Index number
---@field Name string

---@class EquipSkillDataHolder
---@field SkillIdMap table<app.HunterDef.Skill, EquipSkillData>
---@field FixedSkillIdMap table<app.HunterDef.Skill_Fixed, EquipSkillData>
---@field SkillIndexMap table<number, LeveledSkillData>
---@field CategorySkillMap table<app.HunterDef.SkillCategory, EquipSkillData[]>
---@field CategorySkillNames table<app.HunterDef.SkillCategory, table<app.HunterDef.Skill, string>>

---@type EquipSkillDataHolder
local EquipSkillsData = {}
local EquipSkillsDataInited = false

local function InitEquipSkillsData()
    if EquipSkillsDataInited then
        return
    end
    local mgr = Singletons.GetVariousDataManager()
    if mgr == nil then return end

    EquipSkillsData.SkillIdMap = {}
    EquipSkillsData.FixedSkillIdMap = {}
    EquipSkillsData.SkillIndexMap = {}
    EquipSkillsData.CategorySkillMap = {}
    EquipSkillsData.CategorySkillNames = {}

    local array = mgr:get_field("<_EquipDataHolder>k__BackingField")._EquipSkillDataArray
    Utils.ForEach(array,
    ---@param equipSkillData app.EquipDef.EquipSkillData
    function (equipSkillData, i)
        if equipSkillData._SkillMaxLv <= 0 then
            return
        end
        
        local id = equipSkillData._Skill
        local data = {
            SkillId = id,
            MaxLevel = equipSkillData._SkillMaxLv,
            Category = equipSkillData._SkillCategory,
        }

        local commonData = equipSkillData._SkillCommonData
        if commonData then
            data.Index = commonData._Index
            data.FixedSkillId = commonData._skillId
            data.Name = GameText.GetLocalizedText(commonData._skillName)
        end

        Utils.ForEach(equipSkillData._SkillLevelDataList,
        ---@param cData app.user_data.SkillData.cData
        function (cData)
            EquipSkillsData.SkillIndexMap[cData._Index] = {
                SkillId = id,
                SkillLevel = cData._SkillLv,
                Index = cData._Index,
                Name = GameText.GetLocalizedText(cData._skillName)
            }
        end)

        EquipSkillsData.SkillIdMap[id] = data
        if data.Index then
            EquipSkillsData.FixedSkillIdMap[data.Index] = {
                SkillId = id,
                SkillLevel = 0,
                Index = data.Index,
                Name = data.Name
            }
        end
        if data.FixedSkillId then
            EquipSkillsData.FixedSkillIdMap[data.FixedSkillId] = data
        end
        if EquipSkillsData.CategorySkillMap[data.Category] == nil then
            EquipSkillsData.CategorySkillMap[data.Category] = {}
        end
        table.insert(EquipSkillsData.CategorySkillMap[data.Category], data)

        if EquipSkillsData.CategorySkillNames[data.Category] == nil then
            EquipSkillsData.CategorySkillNames[data.Category] = {}
            EquipSkillsData.CategorySkillNames[data.Category][0] = "NONE"
        end
        if data.Name and data.Name ~= "" then
            EquipSkillsData.CategorySkillNames[data.Category][id] = data.Name
        end

        -- log.info(string.format("Init Skill %d (%s), index %s, max lv: %d", id, tostring(data.Name), tostring(data.Index), data.MaxLevel))
    end)

    EquipSkillsDataInited = true
end

---@param skill app.HunterDef.Skill
function _M.GetEquipSkillMaxLevel(skill)
    InitEquipSkillsData()
    if EquipSkillsData.SkillIdMap[skill] then
        return EquipSkillsData.SkillIdMap[skill].MaxLevel
    end
    return 0
end

local WeaponSkills = {}
local ArmorSkills = {}
local SkillMaxLevel = {}
local WeaponArmorSkillsInited = false
local function InitWeaponArmorSkills()
    if WeaponArmorSkillsInited then
        return
    end

    local mgr = Singletons.GetVariousDataManager()
    if mgr == nil then return end

    local array = mgr._Setting._SkillCommonData._Values
    Utils.ForEach(array,
    ---@param CommonData app.user_data.SkillCommonData.cData
    function (CommonData)
        local id = GameText.GetSkillByFixed(CommonData._skillId)
        if not id or id <= 0 then
            return
        end
        local name = GameText.GetLocalizedText(CommonData._skillName)
        if not Utils.IsValidName(name) then
            return
        end
        local category = CommonData._skillCategory
        -- 0 equip, 1 series, 2 group
        -- 3 weapon, 4 meal
        if category == 3 then
            WeaponSkills[id] = name
            -- log.info(string.format("weapon skill enum to name: skill %d: %s", id, name))
        elseif category < 3 then
            ArmorSkills[id] = name
            -- log.info(string.format("armor skill enum to name: skill %d: %s", id, name))
        end
    end)

    WeaponSkills[0] = "NONE"
    ArmorSkills[0] = "NONE"

    WeaponArmorSkillsInited = true
end

function _M.GetAllWeaponSkills()
    InitWeaponArmorSkills()
    return WeaponSkills;
end

function _M.GetAllArmorSkills()
    InitWeaponArmorSkills()
    return ArmorSkills;
    -- InitEquipSkillsData()
    -- return EquipSkillsData.CategorySkillNames[0]
    -- return GameText.GetAllSkillNames()
end

return _M