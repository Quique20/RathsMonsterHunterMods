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

local Game = require("_CatLib.game")
local Player = require("_CatLib.game.player")
local GameText = require("_CatLib.game.text")

local SDK = require("_CatLib.sdk")
local Utils = require("_CatLib.utils")
local CONST = require("_CatLib.const")
local LanguageUtils = require("_CatLib.language")

local _M = {}

local function GetASkill005Name(lang)
    return GameText.GetItemName(628, lang)
end


-- local PhialTextGuid = SDK.NewGuid("5c9031a5-5c07-4419-ac0d-5d258c094e8e")
local function InitBinName(lang)
    if LanguageUtils.IsChinese(lang) then
        return "瓶爆"
    end
    return GameText.GetLocalizedText(SDK.NewGuid("5c9031a5-5c07-4419-ac0d-5d258c094e8e"), lang)
end

-- 直斩和集中攻击是有不同的，但是我们这里只需要名字，所以无所谓
-- local LongSword_OverheadSlash = -1997082496
-- local LongSword_RedSlash1 = 1927826048
-- local LongSword_HelmBreaker = 1909693824
-- local LongSword_IaiKijinSlash = 491596736
-- local LongSword_RenkiRelease = -1093563648
-- local LongSword_FocusStrike = 1569905664
-- local WeaponTypeColToActionIDFix = {
--     [CONST.WeaponType.LongSword] = {
--         [0] = LongSword_OverheadSlash, -- 我tm就不懂了为什么出招表能消失
--         [36] = LongSword_RedSlash1,
--         [38] = LongSword_RedSlash1,
        
--         [71] = LongSword_FocusStrike,
--         [78] = LongSword_FocusStrike,
--     },
--     [CONST.WeaponType.Gunlance] = {
--         [3] = 1497865856, -- 龙杭炮刺那一下（可以用没子弹的时候测试）
--     }
-- }

-- local InsectGlaive_BugMark = 569344320

-- local BinName = InitBinName()

local function InitBowShotName(lang)
    if LanguageUtils.IsChinese(lang) then
        return "平射"
    end
    
    return GameText.GetActionNameByFixedID(-94638112, lang)
end

-- local Bow_Shot = InitBowShotName()
-- local Bow_GoushaShot = GameText.GetActionNameByFixedID(713120064)
-- local Bow_GoushaRapidShot = GameText.GetActionNameByFixedID(-1871211648)

