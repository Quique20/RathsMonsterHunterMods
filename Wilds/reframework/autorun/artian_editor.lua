local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local string = string
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local table = table
local _ = _
local math = math

local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local Imgui = require("_CatLib.imgui")
local Browser = require("_CatLib.equipbox_browser")

local mod = Core.NewMod("Artian Editor")
mod.EnableCJKFont(18) -- if needed

-- 分类选项（下标 0 + 14把武器）
local ArtianCategoryOptions = {
    [0] = "All Weapon Types",
    "Great Sword",
    "Sword & Shield",
    "Dual Blades",
    "Long Sword",
    "Hammer",
    "Hunting Horn",
    "Lance",
    "Gunlance",
    "Switch Axe",
    "Charge Blade",
    "Insect Glaive",
    "Bow",
    "Heavy Bowgun",
    "Light Bowgun",
}

-- 排序选项
local ArtianSortOptions = {
    [0] = "Default (Box Order)",
    "By Weapon Type",
}

-- 浏览器状态
local BrowserState = Browser.NewState()

local PerformanceTypeNames = Core.GetEnumMap("app.ArtianDef.PERFORMANCE_TYPE")
local BonusTypeNames = Core.GetEnumMap("app.ArtianDef.BONUS_ID")

local Get_IsArtianWeapon = Core.TypeMethod("app.ArtianUtil", "isArtianWeapon(app.user_data.WeaponData.cData)")
local Get_PerformanceType = Core.TypeMethod("app.ArtianUtil", "getPerformanceType(app.savedata.cEquipWork)")
local Get_BonusList = Core.TypeMethod("app.ArtianUtil", "getBonusIdList(app.savedata.cEquipWork)")
local Get_PerformanceTypeName = Core.TypeMethod("app.ArtianUtil", "Name(app.ArtianDef.PERFORMANCE_TYPE)")
local Get_BonusTypeName = Core.TypeMethod("app.ArtianUtil", "Name(app.ArtianDef.BONUS_ID)")
local Get_BonusData = Core.TypeMethod("app.ArtianUtil", "Data(app.ArtianDef.BONUS_ID)")

local Get_WeaponData = Core.TypeMethod("app.WeaponUtil", "getWeaponData(app.savedata.cEquipWork)")

local BonusTypeNone = Core.TypeField("app.ArtianDef.BONUS_ID", "INVALID"):get_data()
local BonusTypeMax = Core.TypeField("app.ArtianDef.BONUS_ID", "MAX"):get_data()

local ArtianDataInited = false
local Valid_CreateBonusNames -- 生产加成
local Valid_GrindBonusNames -- 复原加成（词条）
local PerformanceTypeNames_WithAttributeBoost -- 普通机械武器属性词条
local Gogma_PerformanceTypeNames_WithAttributeBoost -- 巨戟武器属性词条

local PerformanceTypes -- 同名属性词条
local PerfType_Gogma_ToNormal -- 巨戟属性词条映射到普通属性词条
local PerfType_Normal_ToGogma -- 普通属性词条映射到巨戟属性词条

local Valid_SeriesSkillsNames -- 系列技能
local Valid_GroupSkillsNames -- 组合技能

local Valid_SeriesSkill_Data -- 选定系列技能后，合法的组合技能
local Valid_GroupSkill_Data -- 选定组合技能后，合法的系列技能
local Valid_ASkillType_ToSkillData -- 选定 Index 后，指定的技能

-- FreeVal1 中存储武器ID（app.WeaponDef.TachiId），来自于 sdk.get_managed_singleton("app.VariousDataManager")._Setting._EquipDatas._WeaponTachi 里对应的 _Tachi 字段
-- 不同的巨戟龙激化类型是不同的武器 ID，暂时没找到本地化字符串在哪

local Gogma_Attack = 0
local Gogma_Affinity = 1
local Gogma_Attribute = 2

