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

local function Tooltip(msg)
    imgui.same_line()
    imgui.text("(?)")
    if imgui.is_item_hovered() then
        imgui.set_tooltip(msg.."\n")
    end
end

local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local Imgui = require("_CatLib.imgui")
local Browser = require("_CatLib.equipbox_browser")

local mod = Core.NewMod("Charm Editor")
mod.EnableCJKFont(18) -- if needed

-- 稀有度分类选项
local CharmCategoryOptions = {
    [0] = "All Rarities",
    "Rarity 5",
    "Rarity 6",
    "Rarity 7",
    "Rarity 8",
}

-- 排序选项
local CharmSortOptions = {
    [0] = "Default (Box Order)",
    "By Rarity",
}

-- 浏览器状态
local BrowserState = Browser.NewState()

-- 技能筛选下拉（按首个技能词条检索）
-- CharmSkillOptions[k] = CharmSkillList[k] = 技能名，下标一致，供 Filter 比对
local CharmSkillOptions = nil
local CharmSkillList = nil

-- 技能名规范化：去掉等级后缀（攻击Lv1/攻击Lv2 -> 攻击），用于下拉去重与筛选匹配
local function NormalizeSkillName(name)
    if not name then
        return nil
    end
    local n = string.gsub(name, "%s*[Ll][Vv]%d+%s*$", "")
    n = string.gsub(n, "%s+$", "")
    if n == "" then
        return nil
    end
    return n
end

local Get_AmuletData = Core.TypeMethod("app.AmuletUtil", "getAmuletData(app.savedata.cEquipWork)")

local RandomDataInited = false

-- 护石类型[]
local Valid_AmuletTypes
local Valid_AmuletTypeNames
-- 护石类型（R5-R8）-> 分数表格[]
local Valid_AmuletTypeDataTable

-- 技能点数 -> 技能表格[]
local Valid_SkillPointsTable
-- 技能存档值（Lv+SkillID）-> 技能表格。暂时没用。
local Valid_SkillSaveDataTable
-- 技能存档值（Lv+SkillID）-> 技能名
local Valid_SkillSaveDataNames
-- 技能存档值（Lv+SkillID）-> 技能点数类型。用于初始化类型表格
local Valid_SkillSaveDataToPoints
-- 表格中存在多个相同技能存档值的情形（例如强四射击Lv2）。用于正确初始化类型表格。
local Valid_SkillSaveDataToPoints_Multiple
-- 技能点数 -> 技能存档值（Lv+SkillID）-> 技能名
local Valid_SkillPoint_ToSaveDataNames

-- 孔位点数 -> 孔位表格[]
local Valid_SlotPointsTable
-- 孔位存档值 -> 孔位表格。暂时没用。
local Valid_SlotSaveDataTable
-- 孔位存档值 -> 孔位名
local Valid_SlotSaveDataNames
-- 孔位存档值 -> 孔位点数类型。用于初始化类型表格
local Valid_SlotSaveDataToPoints
-- 孔位点数 -> 孔位存档值 -> 孔位名
local Valid_SlotPoints_ToSaveDataNames

-- 从分数表格[]中获取合法的参数列表。后面四位参数为过滤器，nil为不过滤，非nil为过滤
local function GetCurrentValidPointsList(list, skill1, skill2, skill3, slot)
    if not list then
        return nil
    end
    local filtered = {
        Skill1List = {},
        Skill2List = {},
        Skill3List = {},
        SlotList = {},
        Combination = {},
    }

    for _, data in pairs(list) do
        if skill1 ~= nil and data.SkillPoint1 ~= skill1 then
            goto continue
        end
        if skill2 ~= nil and data.SkillPoint2 ~= skill2 then
            goto continue
        end
        if skill3 ~= nil and data.SkillPoint3 ~= skill3 then
            goto continue
        end
        if slot ~= nil and data.SlotPoint ~= slot then
            goto continue
        end

        filtered.Skill1List[data.SkillPoint1] = tostring(data.SkillPoint1)
        filtered.Skill2List[data.SkillPoint2] = tostring(data.SkillPoint2)
        filtered.Skill3List[data.SkillPoint3] = tostring(data.SkillPoint3)
        filtered.SlotList[data.SlotPoint] = tostring(data.SlotPoint)
        table.insert(filtered.Combination, data)

        ::continue::
    end

    return filtered