---@type table<app.WeaponDef.TYPE, table<number, app.ActionGuideID.WP00_Fixed>>
-- local WeaponTypeShellColToActionIDFix = {
    -- [CONST.WeaponType.LongSword] = {
    --     [1] = LongSword_HelmBreaker, -- 白刃
    --     [2] = LongSword_HelmBreaker, -- 白刃终结
    --     [3] = LongSword_HelmBreaker, -- 黄刃
    --     [4] = LongSword_HelmBreaker, -- 黄刃终结
    --     [5] = LongSword_HelmBreaker, -- 红刃
    --     [6] = LongSword_HelmBreaker, -- 红刃终结

    --     [7] = LongSword_IaiKijinSlash,
    --     [8] = LongSword_IaiKijinSlash,
    --     [9] = LongSword_IaiKijinSlash,
    --     [10] = LongSword_IaiKijinSlash,

    --     [11] = LongSword_FocusStrike,
    --     [12] = LongSword_RenkiRelease, -- FocusStrike 和 Shell.Index 里不一样

    --     [13] = LongSword_RenkiRelease,
    --     [14] = LongSword_RenkiRelease,
    --     [15] = LongSword_RenkiRelease,
    --     [16] = LongSword_RenkiRelease,
    -- },
    -- [CONST.WeaponType.SwitchAxe] = {
    --     -- [1] = 零解终结
    --     -- [10] = 简易零解终结
    --     -- [2] = 简易属性终结
    --     [3] = BinName,

    --     -- [4] -- 压解
    --     -- [5] -- 全解
    --     -- [8] -- 全解
    -- },
    -- [CONST.WeaponType.ChargeBlade] = {
    --     [0] = BinName,
    --     [1] = BinName,
    --     [2] = BinName,
    --     [3] = BinName,
    --     [4] = BinName,
    --     [5] = BinName,
    --     [6] = BinName,
    --     [7] = BinName,
    --     [8] = BinName,
    --     [9] = BinName,
    --     [10] = BinName,
    --     [11] = BinName,
    -- },
    -- [CONST.WeaponType.InsectGlaive] = {
    --     -- [0] = -1726610048,
    --     -- [1] = -1726610048,
    --     [2] = InsectGlaive_BugMark, -- 无法区分空中虫印标记
    --     [3] = InsectGlaive_BugMark, -- 无法区分空中虫印标记
    --     [4] = InsectGlaive_BugMark, -- 无法区分空中虫印标记
    --     [5] = InsectGlaive_BugMark, -- 无法区分空中虫印标记
    --     [6] = InsectGlaive_BugMark, -- 无法区分空中虫印标记
    --     [7] = InsectGlaive_BugMark, -- 无法区分空中虫印标记
    --     [8] = InsectGlaive_BugMark, -- 无法区分空中虫印标记
    --     [9] = InsectGlaive_BugMark, -- 无法区分空中虫印标记
    -- },
    -- [CONST.WeaponType.Gunlance] = {
    --     [0] = Gunlance_Shot, -- 炮击 通常型
    --     [1] = Gunlance_Shot, -- 炮击 扩散型
    --     [2] = Gunlance_Shot, -- 炮击 放射型

    --     [3] = Gunlance_ChargeShot, -- 蓄力炮击
    --     [4] = Gunlance_ChargeShot, -- 蓄力炮击
    --     [5] = Gunlance_ChargeShot, -- 蓄力炮击
        
    --     [6] = Gunlance_FullBurst, -- 全弹
    --     [7] = Gunlance_FullBurst, -- 全弹
    --     [8] = Gunlance_FullBurst, -- 全弹

    --     [9] = Gunlance_Ryuugeki, -- 龙击炮
    --     [10] = Gunlance_Ryuugeki, -- 龙击炮
    --     [11] = Gunlance_Ryuugeki, -- 龙击炮

    --     [16] = Gunlance_Pile, -- 龙杭炮；成功的集中攻击也会触发
    --     [17] = Gunlance_Pile, -- 龙杭炮终结；成功的集中攻击也会触发

    --     [20] = Gunlance_FocusAttack, -- 集中龙杭炮穿刺
    --     [22] = Gunlance_FocusAttack, -- 集中龙杭炮穿刺终结
    -- },
    -- [CONST.WeaponType.HuntingHorn] = {
    --     -- [0] -- 响周波打？演奏？
    --     -- [9] -- 响周波打？演奏？
    --     [45] = -466143936, -- 响玉？
    --     [43] = -466143936, -- 响玉？
    --     -- [7] -- 高周波？演奏？
    -- },
    -- [CONST.WeaponType.Bow] = {
    --     [0] = Bow_Shot .. "·Lv1",-- -94638112, -- 蓄力0，1发
    --     [1] = Bow_Shot .. "·Lv2",-- -94638112, -- 蓄力1，2发
    --     [2] = Bow_Shot .. "·Lv3",-- -94638112, -- 蓄力2，3发

    --     [4] = Bow_GoushaShot .. "·Lv1", -- -1018903168, -- 迅雷闪击 Quick Shot
    --     [5] = Bow_GoushaShot .. "·Lv2", -- 刚射 4发，Gousha Shot
    --     [6] = Bow_GoushaShot .. "·Lv3", -- 刚射 蓄力，5发
    --     [14] = Bow_GoushaRapidShot .. "·Lv1", -- 刚连射 3发，迅雷闪击（不提升蓄力）-刚射-刚连射
    --     [15] = Bow_GoushaRapidShot .. "·Lv2", -- 刚连射 5发，Gousha Rapid Shot
    --     [16] = Bow_GoushaRapidShot .. "·Lv3", -- 刚连射 蓄力，6发
        
    --     [12] = -125532448, -- 龙之箭（自由态）Special Shot
    --     [13] = 374745664, -- 龙之箭（连段中）Special Shot Shortern
    --     [31] = -1657138304, -- 龙之千矢 Twin Shot

    --     -- -825706560 残留触发箭会被记作龙之千矢等（index一样）
    --     [18] = -966116480, -- 引导箭 超时爆炸（主动引爆？）
    --     [19] = -966116480, -- 引导箭 超时爆炸（主动引爆？） Tsugiya
    --     -- [20] = -94638112, -- 引导箭 射击?
    --     -- [21] = -94638112, -- 引导箭 射击?
    --     [65] = Bow_Shot .. "·Lv4", -- 引导箭 射击（蓄力无变化）
    --     [66] = Bow_GoushaShot .. "·Lv4", -- 引导箭 刚射
    --     [67] = Bow_GoushaRapidShot .. "·Lv4", -- 引导箭 刚连射
    --     -- [25] = , -- 引导箭相关，但是不知道哪来的
    --     -- [26] = , -- 引导箭相关，但是不知道哪来的
    --     -- [20] = , -- 疑似0蓄引导箭 射击
    --     -- [21] = , -- 疑似0蓄引导箭 射击
    --     -- [22] = -1212153600, -- 引导箭的不知道什么攻击模式，飞燕射击和迅雷闪击都能触发


    --     [70] = -1212153600, -- 引导箭 飞燕
    --     [71] = -1018903168, -- 引导箭 迅雷闪击

    --     -- [4] = , -- 飞燕射击蓄力0 Charge Step Jump
    --     -- [5] = , -- 飞燕射击蓄力1
    --     -- [6] = , -- 飞燕射击蓄力2

    --     [30] = 169799632, -- 集中 无蓄力 Multi Lockon
    --     [27] = 169799632, -- 集中 蓄力满
    --     [28] = 169799632, -- 集中 蓄力满
    --     [34] = 169799632, -- 集中 终结（龙之箭）
    --     [38] = 169799632, -- 集中 终结（龙之箭）
    --     [39] = 169799632, -- 集中 无蓄力终结？

    --     -- 曲射不触发？？
    --     -- [0] = -1364116608, -- 曲射 Kyokusha
    -- }
-- }

