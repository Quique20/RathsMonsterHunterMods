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

local Uitls = require("_CatLib.utils")

local _M = {}

---@type app.PlayerCommand.TYPE
_M.CommandType = {
    
}

---@type table<string, app.WeaponDef.TYPE>
_M.WeaponType = {
    FIRST = 0,
    GreatSword = 0,
    SwordShield = 1,
    DualBlades = 2,
    LongSword = 3,
    Hammer = 4,
    HuntingHorn = 5,
    Lance = 6,
    Gunlance = 7,
    SwitchAxe = 8,
    ChargeBlade = 9,
    InsectGlaive = 10,
    Bow = 11,
    HeavyBowgun = 12,
    LightBowgun = 13,
    LAST = 13,
}

_M.WeaponAttrType = {
    None = 0,
    Fire = 1,
    Water = 2,
    Ice = 3,
    Elec = 4,
    Dragon = 5,
    Poison = 6,
    Paralyse = 7,
    Sleep = 8,
    Blast = 9,
}

---@type table<string, via.Language>
_M.LanguageType = {
    Japanese = 0,
    English = 1,
    Korean = 11,
    TraditionalChinese = 12,
    SimplifiedChinese = 13,
}

 -- _Em is caused by Env Life
---@type table<string, app.EnemyDef.CONDITION>
 _M.EnemyConditionType = {
    Angry = 0,
    Tired = 1,
    Depletion = 2,
    Poison = 3, -- OK
    Poison_Em = 4,
    Paralyse = 5, -- OK
    Paralyse_Em = 6,
    Sleep = 7, -- OK
    Sleep_Em = 8,
    Blast = 9,
    BlastReaction = 10,
    Blast_Em = 11,
    BlastReaction_Em = 12,
    Ride = 13, -- OK
    Stamina = 14,
    Stun = 15, -- OK
    Stun_Em = 16,
    Capture = 17,
    Flash = 18, -- OK
    Flash_Em = 19, -- OK
    Ear = 20,
    Koyasi = 21, -- shit
    Shit = 21, -- koyasi
    WeakAttrSlinger = 22,
    WeakAttrBoost = 23,
    LightPlant = 24,
    Parry = 25, -- OK
    Parry_NPC = 26,
    Block = 27, -- OK
    Block_NPC = 28,
    SandDig = 29, -- Shown in sand area, but effect unknown
    Scar = 30, -- Sometimes shown but effect unknown
    FieldPitfall = 31,
    SmokeBall = 32,
    EmLead = 33, -- Unknown
    SkillStabbing_P1 = 34, -- 锁刃刺击
    SkillStabbing_P2 = 35, -- 锁刃刺击
    SkillStabbing_P3 = 36, -- 锁刃刺击
    SkillStabbing_P4 = 37, -- 锁刃刺击
    Ryuki = 38,
    Trap_Fall = 39, -- OK
    Trap_Paralyse = 40, -- OK
    Trap_Ivy = 41, -- OK
    Trap_Paralyse_Animal = 42,
    Trap_Paralyse_Otomo = 43,
    Trap_Bound_NPC = 44,
    Trap_Slinger = 45,

    MAX = 46,
}

