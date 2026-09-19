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

local Utils = require("_CatLib.utils")

local _M = {}

---@param go via.GameObject
function _M.DebugLogGOComponents(go)
    if not go then
        log.info("GameObject: nil")
        return
    end

    local comps = go:get_Components()

    log.info(string.format("GameObject: %s @ %x", tostring(go:get_Name()), go:get_address()))
    Utils.ForEach(comps, function (comp)
        local typename = comp:get_type_definition():get_full_name()
        log.info(typename)
    end)
end


---@param obj table
---@param indent number
---@param ignoreDefault boolean
function _M.DebugTable(obj, indent, ignoreDefault)
    if indent == nil then
        indent = 0
    end
    if ignoreDefault == nil then
        ignoreDefault = true
    end

    for k, v in pairs(obj) do
	    if type(v) == "table" then
            _M.DebugTable(v, indent + 1)
        else
            if v == nil and ignoreDefault then
                goto continue
            end
            if ignoreDefault and type(v) == "number" and v == 0 then
                goto continue
            end
            if ignoreDefault and type(v) == "string" and v == "" then
                goto continue
            end

            local padding = string.rep("  ", indent)
            local msg = string.format("%s%s (%s): %s", padding, tostring(k), tostring(type(k)), tostring(v))
            imgui.text(msg)
        end
        ::continue::
    end
    ::continue::
end

---@param obj table
---@param indent number
---@param ignoreDefault boolean
function _M.LogTable(obj, indent, ignoreDefault)
    if indent == nil then
        indent = 0
    end
    if ignoreDefault == nil then
        ignoreDefault = true
    end

    log.info(string.format("LogTable: %s", tostring(obj)))
    for k, v in pairs(obj) do
	    if type(v) == "table" then
            _M.LogTable(v, indent + 1)
        else
            if v == nil and ignoreDefault then
                goto continue
            end
            if ignoreDefault and type(v) == "number" and v == 0 then
                goto continue
            end
            if ignoreDefault and type(v) == "string" and v == "" then
                goto continue
            end

            local padding = string.rep("  ", indent)
            local msg = string.format("%s%s (%s): %s", padding, tostring(k), tostring(type(k)), tostring(v))
            log.info(msg)
        end
        ::continue::
    end
    ::continue::
end

return _M