local GunShells = {
    [0] = GameText.GetItemName(37), -- 通常弹
    [1] = GameText.GetItemName(38), -- 贯穿弹
    [20] = GameText.GetItemName(39), -- 散弹
    [9] = GameText.GetItemName(40), -- 穿甲榴弹（追击）
    -- [0] = GameText.GetItemName(41), -- 扩散弹
    -- [0] = GameText.GetItemName(42), -- 火炎弹
    -- [0] = GameText.GetItemName(43), -- 水冷弹
    [5] = GameText.GetItemName(44), -- 电击弹
    [6] = GameText.GetItemName(45), -- 冰结弹
    -- [0] = GameText.GetItemName(46), -- 灭龙弹
    [11] = GameText.GetItemName(47), -- 毒弹
    [13] = GameText.GetItemName(48), -- 麻痹弹
    [12] = GameText.GetItemName(49), -- 睡眠弹
    -- [8] = GameText.GetItemName(50), -- 斩裂弹、穿甲榴弹（命中）
    [23] = GameText.GetItemName(50), -- 斩裂弹（后续追击）
    -- [0] = GameText.GetItemName(416), -- 减气弹
    [29] = GameText.GetItemName(153), -- 龙击弹
    [30] = GameText.GetItemName(153), -- 龙击弹2 hit

    -- 轻弩
    [38] = -786271680, -- 集中
    [58] = -786271680, -- 集中 2hit
    [40] = -70162400, -- 起爆龙弹 SET_BOMB
    -- = 14729, 附着龙弹

    -- 重弩
    [21] = -92194408, -- 集中特效弹【龙吼】
    [19] = -92194408, -- 集中特效弹【龙吼】 2hit
    [16] = 154168000, -- 龙热抵消弹
    [26] = 154168000, -- 龙热抵消弹 抵消成功
    [14] = 903581824, -- 龙热机关龙蛋
    -- = 195481808, -- 龙热穿甲弹
    -- = 20551816, -- 龙热榴弹
}
-- (569344320) -> 操虫【虫印标记】
-- (289965312) -> 操虫【空中虫印标记】
-- (1666986368) -> 操虫【空中印弹】
-- (-1726610048) -> 操虫【印弹】

local WeaponTypeShellName = {}
local function IsWeaponShellName(wpType, name)
    local expect = WeaponTypeShellName[wpType]
    if expect == nil then
        expect = string.format("Wp%02dShell", wpType)
        WeaponTypeShellName[wpType] = expect
    end
    return expect == name
end