---@type table<string, app.EnemyDef.PARTS_TYPE>
_M.EnemyPartType = {
    FULL_BODY = 0,
    HEAD = 1,
    UPPER_BODY = 2,
    BODY = 3,
    TAIL = 4,
    TAIL_TIP = 5,
    NECK = 6,
    TORSO = 7,
    STOMACH = 8,
    BACK = 9,
    FRONT_LEGS = 10,
    LEFT_FRONT_LEG = 11,
    RIGHT_FRONT_LEG = 12,
    HIND_LEGS = 13,
    LEFT_HIND_LEG = 14,
    RIGHT_HIND_LEG = 15,
    LEFT_LEG = 16,
    RIGHT_LEG = 17,
    LEFT_LEG_FRONT_AND_REAR = 18,
    RIGHT_LEG_FRONT_AND_REAR = 19,
    LEFT_WING = 20,
    RIGHT_WING = 21,
    ASS = 22,
    NAIL = 23,
    LEFT_NAIL = 24,
    RIGHT_NAIL = 25,
    TONGUE = 26,
    PETAL = 27,
    VEIL = 28,
    SAW = 29,
    FEATHER = 30,
    TENTACLE = 31,
    UMBRELLA = 32,
    LEFT_FRONT_ARM = 33,
    RIGHT_FRONT_ARM = 34,
    LEFT_SIDE_ARM = 35,
    RIGHT_SIDE_ARM = 36,
    LEFT_HIND_ARM = 37,
    RIGHT_HIND_ARM = 38,
    Head = 39, -- WTF is this?
    CHEST = 40,
    MANTLE = 41,
    MANTLE_UNDER = 42,
    POISONOUS_THORN = 43,
    ANTENNAE = 44,
    LEFT_WING_LEGS = 45,
    RIGHT_WING_LEGS = 46,
    WATERFILM_RIGHT_HEAD = 47,
    WATERFILM_LEFT_HEAD = 48,
    WATERFILM_RIGHT_BODY = 49,
    WATERFILM_LEFT_BODY = 50,
    WATERFILM_RIGHT_FRONT_LEG = 51,
    WATERFILM_LEFT_FRONT_LEG = 52,
    WATERFILM_TAIL = 53,
    WATERFILM_LEFT_TAIL = 54,
    MOUTH = 55,
    TRUNK = 56,
    LEFT_WING_BLADE = 57,
    RIGHT_WING_BLADE = 58,
    FROZEN_CORE_HEAD = 59,
    FROZEN_CORE_TAIL = 60,
    FROZEN_CORE_WAIST = 61,
    FROZEN_BIGCORE_BEFORE = 62,
    FROZEN_BIGCORE_AFTER = 63,
    NOSE = 64,
    HEAD_WEAR = 65,
    HEAD_HIDE = 66,
    WING_ARM = 67,
    WING_ARM_WEAR = 68,
    LEFT_WING_ARM_WEAR = 69,
    RIGHT_WING_ARM_WEAR = 70,
    LEFT_WING_ARM = 71,
    RIGHT_WING_ARM = 72,
    LEFT_WING_ARM_HIDE = 73,
    RIGHT_WING_ARM_HIDE = 74,
    CHELICERAE = 75,
    BOTH_WINGS = 76,
    BOTH_WINGS_BLADE = 77,
    BOTH_LEG = 78,
    ARM = 79,
    LEG = 80,
    HIDE = 81,
    SHARP_CORNERS = 82,
    NEEDLE_HAIR = 83,
    PARALYSIS_CORNERS = 84,
    HEAD_OIL = 85,
    UMBRELLA_OIL = 86,
    TORSO_OIL = 87,
    ARM_OIL = 88,
    WATERFILM_RIGHT_TAIL = 89,
}

---@type table<string, app.HitDef.CONDITION>
_M.AttackConditionType = {
    NONE = 0,
    POISON = 1,
    DEADLY_POISON = 2,
    PARALYSE = 3,
    SLEEP = 4,
    BLAST = 5,
    BLEED = 6,
    STAMINA = 7,
    STENCH = 8,
    DEFENCE_DOWN = 9,
    FREEZE = 10,
    FRENZY = 11,
    STICKY = 12,
    FIRE = 13,
    WATER = 14,
    ELEC = 15,
    ICE = 16,
    DARGON = 17,
    MAX = 18,
}

---@type table<string, app.Hit.CRITICAL_TYPE>
_M.CriticalType = {
    None = 0,
    Critical = 1,
    Negative = 2,
}

---@type table<string, app.EnemyDef.CrownType>
_M.CrownType = {
    None = 0,
    Small = 1,
    Big = 2,
    King = 3,
}
_M.CrownTypeNames = Uitls.GetEnumMap("app.EnemyDef.CrownType")

---@type table<app.PlayerCommand.TYPE, string>
_M.PlayerCommandTypeNames = Uitls.GetEnumMap("app.PlayerCommand.TYPE")

---@type table<app.EnemyDef.CONDITION, string>
_M.EnemyConditionTypeNames = Uitls.GetEnumMap("app.EnemyDef.CONDITION")

---@type table<app.EnemyDef.PARTS_TYPE, string>
_M.EnemyPartsTypeNames = Uitls.GetEnumMap("app.EnemyDef.PARTS_TYPE")

return _M