local Gogma_Localization = {
    [CONST.LanguageType.English] = {
        [Gogma_Attack] = "Attack Focus",
        [Gogma_Affinity] = "Affinity Focus",
        [Gogma_Attribute] = "Attribute Focus",
    },
    [CONST.LanguageType.TraditionalChinese] = {
        [Gogma_Attack] = "攻擊激化",
        [Gogma_Affinity] = "會心激化",
        [Gogma_Attribute] = "屬性激化",
    },
    [CONST.LanguageType.SimplifiedChinese] = {
        [Gogma_Attack] = "攻击激化",
        [Gogma_Affinity] = "会心激化",
        [Gogma_Attribute] = "属性激化",
    },
}

local GogmaName
local Valid_Gogma_TypeToWeaponID = {} -- 合法的激化类型，类型 -> ID
local Valid_Gogma_WeaponIDToType = {} -- 合法的激化类型，ID -> 类型

local Valid_ArtianWeapons = {} -- 所有合法的机械武器 ID

local function GetGogmaWeapons()
    local mgr = Core.GetVariousDataManager()
    if not mgr then
        return
    end

    local data = mgr._Setting._EquipDatas

    local DuplicateNameData = {}

    local WeaponTypeMap = {
        ["Bow"] = CONST.WeaponType.Bow,
        ["ChargeAxe"] = CONST.WeaponType.ChargeBlade,
        ["GunLance"] = CONST.WeaponType.Gunlance,
        ["Hammer"] = CONST.WeaponType.Hammer,
        ["HeavyBowgun"] = CONST.WeaponType.HeavyBowgun,
        ["Lance"] = CONST.WeaponType.Lance,
        ["LightBowgun"] = CONST.WeaponType.LightBowgun,
        ["LongSword"] = CONST.WeaponType.GreatSword,
        ["Rod"] = CONST.WeaponType.InsectGlaive,
        ["ShortSword"] = CONST.WeaponType.SwordShield,
        ["SlashAxe"] = CONST.WeaponType.SwitchAxe,
        ["Tachi"] = CONST.WeaponType.LongSword,
        ["TwinSword"] = CONST.WeaponType.DualBlades,
        ["Whistle"] = CONST.WeaponType.HuntingHorn,
    }

    local function RecordGogmaWeapon(key, data)
        local name = Core.GetLocalizedText(data._Name)
        local id = data[string.format("_%s", key)]
        id = Core.FixedToEnum(string.format("app.WeaponDef.%sId", key), id)
        -- log.info(string.format("[%d] %s: Atk: %d, Crit: %d, Attr: %d", id, name, data._Attack, data._Critical, data._AttributeValue))

        local wpType = WeaponTypeMap[key]
        if not Valid_Gogma_TypeToWeaponID[wpType] then
            Valid_Gogma_TypeToWeaponID[wpType] = {}
            Valid_Gogma_WeaponIDToType[wpType] = {}
        end

        local FocusTypeText = Core.GetLocalizedTextConfig(Gogma_Localization)
        
        local critical = data._Critical
        if critical == 0 then
            Valid_Gogma_TypeToWeaponID[wpType][Gogma_Attribute] = id
            Valid_Gogma_WeaponIDToType[wpType][id] = Gogma_Attribute

            name = name .. " · " .. FocusTypeText[Gogma_Attribute]
        elseif critical > 0 then
            Valid_Gogma_TypeToWeaponID[wpType][Gogma_Affinity] = id
            Valid_Gogma_WeaponIDToType[wpType][id] = Gogma_Affinity

            name = name .. " · " .. FocusTypeText[Gogma_Affinity]
        elseif critical < 0 then
            Valid_Gogma_TypeToWeaponID[wpType][Gogma_Attack] = id
            Valid_Gogma_WeaponIDToType[wpType][id] = Gogma_Attack

            name = name .. " · " .. FocusTypeText[Gogma_Attack]
        end
        
        Valid_ArtianWeapons[wpType][id] = name
    end

    local function DumpData(key)
        local table = data[string.format("_Weapon%s", key)]
        if not table then
            return
        end

        local wpType = WeaponTypeMap[key]
        if not Valid_ArtianWeapons[wpType] then
            Valid_ArtianWeapons[wpType] = {}
        end


        if not DuplicateNameData[key] then
            DuplicateNameData[key] = {}
        end

        local dupName = ""

        Core.ForEach(table._Values, function (data)
            local name = Core.GetLocalizedText(data._Name)
            local id = data[string.format("_%s", key)]
            id = Core.FixedToEnum(string.format("app.WeaponDef.%sId", key), id)

            if Get_IsArtianWeapon:call(nil, data) then
                Valid_ArtianWeapons[wpType][id] = name
            end

            if not DuplicateNameData[key][name] then
                DuplicateNameData[key][name] = data
            else
                dupName = name

                RecordGogmaWeapon(key, data)
            end
        end)

        if dupName ~= "" then
            local data = DuplicateNameData[key][dupName]
            RecordGogmaWeapon(key, data)            
        end
    end

    local keys = {
        "Bow",
        "ChargeAxe",
        "GunLance",
        "Hammer",
        "HeavyBowgun",
        "Lance",
        "LightBowgun",
        "LongSword",
        "Rod",
        "ShortSword",
        "SlashAxe",
        "Tachi",
        "TwinSword",
        "Whistle",
    }


    for _, key in pairs(keys) do
        DumpData(key)
    end