end

-- 当某个技能出现在多个池子里时（例如强四射击Lv2，出现在2分池子和4分池子），multiplePoints = [2, 4]
-- 选择合法组合的 validPoints 里出现过的那个
local function PickValidSkillPointIfInMultipleRandomPool(multiplePoints, validPoints, preferredPoint)
    local validMap = {}
    for _, v in pairs(validPoints) do
        validMap[v] = true
        if mod.Config.Debug then
            imgui.text(string.format("%d (%s) is valid", v, tostring(type(v))))
        end
    end

    if preferredPoint ~= nil then
        if validMap[preferredPoint] or validMap[tostring(preferredPoint)] then
            if mod.Config.Debug then
                imgui.text(string.format("prefer %d (%s)", preferredPoint, tostring(type(preferredPoint))))
            end
            return preferredPoint
        end
    end

    for _, p in pairs(multiplePoints) do
        if mod.Config.Debug then
            imgui.text(string.format("finding %d (%s)", p, tostring(type(p))))
        end
        if validMap[tostring(p)] then
            if mod.Config.Debug then
                imgui.text("found at " .. tostring(p))
            end
            return p
        end
    end
    return nil
end

local function InitRandomCharmData()
    if RandomDataInited then
        return
    end
    local mgr = Core.GetVariousDataManager()
    if not mgr then
        return
    end
    local settings = mgr._Setting
    
    local CUSTOM_AMULET_NAMES = {
        [189] = "Rarity 5",
        [190] = "Rarity 6",
        [191] = "Rarity 7",
        [192] = "Rarity 8",
    }

    -- 合法的点数组合，三个技能点数+一个孔位点数
    Valid_AmuletTypeDataTable = {}
    Valid_AmuletTypes = {}
    Valid_AmuletTypeNames = {}
    local ptTable = settings._RandomAmuletPtTable
    Core.ForEach(ptTable._Values, function (data)
        local amuletType = Core.FixedToEnum("app.ArmorDef.AmuletType", data._AmuletType._Value)
        table.insert(Valid_AmuletTypes, amuletType)

        if CUSTOM_AMULET_NAMES[amuletType] then
            Valid_AmuletTypeNames[amuletType] = CUSTOM_AMULET_NAMES[amuletType]
        -- else
        --     Valid_AmuletTypeNames[amuletType] = "Unknown Amulet Type " .. tostring(amuletType)
        -- -- 不应该让用户能编辑奇怪的东西
        end

        if not Valid_AmuletTypeDataTable[amuletType] then
            Valid_AmuletTypeDataTable[amuletType] = {}
        end

        table.insert(Valid_AmuletTypeDataTable[amuletType], {
            Index = data._Index,
            AmuletType = amuletType,
            SkillPoint1 = data._SkillPt_01,
            SkillPoint2 = data._SkillPt_02,
            SkillPoint3 = data._SkillPt_03,
            SlotPoint = data._SlotPt,
        })
    end)
    
    -- 合法的技能组合
    Valid_SkillPointsTable = {}
    Valid_SkillSaveDataTable = {}
    Valid_SkillSaveDataNames = {}
    Valid_SkillSaveDataNames[0] = "NONE"
    Valid_SkillSaveDataToPoints = {}
    Valid_SkillSaveDataToPoints_Multiple = {}
    local skills = settings._RandomAmuletLotSkillTable
    Core.ForEach(skills._Values, function (data, i)
        if not Valid_SkillPointsTable[data._SkillPt] then
            Valid_SkillPointsTable[data._SkillPt] = {}
        end
        
        local skillEnumValue = Core.FixedToEnum("app.HunterDef.Skill", data._SkillType)
        local skillData = {
            Index = data._Index,
            SkillPoint = data._SkillPt,
            -- LotType 可选值有2个，但是目前全是1，暂时不知道是干嘛的
            LotSkillType = Core.FixedToEnum("app.EquipDef.RANDOM_AMULET_LOTSKILL_TYPE", data._LotSkillType),
            SkillType = skillEnumValue,
            SkillLevel = data._SkillLv,
        }
        local saveValue = data._SkillLv * 1000 + skillEnumValue

        skillData.SaveValue = saveValue
        -- 
        table.insert(Valid_SkillPointsTable[data._SkillPt], skillData)

        Valid_SkillSaveDataTable[saveValue] = skillData
        if Valid_SkillSaveDataToPoints[saveValue] then
            -- 在不同的池子里出现多个同样的技能及其等级。记录为多项
            if not Valid_SkillSaveDataToPoints_Multiple[saveValue] then
                Valid_SkillSaveDataToPoints_Multiple[saveValue] = {}
                table.insert(Valid_SkillSaveDataToPoints_Multiple[saveValue], Valid_SkillSaveDataToPoints[saveValue])
            end

            table.insert(Valid_SkillSaveDataToPoints_Multiple[saveValue], data._SkillPt)
        end
        Valid_SkillSaveDataToPoints[saveValue] = data._SkillPt
        Valid_SkillSaveDataNames[saveValue] = string.format("%s Lv%d", Core.GetSkillName(skillEnumValue), data._SkillLv)
        if mod.Config.Debug then
            Valid_SkillSaveDataNames[saveValue] = Valid_SkillSaveDataNames[saveValue] .. string.format(" [SkillID: %d] [SaveValue: %d]", skillEnumValue, saveValue)
        end
    end)

    -- 合法的孔位组合，三个孔位的类型（武器/防具）+等级
    Valid_SlotPointsTable = {}
    Valid_SlotSaveDataTable = {}
    Valid_SlotSaveDataNames = {}
    Valid_SlotSaveDataNames[0] = "NONE"
    Valid_SlotSaveDataToPoints = {}
    local accSlot = settings._RandomAmuletAccSlot
    Core.ForEach(accSlot._Values, function (data)
        if not Valid_SlotPointsTable[data._SlotPt] then
            Valid_SlotPointsTable[data._SlotPt] = {}
        end
        
        local slotData = {
            Index = data._Index,
            SlotPoint = data._SlotPt,
            SlotType1 = Core.FixedToEnum("app.EquipDef.ACCESSORY_TYPE", data._SlotType01),
            SlotLevel1 = Core.FixedToEnum("app.EquipDef.SlotLevel", data._SlotLevel01),
            SlotType2 = Core.FixedToEnum("app.EquipDef.ACCESSORY_TYPE", data._SlotType02),
            SlotLevel2 = Core.FixedToEnum("app.EquipDef.SlotLevel", data._SlotLevel02),
            SlotType3 = Core.FixedToEnum("app.EquipDef.ACCESSORY_TYPE", data._SlotType03),
            SlotLevel3 = Core.FixedToEnum("app.EquipDef.SlotLevel", data._SlotLevel03),
        }
        local hasSlot = slotData.SlotLevel1 > 0
        if not hasSlot then
            -- 有一个无孔位，pt = 0 的数据，不知道为什么。排除他，因为它的三个acc type=0（武器孔）
            return
        end

        -- 【推测】：若无武器孔，个位数为0。
        -- 【推测】：若有1个武器孔，1个以上防具孔，个位数为1。若有1个武器孔，但是无防具孔，个位数为3（实际值则为1003）
        local saveValue = slotData.SlotLevel1 * 1000 + slotData.SlotLevel2 * 100 + slotData.SlotLevel3 * 10
        local hasWeaponSlot = slotData.SlotType1 == 0
        if hasWeaponSlot then
            if saveValue == 1000 then
                -- FIXME 这是推测。个位数在其他数据中似乎只是一个flag，当个位数非零时，首个孔位是武器孔
                -- 但是（我观察到的数据中）当且仅当有武器孔但是没有防具孔时，个位数为3而不是1
                saveValue = saveValue + 3
            else
                saveValue = saveValue + 1
            end
        end

        slotData.SaveValue = saveValue
        -- 
        table.insert(Valid_SlotPointsTable[data._SlotPt], slotData)

        Valid_SlotSaveDataTable[saveValue] = slotData
        Valid_SlotSaveDataToPoints[saveValue] = data._SlotPt

        -- 生成表示孔位的字符串
        local weaponSlot = 0
        local armorSlot = 0
        if slotData.SlotType1 == 0 then
            weaponSlot = weaponSlot + slotData.SlotLevel1 * 100
        else
            armorSlot = armorSlot + slotData.SlotLevel1 * 100
        end
        if slotData.SlotType2 == 0 then
            weaponSlot = weaponSlot + slotData.SlotLevel2 * 10
        else
            armorSlot = armorSlot + slotData.SlotLevel2 * 10
        end
        if slotData.SlotType3 == 0 then
            weaponSlot = weaponSlot + slotData.SlotLevel3
        else
            armorSlot = armorSlot + slotData.SlotLevel3
        end
        
        local slotStr
        if weaponSlot > 0 then
            if armorSlot > 0 then
                slotStr = string.format("Weapon S%03d, Armor S%03d", weaponSlot, armorSlot)
            else
                slotStr = string.format("Weapon S%03d", weaponSlot)
            end
        else
            slotStr = string.format("Armor S%03d", armorSlot)
        end

        Valid_SlotSaveDataNames[saveValue] = slotStr
    end)

    -- 生成点数的combo list
    Valid_SkillPoint_ToSaveDataNames = {}
    Valid_SkillPoint_ToSaveDataNames[0] = {
        [0] = "NONE"
    }
    for pt, list in pairs(Valid_SkillPointsTable) do
        for _, data in pairs(list) do
            if not Valid_SkillPoint_ToSaveDataNames[pt] then
                Valid_SkillPoint_ToSaveDataNames[pt] = {}
            end
            Valid_SkillPoint_ToSaveDataNames[pt][data.SaveValue] = Valid_SkillSaveDataNames[data.SaveValue]
        end
    end

    Valid_SlotPoints_ToSaveDataNames = {}
    for pt, list in pairs(Valid_SlotPointsTable) do
        for _, data in pairs(list) do
            if not Valid_SlotPoints_ToSaveDataNames[pt] then
                Valid_SlotPoints_ToSaveDataNames[pt] = {}
            end
            Valid_SlotPoints_ToSaveDataNames[pt][data.SaveValue] = Valid_SlotSaveDataNames[data.SaveValue]
        end
    end

    -- 技能下拉选项：技能名去等级去重，与条目 skill1 同口径匹配
    if not CharmSkillOptions then
        local seen = {}
        local names = {}
        for saveValue, name in pairs(Valid_SkillSaveDataNames) do
            if saveValue ~= 0 and name and name ~= "NONE" then
                local base = NormalizeSkillName(name)
                if base and not seen[base] then
                    seen[base] = true
                    names[#names + 1] = base
                end
            end
        end
        table.sort(names)
        CharmSkillOptions = { [0] = "All Skills" }
        CharmSkillList = {}
        for k, n in ipairs(names) do
            CharmSkillList[k] = n
            CharmSkillOptions[k] = n
        end
    end

    RandomDataInited = true
end

local EditorStatus = {}

local TooltipText = {
    [CONST.LanguageType.English] = {
        USAGE = "Usage: In the current game version, random charm are composed of four parameters: three skill slots and one decoration slot.\nNot all slot combinations are valid.\n\nThe four checkboxes below (Valid Check) are switches for the validity check of the corresponding parameters.\nWhen the validity check for a parameter is selected, the options for the other unchecked parameters will be filtered to show only valid options.\nThe selected parameter will be locked and cannot be changed.\n\nTo ensure that the charm is valid, you should enable the validity check after editing a parameter.\nIf, after selecting the switch, the other parameters do not have the combination you want, it means that the combination is invalid.\nChanging the rarity requires you to fully exit the game menu (not the REFramework menu) for the display to update correctly.",
        WARNING = "Please note that the editor will not prevent you from writing an invalid value to your savedata.\nSome skills combination might be invalid, but I have no way of knowing for sure. The editor also doesn't have this restriction, so please be aware of this.",
        DUPLICATE_SKILL = "Error: Duplicate skill(s) in multiple skill slots: %s. Selecting the same skill in multiple slots is invalid."
    },
    [CONST.LanguageType.SimplifiedChinese] = {
        USAGE = "使用说明：当前版本，随机护石由4个参数组成，三个技能槽位与一个孔位槽位，并非所有的槽位组合均为合法的。\n\n下面的四个复选框（Valid Check）为对应参数的合法性检测开关。\n当某一参数的合法性检测被勾选时，其他未勾选的参数的可选项，将被过滤为合法选项。\n被勾选的参数将被锁定不能变更。\n\n为了保证生成的护石是合法的，你应该在编辑完一个参数后勾选合法性检测的开关。\n如果勾选后其他参数没有你想要的组合，说明该组合不合法。\n稀有度更改需要完全退出游戏菜单（不是模组菜单）才能正常反应到界面显示中。",
        WARNING = "请注意，编辑器不会阻止你往存档中写入不合法的值。\n部分技能组合很可能是非法的。编辑器没有做此限制，请注意。",
        DUPLICATE_SKILL = "错误：检测到重复技能：%s。多个技能槽位选择相同技能不合法，请更换。"
    },
}

---@param work app.savedata.cEquipWork
local function RandomCharmEditor(work, i)
    local category = work:get_Category()
    if category ~= 2 then
        -- 不是护石
        return
    end

    local amuletType = work.FreeVal0
    if not Valid_AmuletTypeDataTable[amuletType] then
        -- 非随机护石
        return
    end

    -- 护石数据存储方式
    -- 借用的是 BowgunCustomizeId 这个字段里的四个int
    -- 四个int均为四位数
    -- 前三个int为技能，千位是等级，后三位是 app.HunterDef.Skill 这个 enum 里的值（注意这个enum的值和enum名是有差异的）
    -- 第四个int为孔位，千位是第1个孔，十位是第3个孔。
    -- 【推测】：若无武器孔，个位数为0。
    -- 【推测】：若有1个武器孔，1个以上防具孔，个位数为1。若有1个武器孔，但是无防具孔，个位数为3（实际值则为1003）

    local configChanged = false
    local changed = false

    local amuletData = Get_AmuletData:call(nil, work)
    local amuletName = "Data Error! " .. tostring(i)
    if amuletData then
        amuletName = Core.GetLocalizedText(amuletData._Name)
    end

    local rowName = string.format("%s##AmuletIndex%d", amuletName, i)
    if mod.Config.Debug then
        rowName = string.format("[%d] ", i) .. rowName
    end

    imgui.push_id(string.format("AmuletIndex%d", i))
    local open = imgui.tree_node(rowName)
    if open then
        -- 编辑器
        local customValues = work.BowgunCustomizeId
        
        local skill1 = customValues:get_Item(0)
        local skill2 = customValues:get_Item(1)
        local skill3 = customValues:get_Item(2)
        local slot = customValues:get_Item(3)
        if mod.Config.Debug then
            imgui.text("Skill 1: " .. tostring(skill1))
            imgui.text("Skill 2: " .. tostring(skill2))
            imgui.text("Skill 3: " .. tostring(skill3))
            imgui.text("Slots: " .. tostring(slot))

            -- imgui.text(string.format("%s, %s, %s", tostring(skill1), tostring(type(skill1)), tostring(Valid_SkillSaveDataToPoints[2171])))
            -- for saveValue, name in pairs(Valid_SkillSaveDataNames) do
            --     imgui.text(string.format("%d -> %s", saveValue, name))
            -- end
        end

        changed, amuletType = imgui.combo("Charm Type", amuletType, Valid_AmuletTypeNames)
        if changed then
            work.FreeVal0 = amuletType
            Browser.MarkEdited(BrowserState, i, amuletName)
        end
        if changed or EditorStatus[i] == nil then
            EditorStatus[i] = {
                FilterSkill1 = false,
                Skill1Points = nil,
                FilterSkill2 = false,
                Skill2Points = nil,
                FilterSkill3 = false,
                Skill3Points = nil,
                FilterSlots = false,
                SlotPoints = nil,
            }

            -- 反查填入实际分数
            EditorStatus[i].Skill1Points = Valid_SkillSaveDataToPoints[skill1]
            if EditorStatus[i].Skill1Points == nil then
                EditorStatus[i].Skill1Points = 0
            end
            EditorStatus[i].Skill2Points = Valid_SkillSaveDataToPoints[skill2]
            if EditorStatus[i].Skill2Points == nil then
                EditorStatus[i].Skill2Points = 0
            end
            EditorStatus[i].Skill3Points = Valid_SkillSaveDataToPoints[skill3]
            if EditorStatus[i].Skill3Points == nil then
                EditorStatus[i].Skill3Points = 0
            end

            EditorStatus[i].SlotPoints = Valid_SlotSaveDataToPoints[slot]
        end
        if mod.Config.Debug then
            imgui.text(string.format("SaveValue: %s,%s,%s %s", tostring(skill1), tostring(skill2), tostring(skill3), tostring(slot)))
            imgui.text(string.format("Reverse: %s,%s,%s %s", tostring(Valid_SkillSaveDataToPoints[skill1]), tostring(Valid_SkillSaveDataToPoints[skill2]), tostring(Valid_SkillSaveDataToPoints[skill3]), tostring(Valid_SlotSaveDataToPoints[slot])))
            imgui.text(string.format("Points: %s,%s,%s %s", tostring(EditorStatus[i].Skill1Points), tostring(EditorStatus[i].Skill2Points), tostring(EditorStatus[i].Skill3Points), tostring(EditorStatus[i].SlotPoints)))
        end

        local status = EditorStatus[i]

        local msgConf = Core.GetLocalizedTextConfig(TooltipText)
        imgui.text(msgConf.USAGE)
        imgui.text()
        imgui.text_colored(msgConf.WARNING, 0xFFE0853D)
        imgui.text()

        -- 合法性检测
        local s1p = nil
        if status.FilterSkill1 then
            s1p = status.Skill1Points
        end
        local s2p = nil
        if status.FilterSkill2 then
            s2p = status.Skill2Points
        end
        local s3p = nil
        if status.FilterSkill3 then
            s3p = status.Skill3Points
        end
        local ssp = nil
        if status.FilterSlots then
            ssp = status.SlotPoints
        end

        -- 重复技能检测（SkillID 重复即不合法，与等级无关）
        local dupSkillIds = {}
        local dupCount = 0
        local seenSkillIds = {}
        for _, saveValue in ipairs({ skill1, skill2, skill3 }) do
            if saveValue ~= 0 then
                local skillId = saveValue % 1000
                if seenSkillIds[skillId] then
                    if not dupSkillIds[skillId] then
                        dupCount = dupCount + 1
                    end
                    dupSkillIds[skillId] = Core.GetSkillName(skillId)
                end
                seenSkillIds[skillId] = true
            end
        end
        if dupCount > 0 then
            local dupIds = {}
            for skillId in pairs(dupSkillIds) do
                dupIds[#dupIds + 1] = skillId
            end
            table.sort(dupIds)
            local dupNames = {}
            for _, skillId in ipairs(dupIds) do
                dupNames[#dupNames + 1] = dupSkillIds[skillId]
            end
            imgui.text_colored(string.format(msgConf.DUPLICATE_SKILL, table.concat(dupNames, ", ")), Core.ReverseRGB(0xffff8000))
        end

        if mod.Config.Debug then
            imgui.text(string.format("Points: %s,%s,%s %s", tostring(status.Skill1Points), tostring(status.Skill2Points), tostring(status.Skill3Points), tostring(status.SlotPoints)))
            imgui.text(string.format("FilterOptions: %s,%s,%s %s", tostring(s1p), tostring(s2p), tostring(s3p), tostring(ssp)))
        end

        local filteredData = GetCurrentValidPointsList(Valid_AmuletTypeDataTable[amuletType], s1p, s2p, s3p, ssp)
        if not filteredData then
            imgui.text("ERROR, not such amulet type")
            imgui.tree_pop()
            return
        end

        if mod.Config.Debug then
            imgui.text(string.format("1 Is Multiple: %s", tostring(Valid_SkillSaveDataToPoints_Multiple[skill1] ~= nil)))
            imgui.text(string.format("2 Is Multiple: %s", tostring(Valid_SkillSaveDataToPoints_Multiple[skill2] ~= nil)))
            imgui.text(string.format("3 Is Multiple: %s", tostring(Valid_SkillSaveDataToPoints_Multiple[skill3] ~= nil)))
        end

        if Valid_SkillSaveDataToPoints_Multiple[skill1] then
            -- 理论上来讲应该在初始化 Skill1Points 的时候就进行这个修改。但是那样逻辑会比较复杂。实际上晚一帧也没关系，因为执行速度很快。
            local sp = PickValidSkillPointIfInMultipleRandomPool(Valid_SkillSaveDataToPoints_Multiple[skill1], filteredData.Skill1List, status.Skill1Points)
            if sp then
                status.Skill1Points = sp
            end
        end
        if Valid_SkillSaveDataToPoints_Multiple[skill2] then
            local sp = PickValidSkillPointIfInMultipleRandomPool(Valid_SkillSaveDataToPoints_Multiple[skill2], filteredData.Skill2List, status.Skill2Points)
            if sp then
                status.Skill2Points = sp
            end
        end
        if Valid_SkillSaveDataToPoints_Multiple[skill3] then
            local sp = PickValidSkillPointIfInMultipleRandomPool(Valid_SkillSaveDataToPoints_Multiple[skill3], filteredData.Skill3List, status.Skill3Points)
            if sp then
                status.Skill3Points = sp
            end
        end
        
        local skillList = Valid_SkillSaveDataNames
        local slotList = Valid_SlotSaveDataNames

        -- 技能1
        configChanged = false
        changed, status.FilterSkill1 = imgui.checkbox(string.format("Valid Check: Skill 1##FilterSkill1%d", i), status.FilterSkill1)
        configChanged = configChanged or changed
        changed, status.Skill1Points = imgui.combo(string.format("Skill 1 Type##Skill1Points%d", i), status.Skill1Points, filteredData.Skill1List)
        configChanged = configChanged or changed
        if Valid_SkillPoint_ToSaveDataNames[status.Skill1Points] then
            skillList = Valid_SkillPoint_ToSaveDataNames[status.Skill1Points]
        end
        changed, skill1 = imgui.combo(string.format("Skill 1##AmuletSkill1%d", i), skill1, skillList)
        configChanged = configChanged or changed
        if configChanged then
            customValues:set_Item(0, skill1)
            Browser.MarkEdited(BrowserState, i, amuletName)
        end

        -- 技能2
        configChanged = false
        changed, status.FilterSkill2 = imgui.checkbox(string.format("Valid Check: Skill 2##FilterSkill2%d", i), status.FilterSkill2)
        configChanged = configChanged or changed
        changed, status.Skill2Points = imgui.combo(string.format("Skill 2 Type##Skill2Points%d", i), status.Skill2Points, filteredData.Skill2List)
        configChanged = configChanged or changed
        if Valid_SkillPoint_ToSaveDataNames[status.Skill2Points] then
            skillList = Valid_SkillPoint_ToSaveDataNames[status.Skill2Points]
        end
        changed, skill2 = imgui.combo(string.format("Skill 2##AmuletSkill2%d", i), skill2, skillList)
        configChanged = configChanged or changed
        if configChanged then
            customValues:set_Item(1, skill2)
            Browser.MarkEdited(BrowserState, i, amuletName)
        end

        -- 技能3
        configChanged = false
        changed, status.FilterSkill3 = imgui.checkbox(string.format("Valid Check: Skill 3##FilterSkill3%d", i), status.FilterSkill3)
        configChanged = configChanged or changed
        changed, status.Skill3Points = imgui.combo(string.format("Skill 3 Type##Skill3Points%d", i), status.Skill3Points, filteredData.Skill3List)
        configChanged = configChanged or changed
        if Valid_SkillPoint_ToSaveDataNames[status.Skill3Points] then
            skillList = Valid_SkillPoint_ToSaveDataNames[status.Skill3Points]
        end
        changed, skill3 = imgui.combo(string.format("Skill 3##AmuletSkill3%d", i), skill3, skillList)
        configChanged = configChanged or changed
        if configChanged then
            customValues:set_Item(2, skill3)
            Browser.MarkEdited(BrowserState, i, amuletName)
        end

        -- 孔位
        configChanged = false
        changed, status.FilterSlots = imgui.checkbox(string.format("Valid Check: Slots##FilterSlots%d", i), status.FilterSlots)
        configChanged = configChanged or changed
        changed, status.SlotPoints = imgui.combo(string.format("Slots Type##SlotsPoints%d", i), status.SlotPoints, filteredData.SlotList)
        configChanged = configChanged or changed

        if Valid_SlotPoints_ToSaveDataNames[status.SlotPoints] then
            slotList = Valid_SlotPoints_ToSaveDataNames[status.SlotPoints]
        end
        changed, slot = imgui.combo(string.format("Slots##AmuletSlots%d", i), slot, slotList)
        configChanged = configChanged or changed
        Tooltip("S100 = Lv1 slot, S210 = Lv2 slot + Lv1 slot, etc")
        if configChanged then
            customValues:set_Item(3, slot)
            Browser.MarkEdited(BrowserState, i, amuletName)
        end
        
        imgui.tree_pop()
    end
    imgui.pop_id()
end


local function EquipBoxEditor()
    local mgr = Core.GetVariousDataManager()
    if not mgr then
        return
    end

    local data = mgr._Setting._EquipDatas
    -- sdk.get_managed_singleton("app.SaveDataManager"):getCurrentUserSaveData():get_Equip()._EquipBox:get_Item(98)

    local mgr = Core.GetSaveDataManager()
    if not mgr then
        return false
    end
    InitRandomCharmData()

    local box = mgr:getCurrentUserSaveData()._Equip._EquipBox

    if mod.Config.Debug then
        imgui.text("Valid Amulet types:")
        for k, v in pairs(Valid_AmuletTypeNames) do
            imgui.same_line()
            imgui.text(tostring(k) ..", ")
        end
        
        imgui.text("Valid Slot types:")
        for k, v in pairs(Valid_SlotSaveDataNames) do
            imgui.text(tostring(k) ..": " .. tostring(v))
        end

        for pts, list in pairs(Valid_SlotPoints_ToSaveDataNames) do
            imgui.text(string.format("Slot pt %d", pts))
            for saveValue, name in pairs(list) do
                imgui.text(string.format("%d: %s", saveValue, name))
            end
        end
    end

    -- 新列表逻辑
    local tbChanged = Browser.Toolbar(BrowserState, {
        category = CharmCategoryOptions,
        sort = CharmSortOptions,
        skill = { options = CharmSkillOptions, list = CharmSkillList },
    })
    if tbChanged then
        -- 调整筛选时不跳回最近编辑的条目
        BrowserState.ScrollToIdx = nil
    end

    -- 收集全部随机护石条目
    local entries = {}
    local count = box:get_Count()
    for j = 0, count - 1 do
        local work = box:get_Item(j)
        if work then
            local category = work:get_Category()
            if category == 2 then
                local amuletType = work.FreeVal0
                if Valid_AmuletTypeDataTable[amuletType] then
                    local amuletData = Get_AmuletData:call(nil, work)
                    local amuletName = "Data Error! " .. tostring(j)
                    if amuletData then
                        amuletName = Core.GetLocalizedText(amuletData._Name)
                    end
                    -- 同步最近编辑条目的最新名字（改名后保持显示正确）
                    if BrowserState.LastEditedIdx == j then
                        BrowserState.LastEditedName = amuletName
                    end
                    -- 首个技能词条（基础技能名，供技能筛选匹配）
                    local skill1Name = "NONE"
                    local customValues = work.BowgunCustomizeId
                    if customValues then
                        skill1Name = NormalizeSkillName(Valid_SkillSaveDataNames[customValues:get_Item(0)]) or "NONE"
                    end
                    entries[#entries + 1] = {
                        idx = j,
                        work = work,
                        name = amuletName,
                        cat = amuletType,
                        skill1 = skill1Name,
                    }
                end
            end
        end
    end

    -- 过滤 + 排序
    local filtered = Browser.Filter(BrowserState, entries, function(k) return k + 188 end, CharmSkillList)

    -- 最近编辑信息条（放在空结果判断之前，保证始终可见）
    Browser.EditedBar(BrowserState, filtered)

    if #filtered == 0 then
        imgui.text("No matching charms")
        return
    end

    imgui.text(string.format("Showing %d / %d random charms", #filtered, #entries))
    if #filtered > 500 then
        imgui.text_colored("Too many results. Use filters to narrow down.", Core.ReverseRGB(0xffff8000))
    end

    local listOpen = imgui.tree_node(string.format("EquipBox (%d)", count))
    imgui.same_line()
    imgui.text(string.format("charms: %d, shown: %d", #entries, #filtered))
    if listOpen then
        for _, e in ipairs(filtered) do
            Browser.BeginScroll(BrowserState, e.idx)
            RandomCharmEditor(e.work, e.idx)
        end
        imgui.tree_pop()
    end
end

mod.Menu(function()
    EquipBoxEditor()
end)