local WeaponTypeShellIndexes = nil
local function InitWeaponTypeShellIndexes()
    if WeaponTypeShellIndexes then
        return
    end
    WeaponTypeShellIndexes = {
        [CONST.WeaponType.GreatSword] = Utils.GetEnumMap("ace.Wp00Shell.Index"),
        [CONST.WeaponType.SwordShield] = Utils.GetEnumMap("app.Wp01Shell.Index"),
        [CONST.WeaponType.DualBlades] = Utils.GetEnumMap("app.Wp02Shell.Index"),
        [CONST.WeaponType.LongSword] = Utils.GetEnumMap("ace.Wp03Shell.Index"),
        -- [CONST.WeaponType.Hammer] = Utils.GetEnumMap(""),
        [CONST.WeaponType.HuntingHorn] = Utils.GetEnumMap("app.Wp05Shell.Index"),
        [CONST.WeaponType.Lance] = Utils.GetEnumMap("ace.Wp06Shell.Index"),
        [CONST.WeaponType.Gunlance] = Utils.GetEnumMap("app.Wp07Shell.Index"),
        [CONST.WeaponType.SwitchAxe] = Utils.GetEnumMap("app.Wp08Shell.Index"),
        [CONST.WeaponType.ChargeBlade] = Utils.GetEnumMap("app.Wp09Shell.Index"),
        [CONST.WeaponType.InsectGlaive] = Utils.GetEnumMap("app.Wp10Shell.Index"),
        [CONST.WeaponType.Bow] = Utils.GetEnumMap("app.Wp11Shell.Index"),
        -- [CONST.WeaponType.HeavyBowgun] = Utils.GetEnumMap(""),
        [CONST.WeaponType.LightBowgun] = Utils.GetEnumMap("ace.Wp13Shell.Index"),
    }
end

local LongSword_OverheadSlash = -1997082496
local LongSword_RedSlash1 = 1927826048
local LongSword_HelmBreaker = 1909693824
local LongSword_IaiKijinSlash = 491596736
local LongSword_RenkiRelease = -1093563648
local LongSword_FocusStrike = 1569905664

local function LongSwordShellIndexNames(i, colID, lang)
    if 1 <= i and i <= 6 then
        return LongSword_HelmBreaker
    end
    if 8 <= i and i <= 10 then
        return LongSword_IaiKijinSlash
    end
    if 11 <= i and i <= 12 then
        return LongSword_FocusStrike
    end
    if 13 <= i and i <= 16 then
        return LongSword_RenkiRelease
    end
end

local Gunlance_Shot = 703375872
local Gunlance_ChargeShot = -43537492
local Gunlance_Ryuugeki = -26915160 -- 龙击炮
local Gunlance_FocusAttack = -915528384
local Gunlance_Pile = 1497865856 -- 龙杭炮
local Gunlance_PileFullRelease = 646080000 -- 龙杭全弹
local Gunlance_FullBurst = -1677525760 -- 全弹

local function GunlanceShellIndexNames(i, colID, lang)
    if 0 <= i and i <= 2 then
        return Gunlance_Shot
    end
    if 3 <= i and i <= 8 then
        return Gunlance_ChargeShot
    end
    if 9 <= i and i <= 11 then
        return Gunlance_FullBurst
    end
    if 15 <= i and i <= 17 then
        return Gunlance_Pile
    end
    if 18 <= i and i <= 20 then
        return Gunlance_Pile -- 连装龙杭 RBF
    end
    if 24 <= i and i <= 27 then
        -- 25-27其实是龙杭的伤害，但是都算到集中里
        return Gunlance_FocusAttack
    end
end

local SwitchAxe_ElementalRelease_Finish = -1280417792 -- 属性解放终结
local SwitchAxe_ElementalRelease_SimpleFinish = -1710496128 -- 简易属性解放终结
local SwitchAxe_ZeroRelease_Finish = 67143400 -- 零解终结
local SwitchAxe_ZeroRelease_SimpleFinish = -1011370176 -- 简易零解终结
local SwitchAxe_ChargeRelease = 1649891712 -- 压解
local SwitchAxe_FullRelease = 26943142 -- 全解

local function SwitchAxeShellIndexNames(i, colID, lang)
    if i == 0 then
        return SwitchAxe_ElementalRelease_SimpleFinish
    end
    if i == 1 then
        return SwitchAxe_ElementalRelease_Finish
    end
    if i == 2 then
        return SwitchAxe_ZeroRelease_SimpleFinish
    end
    if i == 3 then
        return SwitchAxe_ZeroRelease_Finish
    end
    if 4 <= i and i <= 5 then
        return InitBinName(lang)
    end
    if 6 <= i and i <= 7 then
        return SwitchAxe_ChargeRelease
    end
    if 8 <= i and i <= 11 then
        return SwitchAxe_FullRelease
    end
end

