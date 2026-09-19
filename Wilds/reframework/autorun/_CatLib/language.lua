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
local require = require

local Game = require("_CatLib.game")
local CONST = require("_CatLib.const")
local LibConf = require("_CatLib.config")

local _M = {}

local LANGUAGE
-- via.Language, Jp 0, Eng 1, SChinese 13, TChinese 12
---@return via.Language
function _M.GetLanguage()
    if LibConf.LanguageOverride then
        return LibConf.Language
    end
    if LANGUAGE == nil then
        local guiManager = Game.GetGUIManager()
        if not guiManager then -- dunno why but sometimes it returns nil
            return CONST.LanguageType.English
        end
        LANGUAGE = Game.GetGUIManager():getSystemLanguageToApp()
    end
    return LANGUAGE
end

---@return boolean
function _M.IsChinese(lang)
    if LibConf.LanguageOverride then
        return LibConf.Language == CONST.LanguageType.SimplifiedChinese or LibConf.Language == CONST.LanguageType.TraditionalChinese
    end
    if lang == nil then
        lang = _M.GetLanguage()
    end
    return lang == CONST.LanguageType.SimplifiedChinese or lang == CONST.LanguageType.TraditionalChinese
end

---@param LocalizationText table<via.Language, table>
function _M.GetLocalizedTextConfig(LocalizationText, lang)
    if lang == nil then
        lang = _M.GetLanguage()
    end
    if not LocalizationText[lang] then
        if lang == CONST.LanguageType.TraditionalChinese and LocalizationText[CONST.LanguageType.SimplifiedChinese] then
            return LocalizationText[CONST.LanguageType.SimplifiedChinese]
        elseif lang == CONST.LanguageType.SimplifiedChinese and LocalizationText[CONST.LanguageType.TraditionalChinese] then
            return LocalizationText[CONST.LanguageType.TraditionalChinese]
        else
            lang = CONST.LanguageType.English
        end
    end

    return LocalizationText[lang]
end

return _M