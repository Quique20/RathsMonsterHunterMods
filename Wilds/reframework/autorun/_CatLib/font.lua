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
local type = type

local CONST = require("_CatLib.const")
local Language = require("_CatLib.language")

local LibConf = require("_CatLib.config")

local _M = {}

local CNFont = {
    FONT_FAMILY = "Noto Sans SC",
    FONT_NAME = 'NotoSansSC-Bold.otf',
    GLYPH_RANGES = {
        0x0020, 0x00FF, -- Basic Latin + Latin Supplement
        0x0370, 0x03FF, -- Greek alphabet
        0x2000, 0x206F, -- General Punctuation
        0x2160, 0x217F, -- Roman Numbers
        0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
        0x31F0, 0x31FF, -- Katakana Phonetic Extensions
        0xFF00, 0xFFEF, -- Half-width characters
        0x4e00, 0x9FAF, -- CJK Ideograms
        0,
    }
}

local FallbackFont = CNFont

local LanguagePack = {
    [CONST.LanguageType.SimplifiedChinese] = CNFont,
    [CONST.LanguageType.TraditionalChinese] = CNFont,
    [CONST.LanguageType.Korean] = {
        FONT_FAMILY = "Noto Sans KR",
        FONT_NAME = "NotoSansKR-Bold.otf",
        GLYPH_RANGES = {
            0x0020, 0x00FF, -- Basic Latin + Latin Supplement
            0x0370, 0x03FF, -- Greek alphabet
            0x2000, 0x206F, -- General Punctuation
            0x2160, 0x217F, -- Roman Numbers
            0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
            0x3130, 0x318F, -- Hangul Compatibility Jamo
            0x31F0, 0x31FF, -- Katakana Phonetic Extensions
            0xFF00, 0xFFEF, -- Half-width characters
            0x4e00, 0x9FAF, -- CJK Ideograms
            0xA960, 0xA97F, -- Hangul Jamo Extended-A
            0xAC00, 0xD7A3, -- Hangul Syllables
            0xD7B0, 0xD7FF, -- Hangul Jamo Extended-B
            0,
        },
    },
    [CONST.LanguageType.Japanese] = {
        FONT_FAMILY = "Noto Sans JP",
        FONT_NAME = "NotoSansJP-Regular.otf",
        GLYPH_RANGES = {
            0x0020, 0x00FF, -- Basic Latin + Latin Supplement
            0x0370, 0x03FF, -- Greek alphabet
            0x2000, 0x206F, -- General Punctuation
            0x2160, 0x217F, -- Roman Numbers
            0x3000, 0x30FF, -- CJK Symbols and Punctuations, Hiragana, Katakana
            0x31F0, 0x31FF, -- Katakana Phonetic Extensions
            0x4e00, 0x9FFF, -- CJK Ideograms
            0xFF00, 0xFFEF, -- Half-width characters
            0,
        },
    },
}

local function PickLanguageFont(lang)
    if lang == nil then
        return FallbackFont
    end

    local pack = LanguagePack[lang]

    if not pack then
        -- Fallback
        pack = FallbackFont
    end

    return pack
end

local CJKFontTable = {}

local DEFAULT_FONT_SIZE = 18

function _M.GetNormalizedFontSize(size)
    if size == DEFAULT_FONT_SIZE then
        size = imgui.get_default_font_size()
    end
    if size == nil or type(size) ~= "number" or size <= 0 then
        size = imgui.get_default_font_size()
    end

    size = math.ceil(size* LibConf.FontScale *LibConf.UIScale)
    return size
end

---@param size number? font size, default 18
---@return any # font object
function _M.LoadImguiCJKFont(size)
    size = _M.GetNormalizedFontSize(size)
    if CJKFontTable[size] == nil then
        local lang = Language.GetLanguage()
        local cfg = PickLanguageFont(lang)
        log.info(string.format("Loading font with size %0.1f", size))
        CJKFontTable[size] = imgui.load_font(cfg.FONT_NAME, size, cfg.GLYPH_RANGES)
        log.info(string.format("Loaded %d", CJKFontTable[size]))
    end

    return CJKFontTable[size]
end

local D2dDefaultFontTable = {}
---@param size number|nil
---@param bold boolean|nil
---@param italic boolean|nil
function _M.LoadD2dFont(size, bold, italic)
    size = _M.GetNormalizedFontSize(size)
    local key = tostring(size)
    if bold then
        key = key .. "_B"
    end
    if italic then
        key = key .. "_I"
    end
    if D2dDefaultFontTable[key] == nil then
        local lang = Language.GetLanguage()
        local cfg = PickLanguageFont(lang)
        D2dDefaultFontTable[key] = d2d.Font.new(cfg.FONT_FAMILY, size, bold, italic)
    end
    return D2dDefaultFontTable[key]
end

return _M