local ChargeBlade_SuperRelease = 2057398656

local function ChargeBladeShellIndexNames(i, colID, lang)
    if true then
        return InitBinName(lang)
    end
    if 0 <= i and i <= 1 then
        return InitBinName(lang) -- 一二解
    end
    if 7 <= i and i <= 8 then
        return ChargeBlade_SuperRelease -- 超解
    end
    if 9 <= i and i <= 11 then
        return InitBinName(lang) -- 大解、追解
    end
    if 2 <= i and i <= 3 then
        return InitBinName(lang) -- 红剑平a的瓶爆
    end
    if 4 <= i and i <= 5 then
        return InitBinName(lang) -- 红盾盾突的瓶爆
    end
    if i == 6 then
        return InitBinName(lang) -- 开红剑的瓶爆
    end
end

local function InsectGlaiveShellIndexNames(i, colID, lang)
    if 0 <= i and i <= 1 then
        return nil -- 印弹
    end
    if 2 <= i and i <= 3 then
        return "<REF RefStatus_0008_002_00>·<REF RefStatus_0008_002_04>" -- 爆破
    end
    if 4 <= i and i <= 5 then
        return nil -- 回复
    end
    if 6 <= i and i <= 7 then
        return "<REF RefStatus_0008_002_00>·<REF RefStatus_0008_002_03>" -- 麻痹
    end
    if 8 <= i and i <= 9 then
        return "<REF RefStatus_0008_002_00>·<REF RefStatus_0008_002_02>" -- 毒
    end
end

local HuntingHorn_Hibiki = -466143936 -- 响玉
local HuntingHorn_Music = -208341008 -- 演奏
local HuntingHorn_Encore = -678098496 -- 叠加
local HuntingHorn_Penetrate = -1842698112 -- 鸣响之曲
local HuntingHorn_Aim_JustMusic = -1457110272 -- 集中攻击

local HuntingHorn_HighFreqGuid = SDK.NewGuid("be13e48a-18f0-409f-92cf-1f276177abb4")
local function HighFreqName(lang)
    return GameText.GetLocalizedText(HuntingHorn_HighFreqGuid, lang)
end

local function HuntingHornShellIndexNames(i, colID, lang)
    if 2 <= i and i <= 4 then
        return HuntingHorn_Hibiki -- 响玉
    end
    if i == 0 or i == 6 then
        return HuntingHorn_Music -- 演奏，乐曲效果
    end
    if i == 7 or i == 9 then
        return HuntingHorn_Aim_JustMusic -- 集中攻击的 Just伤害，FullCombo伤害（不会打，没测过）
    end
    if i == 1 then
        return HighFreqName(lang) -- 响周波
    end
    if i == 5 then
        return HuntingHorn_Penetrate -- 鸣响之曲
    end
    if i == 8 then
        return -- Sonic Blast? 不知道是什么，可能是响周波
    end
end

local Bow_Homing = -966116480
local Bow_GoushaShot_ID = 713120064 -- 刚射
local Bow_GoushaRapidShot_ID = -1871211648 -- 刚连射
local Bow_RapidShot = -1018903168 -- 迅雷闪击

local Bow_JumpShot = -1212153600

local Bow_Kyokusha = -1364116608 -- 曲射

local Bow_AimLockOn = 169799632 -- 集中攻击

local Bow_Special = -125532448
local Bow_SpecialQuick = 374745664
local Bow_TwinShot = -1657138304

local Bow_Trigger = "<REF ActionGuideDataNameText_Wp11_m825706560>"

local function BowHomingName(lang)
    return GameText.GetActionNameByFixedID(Bow_Homing, lang)
end

local function InitBowGoushaShotName(lang)
    return GameText.GetActionNameByFixedID(Bow_GoushaShot_ID, lang)
end

local function InitBowGoushaRapidShotName(lang)
    return GameText.GetActionNameByFixedID(Bow_GoushaRapidShot_ID, lang)
end

local function InitBowRapidShotName(lang)
    return GameText.GetActionNameByFixedID(Bow_RapidShot, lang)
end

local function InitBowJumpShotName(lang)
    return GameText.GetActionNameByFixedID(Bow_JumpShot, lang)
end

local function InitBowKyokushaName(lang)
    return GameText.GetActionNameByFixedID(Bow_Kyokusha, lang)
end

local function InitBowSpecialName(lang)
    return GameText.GetActionNameByFixedID(Bow_Special, lang)
end

