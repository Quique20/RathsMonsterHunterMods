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


local SDK = require("_CatLib.sdk")
local CACHE = require("_CatLib.cache")
local Singletons = require("_CatLib.game.singletons")


local _M = {}

---@return boolean
function _M.IsInBattle()
    local mgr = Singletons.GetBattleMusicManager()
    if mgr == nil then
        -- log.info("BattleMusicManager is nil, skipped")
        return false
    end
    return mgr:get_IsBattle()
end

---@return boolean
function _M.IsInTrainingArea()
    local player = _M.GetCharacter()
    if not player then
        return false
    end
    local ctrl = player:get_ASkillController()
    if not ctrl then
        return false
    end
    return ctrl:get_IsInTrainingArea()
end

---@return app.cPlayerManageInfo
function _M.GetInfo()
    if CACHE.PlayerInfo == nil and Singletons.GetPlayerManager() then
        CACHE.PlayerInfo = Singletons.GetPlayerManager():getMasterPlayer()
    end
    return CACHE.PlayerInfo
end

---@return app.HunterCharacter
function _M.GetCharacter()
    if CACHE.PlayerCharacter == nil and _M.GetInfo() then
        CACHE.PlayerCharacter = _M.GetInfo():get_Character()
    end
    return CACHE.PlayerCharacter
end

function _M.IsWearMantle()
    if _M.GetCharacter() then
        local armorCtrl = _M.GetCharacter():get_ArmorCtrl()
        if not armorCtrl then return false end
        -- its name is "Is Off", but it is True when you wear Mantle, wtf
        -- _IsPutOnMantle equals _IsMantleOff
        return armorCtrl._IsMantleOff
    end
    return false
end

---@return app.cPlayerCatalogHolder?
function _M.GetPlayerCatalogHolder()
    if Singletons.GetPlayerManager() then
        return Singletons.GetPlayerManager():get_Catalog()
    end
    return nil
end

---@return app.Weapon?
function _M.GetWeapon()
    if _M.GetCharacter() then
        return _M.GetCharacter():get_Weapon()
    end
end

---@return app.Weapon?
function _M.GetSubWeapon()
    if _M.GetCharacter() then
        return _M.GetCharacter():get_ReserveWeapon()
    end
end

---@return app.WeaponDef.TYPE?
function _M.GetWeaponType()
    if _M.GetWeapon() then
        return _M.GetWeapon()._WpType
    end
end

---@return app.WeaponDef.TYPE?
function _M.GetSubWeaponType()
    if _M.GetSubWeapon() then
        return _M.GetSubWeapon()._WpType
    end
end

---@return app.cHunterWeaponHandlingBase?
function _M.GetWeaponHandling()
    if _M.GetCharacter() then
        return _M.GetCharacter():get_WeaponHandling()
    end
end

---@return app.cHunterWeaponHandlingBase?
function _M.GetSubWeaponHandling()
    if _M.GetCharacter() then
        return _M.GetCharacter():get_ReserveWeaponHandling()
    end
end

---@return via.GameObject
function _M.GetGameObject()
    if CACHE.PlayerGameObject == nil and _M.GetInfo() then
        CACHE.PlayerGameObject = _M.GetInfo():get_Object()
    end
    return CACHE.PlayerGameObject
end

---@return via.motion.Motion
function _M.GetMotion()
    if CACHE.PlayerMotion == nil and _M.GetInfo() then
        CACHE.PlayerMotion = _M.GetGameObject():getComponent(SDK.Typeof("via.motion.Motion"))
    end
    return CACHE.PlayerMotion
end

return _M