end

local function InitArtianNames()
    if ArtianDataInited then
        return
    end
    -- log.info("Init Artian Names")
    GetGogmaWeapons()
    Valid_CreateBonusNames = {
        [1] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 1)),
        [2] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 2))
    }
    Valid_GrindBonusNames = {
        [0] = Core.GetLocalizedText(Get_BonusTypeName:call(nil, 0)),
    }

    -- log.info("Init Artian Bonus Names")
    -- 4 是基础攻击力强化1，巨戟龙版本截止 16（会心EX）
    for bonusId = 4, BonusTypeMax, 1 do
        local name = Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonusId))

        local fixedBonusId = Core.EnumToFixed("app.ArtianDef.BONUS_ID", bonusId)
        local bonusName = Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonusId))

        if not Core.IsValidName(bonusName) then
            break
        end

        Valid_GrindBonusNames[bonusId] = bonusName
    end
    
    -- log.info("Init Artian Perf Names")
    PerformanceTypeNames_WithAttributeBoost = {}
    Gogma_PerformanceTypeNames_WithAttributeBoost = {}
    
    PerformanceTypes = {}
    GogmaName = Core.GetEnemyName(12) -- Em78 = 12

    local mgr = Core.GetVariousDataManager()
    local perf = mgr._Setting._EquipDatas._ArtianDataSetting._PerformanceData

    Core.ForEach(perf._Values, function (data, i)
        local idx = data._Index
        local perfType = data:get_PerformanceType()
        local bonus = data:get_BonusId()
        local name =  Core.GetLocalizedText(data._Name)
        if bonus > 0 then
            name = string.format("%s · %s", name, Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonus)))
        end
        local rawName = name

        local isGogma = idx >= 19 and idx <= 37

        if isGogma then
        -- if math.abs(data._PerformanceType._Value) < 99999 then
            name = string.format("[%s] %s", GogmaName, name)
        end
        if mod.Config.Debug then
            -- name = string.format("(%d)[%d](%d) %s", i, idx, perfType, name)
            name = string.format("[%d] %s [%d]", idx, name, data._PerformanceType._Value)
        end

        if isGogma then
            Gogma_PerformanceTypeNames_WithAttributeBoost[perfType] = name
        else
            PerformanceTypeNames_WithAttributeBoost[perfType] = name
        end

        if not PerformanceTypes[rawName] then
            PerformanceTypes[rawName] = {}
        end
        if isGogma then
            PerformanceTypes[rawName].Gogma = perfType
            mod.info("Gogma %s = %d", name, perfType)
        else
            PerformanceTypes[rawName].Normal = perfType
            mod.info("Normal %s = %d", name, perfType)
        end
    end)

    PerfType_Gogma_ToNormal = {}
    PerfType_Normal_ToGogma = {}

    for name, data in pairs(PerformanceTypes) do
        if data.Gogma and data.Normal then
            PerfType_Gogma_ToNormal[data.Gogma] = data.Normal
            PerfType_Normal_ToGogma[data.Normal] = data.Gogma
        end
    end

    -- log.info("Init Skill Names")
    -- 技能数据
    Valid_SeriesSkillsNames = {}
    Valid_GroupSkillsNames = {}
    Valid_SeriesSkill_Data = {}
    Valid_GroupSkill_Data = {}
    Valid_ASkillType_ToSkillData = {}

    local skillData = mgr._Setting._EquipDatas._ArtianDataSetting._ArtianSkillGroup._Values
    Core.ForEach(skillData, function (data)
        local idx = data._Index
        local series = data:get_SeriesSkillId()
        local group = data:get_GroupSkillId()
        local aSkillType = data:get_ArtianSkillType()

        Valid_SeriesSkillsNames[series] = Core.GetSkillName(series)
        Valid_GroupSkillsNames[group] = Core.GetSkillName(group)

        if not Valid_SeriesSkill_Data[series] then
            Valid_SeriesSkill_Data[series] = {}
        end
        Valid_SeriesSkill_Data[series][group] = aSkillType

        if not Valid_GroupSkill_Data[group] then
            Valid_GroupSkill_Data[group] = {}
        end
        Valid_GroupSkill_Data[group][series] = aSkillType

        Valid_ASkillType_ToSkillData[aSkillType] = {
            Series = series,
            Group = group,
        }

        -- log.info(string.format("Index: %d, ASkillType_Fixed: %d, Series: %d (%s), Group: %d (%s)", idx, aSkillType, series, Valid_SeriesSkillsNames[series], group, Valid_GroupSkillsNames[group]))
    end)

    -- log.info("Inited")
    ArtianDataInited = true