local function InitBowSpecialQuickName(lang)
    return GameText.GetActionNameByFixedID(Bow_SpecialQuick, lang)
end

local function InitBowTwinShotName(lang)
    return GameText.GetActionNameByFixedID(Bow_TwinShot, lang)
end

local BowShellIndexMap = {
    [6] = Bow_RapidShot, -- 迅雷闪击

    [34] = Bow_Homing, -- 引导箭命中


    [21] = Bow_Special, -- 龙之箭（自由态）Special Shot
    [22] = Bow_SpecialQuick, -- 龙之箭刹那（连段中）Special Shot Shortern
    
    [30] = Bow_TwinShot, -- 龙之千矢 Twin Shot
}

local function BowShellIndexNames(i, colID, lang)
    -- 平射
    if 0 <= i and i <= 3 then
        return InitBowShotName(lang) .. "·Lv" .. tostring(i+1)
    end
    if i == 5 then
        return GetASkill005Name(lang)
    end
    if i == 7 then
        return InitBowRapidShotName(lang)
    end
    -- 刚射
    if 8 <= i and i <= 11 then
        return InitBowGoushaShotName(lang) .. "·Lv" .. tostring(i-7)
    end
    -- 刚连射
    if 25 <= i and i <= 28 then
        return InitBowGoushaRapidShotName(lang) .. "·Lv" .. tostring(i-24)
    end
    
    -- 曲射及其Child
    if 13 <= i and i <= 16 then
        return InitBowKyokushaName(lang) .. "·Lv" .. tostring(i-12)
    end
    if 17 <= i and i <= 20 then
        return InitBowKyokushaName(lang) .. "·Lv" .. tostring(i-16)
    end
    
    -- 集中攻击
    if 37 <= i and i <= 43 then
        return Bow_AimLockOn
    end
    
    -- 引导箭相关（Homing）
    if i == 4 then
        return InitBowShotName(lang) .. "·" .. BowHomingName(lang)
    end
    if i == 12 then
        return InitBowGoushaShotName(lang) .. "·" .. BowHomingName(lang)
    end
    if i == 29 then
        return InitBowGoushaRapidShotName(lang) .. "·" .. BowHomingName(lang)
    end
    if i == 7 then
        return InitBowRapidShotName(lang) .. "·" .. BowHomingName(lang)
    end
    if i == 23 then
        return InitBowSpecialName(lang) .. "·" .. BowHomingName(lang)
    end
    if i == 24 then
        return InitBowSpecialQuickName(lang) .. "·" .. BowHomingName(lang)
    end
    if i == 31 then
        return InitBowTwinShotName(lang) .. "·" .. BowHomingName(lang)
    end
    if 34 <= i and i <= 36 then
        -- 引导箭爆炸（触发箭）
        return Bow_Trigger
    end

    if 46 <= i and i <= 48 then
        return InitBowKyokushaName(lang) .. "·" .. Bow_Trigger
    end

    if i == 44 then
        -- 引导箭命中身体 RSID 500-506
        if colID == 0 then
            return InitBowShotName(lang) .. "·" .. BowHomingName(lang)
        end
        if colID == 1 then
            return InitBowGoushaShotName(lang) .. "·" .. BowHomingName(lang)
        end
        if colID == 2 then
            return InitBowGoushaRapidShotName(lang) .. "·" .. BowHomingName(lang)
        end
        if colID == 3 then
            -- 龙之千矢
            return InitBowTwinShotName(lang) .. "·" .. BowHomingName(lang)
        end
        if colID == 5 then
            return InitBowRapidShotName(lang) .. "·" .. BowHomingName(lang)
        end
        if colID == 6 then
            return InitBowJumpShotName(lang) .. "·" .. BowHomingName(lang)
        end
    end
    return BowShellIndexMap[i]
end

-- local function LightBowgunShellIndexNames(i, colID, lang)
--     -- 平射
--     if 0 <= i and i <= 3 then
--         return GameText.GetItemName(37, lang)
--     end
-- end

local WeaponTypeShellIndexFunctions = {
    [CONST.WeaponType.LongSword] = LongSwordShellIndexNames,
    [CONST.WeaponType.Gunlance] = GunlanceShellIndexNames,
    [CONST.WeaponType.SwitchAxe] = SwitchAxeShellIndexNames,
    [CONST.WeaponType.ChargeBlade] = ChargeBladeShellIndexNames,
    [CONST.WeaponType.InsectGlaive] = InsectGlaiveShellIndexNames,
    [CONST.WeaponType.HuntingHorn] = HuntingHornShellIndexNames,
    [CONST.WeaponType.Bow] = BowShellIndexNames,
    -- [CONST.WeaponType.LightBowgun] = LightBowgunShellIndexNames,
}