end

---@param work app.savedata.cEquipWork
local function ArtianWeaponEditor(work, i)
    local category = work:get_Category()
    if category ~= 1 then
        return
    end
    if work.BonusByCreating <= 0 then
        return
    end

    local FocusTypeText = Core.GetLocalizedTextConfig(Gogma_Localization)

    local configChanged = false
    local changed = false

    local wpType = work.FreeVal0
    local wpID = work.FreeVal1
    local wpData = Get_WeaponData:call(nil, work)
    local wpName = Core.GetLocalizedText(wpData._Name)
    local perfType = Get_PerformanceType:call(nil, work)

    local IsGogmaWeapon = Valid_Gogma_WeaponIDToType[wpType][wpID]

    local perfName = PerformanceTypeNames_WithAttributeBoost[perfType]
    if IsGogmaWeapon then
        perfName = Gogma_PerformanceTypeNames_WithAttributeBoost[perfType]
    end
    if not perfName then
        -- Auto fix wrong perf type
        perfName = string.format("%d WRONG ELEMENT TYPE", perfType)

        if IsGogmaWeapon then
            if PerfType_Normal_ToGogma[perfType] then
                perfType = PerfType_Normal_ToGogma[perfType]
                work.FreeVal2 = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
            end
        else
            if PerfType_Gogma_ToNormal[perfType] then
                perfType = PerfType_Gogma_ToNormal[perfType]
                work.FreeVal2 = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
            end
        end
    end

    imgui.push_id(string.format("WpIndex%d", i))
    local open = imgui.tree_node(string.format("%s##WpIndex%d", wpName, i))
    imgui.same_line()

    local focusText = ""
    if Valid_Gogma_WeaponIDToType[wpType] and Valid_Gogma_WeaponIDToType[wpType][wpID] then
        local focusType = Valid_Gogma_WeaponIDToType[wpType][wpID]
        focusText = " · " ..  FocusTypeText[focusType]
    end
    imgui.text("· " .. perfName .. focusText)
    if open then
        if mod.Config.Debug then
            imgui.text(string.format("Weapon %d", i))
            imgui.text(string.format("wpType %d", wpType))
            imgui.text(string.format("wpID %d", wpID))
            local fixedPerfType = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
            imgui.text(string.format("%s: %d (%d)", perfName, perfType, fixedPerfType))
        end

        local newWpID = wpID
        changed, newWpID = imgui.combo("Weapon", wpID, Valid_ArtianWeapons[wpType])
        if changed then
            local oldIsGogmaWeapon = Valid_Gogma_WeaponIDToType[wpType][wpID] ~= nil
            local newIsGogmaWeapon = Valid_Gogma_WeaponIDToType[wpType][newWpID] ~= nil
            work.FreeVal1 = newWpID
            Browser.MarkEdited(BrowserState, i, wpName)

            if not oldIsGogmaWeapon and newIsGogmaWeapon then
                -- 变成巨戟武器
                work.BonusByCreating = work.BonusByCreating + 10
                work.FreeVal5 = 1

                -- patch 属性类型
                if PerfType_Normal_ToGogma[perfType] then
                    perfType = PerfType_Normal_ToGogma[perfType]
                    work.FreeVal2 = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
                end
            elseif oldIsGogmaWeapon and not newIsGogmaWeapon then
                -- 变回普通机械武器
                work.FreeVal5 = 0
                
                -- patch 属性类型
                if PerfType_Gogma_ToNormal[perfType] then
                    perfType = PerfType_Gogma_ToNormal[perfType]
                    work.FreeVal2 = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
                end
            end

            wpID = newWpID
            configChanged = true
        end

        if IsGogmaWeapon then
            changed, perfType = imgui.combo("Element Type", perfType, Gogma_PerformanceTypeNames_WithAttributeBoost)
            if changed then
                work.FreeVal2 = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
                Browser.MarkEdited(BrowserState, i, wpName)
            end
        else
            changed, perfType = imgui.combo("Element Type", perfType, PerformanceTypeNames_WithAttributeBoost)
            if changed then
                work.FreeVal2 = Core.EnumToFixed("app.ArtianDef.PERFORMANCE_TYPE", perfType)
                Browser.MarkEdited(BrowserState, i, wpName)
            end
        end

        IsGogmaWeapon = Valid_Gogma_WeaponIDToType[wpType][wpID]

        -- TODO: 激化类型。但是找不到配置表和本地化数据
        if IsGogmaWeapon then
            if Valid_Gogma_WeaponIDToType[wpType] and Valid_Gogma_WeaponIDToType[wpType][wpID] then
                local focusType = Valid_Gogma_WeaponIDToType[wpType][wpID]

                changed, focusType = imgui.combo("Focus Type", focusType, FocusTypeText)
                if changed then
                    work.FreeVal1 = Valid_Gogma_TypeToWeaponID[wpType][focusType]
                    Browser.MarkEdited(BrowserState, i, wpName)
                end
            elseif mod.Config.Debug then
                imgui.text(string.format("A: %s", tostring(Valid_Gogma_WeaponIDToType[wpType])))
                if Valid_Gogma_WeaponIDToType[wpType] then
                    imgui.text(string.format("B: %s", tostring(Valid_Gogma_WeaponIDToType[wpType][wpID])))
                end
            end
        end

        Imgui.Rect(function ()
            -- 生产加成（属性强化、基础攻击力增强）
            imgui.text("Production Bonus")
            local bonusData = work.BonusByCreating

            if mod.Config.Debug then
                imgui.text(string.format("value: %d", bonusData))
            end

            local first = bonusData % 1000
            local second = math.floor(bonusData/1000) % 1000
            local third = math.floor(bonusData/1000000) % 1000

            -- 之前的版本： 001 001 001
            -- 现在的版本： 011 081 091
            -- 多出来的合起来是 ASkillType
            local aSkillType_Fixed = 0
            if IsGogmaWeapon then
                local asFirst = math.floor(first/10) % 10
                local asSecond = math.floor(second/10) % 10
                local asThird = math.floor(third/10) % 10
                aSkillType_Fixed = asThird * 100 + asSecond * 10 + asFirst
            end

            if aSkillType_Fixed > 0 then
                if mod.Config.Debug then
                    imgui.text(string.format("Index: %d", aSkillType_Fixed))
                end

                local skillData = Valid_ASkillType_ToSkillData[aSkillType_Fixed]
                if mod.Config.Debug then
                    if skillData then
                        imgui.text(string.format("Series: %d %s", skillData.Series, Valid_SeriesSkillsNames[skillData.Series]))
                        imgui.text(string.format("Group: %d %s", skillData.Group, Valid_GroupSkillsNames[skillData.Group]))
                    else
                        imgui.text("No skill data")
                    end
                end

                local group = skillData.Group
                local series = skillData.Series

                local asChanged = false
                changed, group = imgui.combo("Group Skill##CreateGroupSkill", group, Valid_GroupSkillsNames)
                asChanged = asChanged or changed

                changed, series = imgui.combo("Series Skill##CreateSeriesSkill", series, Valid_SeriesSkillsNames)
                asChanged = asChanged or changed

                imgui.text()

                if not Valid_SeriesSkill_Data[series] then
                    imgui.text_colored(string.format(
                        "Warning: Skill `%s` is invalid",
                        Valid_GroupSkillsNames[series]
                    ),Core.ReverseRGB(0xffff8000))
                end
                if not Valid_GroupSkill_Data[group] then
                    imgui.text_colored(string.format(
                        "Warning: Skill `%s` is invalid",
                        Valid_GroupSkillsNames[group]
                    ),Core.ReverseRGB(0xffff8000))
                end
                if not Valid_SeriesSkill_Data[series][group] then
                    imgui.text_colored(string.format(
                        "Warning: Skill `%s` + `%s` is invalid",
                        Valid_GroupSkillsNames[group], Valid_GroupSkillsNames[series]
                    ), Core.ReverseRGB(0xffff8000))
                end

                if asChanged then
                    if Valid_SeriesSkill_Data[series] and Valid_SeriesSkill_Data[series] and Valid_SeriesSkill_Data[series][group] then
                        configChanged = true
                        aSkillType_Fixed = Valid_SeriesSkill_Data[series][group]
                    end
                end
            end

            -- 生产加成只看个位数
            first = first % 10
            second = second % 10
            third = third % 10

            first = Core.FixedToEnum("app.ArtianDef.BONUS_ID", first)
            second = Core.FixedToEnum("app.ArtianDef.BONUS_ID", second)
            third = Core.FixedToEnum("app.ArtianDef.BONUS_ID", third)

            changed, first = imgui.combo("Bonus I##CreateFirst", first, Valid_CreateBonusNames)
            configChanged = configChanged or changed

            changed, second = imgui.combo("Bonus II##CreateSecond", second, Valid_CreateBonusNames)
            configChanged = configChanged or changed

            changed, third = imgui.combo("Bonus III##CreateThird", third, Valid_CreateBonusNames)
            configChanged = configChanged or changed

            if configChanged then
                -- 技能计算
                local asResult = 0
                local asFirst = aSkillType_Fixed % 10
                local asSecond = math.floor(aSkillType_Fixed/10) % 10
                local asThird = math.floor(aSkillType_Fixed/100) % 10

                local result = 0

                -- 基础加成计算
                first = Core.EnumToFixed("app.ArtianDef.BONUS_ID", first) + asFirst * 10
                second = Core.EnumToFixed("app.ArtianDef.BONUS_ID", second) + asSecond * 10
                third = Core.EnumToFixed("app.ArtianDef.BONUS_ID", third) + asThird * 10

                result = third
                result = result * 1000 + second
                result = result * 1000 + first
                work.BonusByCreating = result
                Browser.MarkEdited(BrowserState, i, wpName)
            end
        end)

        Imgui.Rect(function ()
            configChanged = false
            -- 复原强化词条加成（I II III EX）
            imgui.text("Reinforcement Bonus")
            local bonusData = work.BonusByGrinding

            if mod.Config.Debug then
                imgui.text(string.format("value: %d", bonusData))
            end

            local first = bonusData % 1000

            bonusData = math.floor(bonusData/1000)
            local second = bonusData % 1000

            bonusData = math.floor(bonusData/1000)
            local third = bonusData % 1000

            bonusData = math.floor(bonusData/1000)
            local fourth = bonusData % 1000

            bonusData = math.floor(bonusData/1000)
            local fifth = bonusData % 1000

            first = Core.FixedToEnum("app.ArtianDef.BONUS_ID", first)
            second = Core.FixedToEnum("app.ArtianDef.BONUS_ID", second)
            third = Core.FixedToEnum("app.ArtianDef.BONUS_ID", third)
            fourth = Core.FixedToEnum("app.ArtianDef.BONUS_ID", fourth)
            fifth = Core.FixedToEnum("app.ArtianDef.BONUS_ID", fifth)

            changed, first = imgui.combo("First Bonus##GrindFirst", first, Valid_GrindBonusNames)
            configChanged = configChanged or changed

            changed, second = imgui.combo("Second Bonus##GrindSecond", second, Valid_GrindBonusNames)
            configChanged = configChanged or changed

            changed, third = imgui.combo("Third Bonus##GrindThird", third, Valid_GrindBonusNames)
            configChanged = configChanged or changed

            changed, fourth = imgui.combo("Fourth Bonus##GrindFourth", fourth, Valid_GrindBonusNames)
            configChanged = configChanged or changed

            changed, fifth = imgui.combo("Fifth Bonus##GrindFifth", fifth, Valid_GrindBonusNames)
            configChanged = configChanged or changed

            -- 重复词条的有效性检测
            -- bonus count validation
            local bonus_list = {first, second, third, fourth, fifth}
            local bonus_id_count = {}
            for _, bonus_id in ipairs(bonus_list) do
                local b_data = Get_BonusData:call(nil, bonus_id)
                if b_data then
                    bonus_id_count[bonus_id] = (bonus_id_count[bonus_id] or 0) + 1
                else
                    log.warn("Invalid bonus id: ", bonus_id)
                end
            end
            for bonus_id, count in pairs(bonus_id_count) do
                local b_data = Get_BonusData:call(nil, bonus_id)
                local maxCount = b_data._GrindingMaxNum
                if bonus_id > 7 then
                    maxCount = b_data._Em0078_GrindingMaxNum

                    -- 数据里都是5，但是程序实现上似乎会通过 SubProbability 来限制为同词条最多2个
                    maxCount = 2
                end

                if mod.Config.Debug then
                    imgui.text(string.format("%s: %d/%d", Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonus_id)), count, maxCount))
                end

                if count > maxCount then
                    imgui.text_colored(string.format(
                        "Warning: Bonus `%s` has exceeded\n  the max count of grinding.\nThe max count is %d, but current count is %d.",
                        Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonus_id)), maxCount, count),
                        Core.ReverseRGB(0xffff8000))
                end
            end

            if configChanged then
                local result = 0

                first = Core.EnumToFixed("app.ArtianDef.BONUS_ID", first)
                second = Core.EnumToFixed("app.ArtianDef.BONUS_ID", second)
                third = Core.EnumToFixed("app.ArtianDef.BONUS_ID", third)
                fourth = Core.EnumToFixed("app.ArtianDef.BONUS_ID", fourth)
                fifth = Core.EnumToFixed("app.ArtianDef.BONUS_ID", fifth)

                local num = 0

                -- we assign the value directly because if we have values like 11011
                -- which is invalid in vanilla game but possible with Editor
                -- in this situation, we count num=4 but the game reads only 1011
                -- so the fifth bonus is ignored
                if first > 0 then
                    num = 1
                end
                if second > 0 then
                    num = 2
                end
                if third > 0 then
                    num = 3
                end
                if fourth > 0 then
                    num = 4
                end
                if fifth > 0 then
                    num = 5
                end

                result = fifth
                result = result * 1000 + fourth
                result = result * 1000 + third
                result = result * 1000 + second
                result = result * 1000 + first
                work.BonusByGrinding = result
                work.GrindingNum = num
                Browser.MarkEdited(BrowserState, i, wpName)
            end
        end)

        if mod.Config.Debug then
            local bonusList = Get_BonusList:call(nil, work)
            Core.ForEach(bonusList, function(bonusId)
                local fixedBonusId = Core.EnumToFixed("app.ArtianDef.BONUS_ID", bonusId)
                local bonusName = Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonusId))

                imgui.text(string.format("  %s: %d (%d)", bonusName, bonusId, fixedBonusId))
            end)
        end

        imgui.tree_pop()
    end
    imgui.pop_id()
end


local SaveData = nil
local EquipBox = nil
mod.HookFunc("app.SaveDataManager", "update()", function (args)
    if SaveData ~= nil then
        return
    end
    local this = Core.Cast(args[2])
    SaveData = this:getCurrentUserSaveData()
    EquipBox = SaveData._Equip._EquipBox
end)

local function EquipBoxEditor()
    -- local mgr = Core.GetVariousDataManager()
    -- if not mgr then
    --     return
    -- end

    -- local data = mgr._Setting._EquipDatas
    -- sdk.get_managed_singleton("app.SaveDataManager"):getCurrentUserSaveData():get_Equip()._EquipBox:get_Item(98)

    if not EquipBox then
        return
    end

    -- local mgr = Core.GetSaveDataManager()
    -- if not mgr then
    --     return false
    -- end
    InitArtianNames()

    -- 新列表逻辑
    -- local box = mgr:getCurrentUserSaveData()._Equip._EquipBox

    local tbChanged = Browser.Toolbar(BrowserState, {
        search = true,
        category = ArtianCategoryOptions,
        sort = ArtianSortOptions,
    })
    if tbChanged then
        -- 调整筛选时不跳回最近编辑的条目
        BrowserState.ScrollToIdx = nil
    end

    -- 收集全部机械武器条目
    local entries = {}
    local count = EquipBox:get_Count()
    for j = 0, count - 1 do
        local work = EquipBox:get_Item(j)
        if work then
            local category = work:get_Category()
            if category == 1 and work.BonusByCreating > 0 then
                local wpData = Get_WeaponData:call(nil, work)
                local wpName = Core.GetLocalizedText(wpData._Name)
                -- 同步最近编辑条目的最新名字（改名后保持显示正确）
                if BrowserState.LastEditedIdx == j then
                    BrowserState.LastEditedName = wpName
                end
                entries[#entries + 1] = {
                    idx = j,
                    work = work,
                    name = wpName,
                    cat = work.FreeVal0,
                }
            end
        end
    end

    -- 过滤 + 排序
    local filtered = Browser.Filter(BrowserState, entries, function(k) return k - 1 end)

    -- 最近编辑信息条（放在空结果判断之前，保证始终可见）
    Browser.EditedBar(BrowserState, filtered)

    if #filtered == 0 then
        imgui.text("No matching artian weapons")
        return
    end

    imgui.text(string.format("Showing %d / %d artian weapons", #filtered, #entries))
    if #filtered > 500 then
        imgui.text_colored("Too many results. Use search or category to narrow down.", Core.ReverseRGB(0xffff8000))
    end

    local listOpen = imgui.tree_node(string.format("EquipBox (%d)", count))
    imgui.same_line()
    imgui.text(string.format("artian: %d, shown: %d", #entries, #filtered))
    if listOpen then
        for _, e in ipairs(filtered) do
            Browser.BeginScroll(BrowserState, e.idx)
            ArtianWeaponEditor(e.work, e.idx)
        end
        imgui.tree_pop()
    end
end

mod.Menu(function()
    -- if mod.Config.Debug then
    --     for bonusId = BonusTypeNone+1, BonusTypeMax, 1 do
    --         local name = Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonusId))

    --         local fixedBonusId = Core.EnumToFixed("app.ArtianDef.BONUS_ID", bonusId)
    --         local bonusName = Core.GetLocalizedText(Get_BonusTypeName:call(nil, bonusId))

    --         if bonusName and bonusId and fixedBonusId then
    --             imgui.text(string.format("  %s: %d (%d)", bonusName, bonusId, fixedBonusId))
    --         else
    --             imgui.text(string.format("[ERROR]  %s: %s (%s)", tostring(bonusName), tostring(bonusId), tostring(fixedBonusId)))
    --         end
    --     end
    -- end

    EquipBoxEditor()
end)