local function GetShellNameByAppShell(wpType, colID, shell, lang, character)
    local setupArgs = shell:get_field("<Setting>k__BackingField")
    local effectParam = setupArgs._EffectParam
    local mainParam = setupArgs._MainParam
    local nameHash = setupArgs._NameHash

    local shellIndex
    local paramMatchIndex

    if character == nil then
        character = Player.GetCharacter()
    end
    local ctrl = character:get_Weapon()._ShellCreateController
    local list = ctrl._ShellList._DataList
    -- local listLen = list:get_Count()
    -- if colID < listLen then
    --     local pkg = list:get_Item(colID)._ShellPackage
    --     if pkg._MainParam == argParam then
    --         shellIndex = colID
    --     end
    --     Core.SendMessage("%x vs %x", pkg._MainParam:get_address(), argParam:get_address())
    -- end

    if not shellIndex then
        Utils.ForEach(list, function (shell, i)
            local pkg = shell._ShellPackage
            if nameHash == pkg._ShellNameHash then
                shellIndex = i
                return Utils.ForEachBreak
            end

            local param = pkg._MainParam
            if pkg._MainParam == mainParam and effectParam == pkg._EffectParam then
                paramMatchIndex = i
                if colID == pkg._AttackCollisionID then
                    shellIndex = i
                    return Utils.ForEachBreak
                end
            end
            -- Core.SendMessage("[%d]%s: %x vs %x", i, shellNames[i], param:get_address(), argParam:get_address())
        end)
    end

    if false then
        InitWeaponTypeShellIndexes()

        local shellNames = WeaponTypeShellIndexes[wpType]
        if shellNames then
            if shellIndex then
                Game.SendMessage("%s (full %d)", shellNames[shellIndex], colID)
            elseif paramMatchIndex then
                Game.SendMessage("%s (param only: %d)", shellNames[paramMatchIndex], colID)
            else
                Game.SendMessage("%s (col index)", tostring(colID))
            end
        end
    end

    local wpFunc = WeaponTypeShellIndexFunctions[wpType]
    if not wpFunc then
        return nil
    end
    if shellIndex then
        return wpFunc(shellIndex, colID, lang)
    elseif paramMatchIndex then
        return wpFunc(paramMatchIndex, colID, lang)
    end

    return nil
end

-- 狂龙衣
local function IsASkill005(wpType, colID)
    if wpType == CONST.WeaponType.GreatSword then
        if 112 <= colID and colID <= 117 then
            -- 蓄力斩一段，满蓄额外一段
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.SwordShield then
        if colID == 6 then
            -- 平砍
            return true
        end
        if colID == 55 then
            -- 突进斩
            return true
        end
        if colID == 57 then
            -- 上捞
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.DualBlades then
        if 72 <= colID and colID <= 83 then
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.LongSword then
        if 84 <= colID and colID <= 92 then
            -- 84 85 86 直斩
            -- 87 88 89 赤刃
            -- 90 91 92 大回旋、赤回旋、极旋
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.Hammer then
        if 58 <= colID and colID <= 67 then
            -- 58 （拔刀）猛击
            -- 60 （移动）横挥
            -- 61 62 63 左键三段
            -- 64 65 66 （回旋）横挥 返挥 强撩击
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.HuntingHorn then
        if 49 <= colID and colID <= 55 then
            -- 49 左挥 狂化多段_左ぶん回し
            -- 50 右挥 狂化多段_右ぶん回し
            -- 53 后扣 狂化多段_後方攻撃
            -- 52 前扣 狂化多段_前方攻撃
            -- 大地 狂化多段_叩きつけ・2発目
            -- 54 敲打追击（下挥） 狂化多段_コンボ叩きつけ 敲打后接敲打追击
            -- 55 连音 狂化多段_連音攻撃・2発目
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.Lance then
        if 49 <= colID and colID <= 52 then
            -- 52 防御后左键攻击
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.Gunlance then
        if 26 <= colID and colID <= 30 then
            -- 26 突刺
            -- 27 上捞
            -- 28 下砸
            -- 29 横扫
            -- 30 龙杭抬手突刺 ？没打出来
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.SwitchAxe then
        if 71 <= colID and colID <= 78 then
            -- 78 斧突进斩
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.ChargeBlade then
        if 54 <= colID and colID <= 64 then
            return true
        end
        return false
    end
    if wpType == CONST.WeaponType.InsectGlaive then
        if 81 <= colID and colID <= 92 then
            return true
        end
        return false
    end
end

function _M.GetActionNameByHitInfo(hitInfo, lang, character)
    -- local hitID = hitInfo:get_HitID()
    -- local cRuntimeData = hitInfo:get_AttackData()._RuntimeData
    -- local AttackUniqueID = cRuntimeData._AttackUniqueID
    -- local HitID = cRuntimeData._HitID

    local ColIndex = hitInfo:get_AttackIndex()
    local attackIndex = ColIndex._Index

    if character == nil then
        character = Player.GetCharacter()
    end
    local wpType = character:get_Weapon()._WpType

    if wpType == CONST.WeaponType.LightBowgun or wpType == CONST.WeaponType.HeavyBowgun then
        return
    end

    -- 判断各武器的 Shell
    local appShell = hitInfo:get_AttackHit()._Owner:call("getComponent(System.Type)", sdk.typeof("app.AppShell"))
    if appShell then
        local fixedID = GetShellNameByAppShell(wpType, attackIndex, appShell, lang, character)
        if fixedID then
            if type(fixedID) == "string" then
                return fixedID
            elseif type(fixedID) == "number" then
                return GameText.GetActionNameByFixedID(fixedID, lang)
            end
            return
        end
    end

    -- 判断是否是狂龙衣
    local param = hitInfo:get_field("<AttackData>k__BackingField")
    local colID = param._RuntimeData._CollisionDataID._Index
    -- Core.SendMessage("ColID %d", colID)

    if IsASkill005(wpType, colID) then
        return GetASkill005Name(lang)
    end

    -- 判断子弹种类
    local colResource = ColIndex._Resource
    local wpFixup
    
    local attackerHitOwnerName = hitInfo:get_AttackHit()._Owner:get_Name()
    if false then
        Game.SendMessage("HitOwner %s", attackerHitOwnerName)
    end
    -- if IsWeaponShellName(wpType, attackerHitOwnerName) then
    --     wpFixup = WeaponTypeShellColToActionIDFix[wpType]
    -- else
    if Utils.StringStartsWith(attackerHitOwnerName, "WpGunShell") or Utils.StringStartsWith(attackerHitOwnerName, "WpGunConstShell") then
        wpFixup = GunShells
    -- elseif attackerHitOwnerName == "MasterPlayer" then
    --     wpFixup = WeaponTypeColToActionIDFix[wpType]
    end

    if wpFixup then
        -- Game.SendMessage("fixup %d", attackIndex)
        local fixupName = wpFixup[attackIndex]
        if fixupName then
            if type(fixupName) == "number" then
                return GameText.GetActionNameByFixedID(fixupName, lang)
            elseif type(fixupName) == "string" then
                return fixupName
            end
        end
    end
    
    -- local attackHit = hitInfo:get_AttackHit()._Owner -- app.HitController
    -- -- Core.SendMessage("AttackHitType: %s", attackHit:get_type_definition():get_full_name())

    -- -- local DEBUG = require("_CatLib.debug")
    -- -- DEBUG.DebugLogGOComponents(attackHit)

    -- local appShell = hitInfo:get_AttackHit()._Owner:call("getComponent(System.Type)", sdk.typeof("app.AppShell"))
    -- if appShell then
    --     local name = GetShellNameByAppShell(wpType, appShell)
    --     Core.SendMessage("Hit: %s", tostring(name))
    -- end

    -- if not wpFixup then
        -- if ShellActionNameCache[key].ActionName then
            -- Core.SendMessage("evHit: %d,%d, colID: %d, hit owner: %s;\nName: %s, DMG: %0.1f", colResource, attackIndex, colID, attackerHitOwnerName, ShellActionNameCache[key].ActionName, FinalDmg)
        -- else
        --     Core.SendMessage("evHit: %d,%d, hit owner: %s;\nNO NAME, DMG: %0.1f", colResource, attackIndex, attackerHitOwnerName, FinalDmg)
        -- end
    -- end
    -- Core.SendMessage("evHit: %d, hitID: %d, hit owner: %s; %d(AUID)/%d(HitID)", attackIndex, hitID, attackerHitCtrl,AttackUniqueID , HitID)
end


return _M