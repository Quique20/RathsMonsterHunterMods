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

local _M = {}

local GetUpTimeSecondMethod = sdk.find_type_definition("via.Application"):get_method("get_UpTimeSecond")
function _M.GetTime()
    return GetUpTimeSecondMethod:call(nil)
end
local GetElapsedTimeMillisecondMethod = sdk.find_type_definition("via.Application"):get_method(
    "get_CurrentElapsedTimeMillisecond")
function _M.GetElapsedTimeMs()
    return GetElapsedTimeMillisecondMethod:call(nil)
end
local GetDeltaTimeMethod = sdk.find_type_definition("via.Application"):get_method("get_DeltaTime")
-- local GetDeltaTimeMethod = sdk.find_type_definition("ace.WorkRate"):get_method("getAppDeltaTime()")
function _M.GetDeltaTime()
    return GetDeltaTimeMethod:call(nil)
end

---@param total number
---@return string
function _M.GetTimeString(total, alwaysMinute, digits)
    if digits == nil then
        digits = 0
    end
    local digistFormat = "%02." .. tostring(digits) .. "f"

    local min = math.floor(total / 60.0)
    local secs = total % 60
    if min > 0 or alwaysMinute then
        return string.format("%02d:" .. digistFormat, min, secs)
    else
        return string.format(digistFormat, secs)
    end
end

---@param name string
---@return boolean
function _M.IsValidName(name)
    if name == nil or name == "" or _M.StringStartsWith(name, "[INVALID") then
        return false
    end
    if _M.StringContains(name, "Rejected") then
        return false
    end
    if _M.StringContains(name, "---") then
        return false
    end
    return true
end

function _M.GetTypeIterateFunction(typename)
    local type = sdk.find_type_definition(typename)
    if not type then
        return nil, nil
    end
    return type:get_method("get_Count"), type:get_method("get_Item")
end

_M.ForEachBreak = -1
---@param list ReObj[]|List<ReObj>|T[] # CSharp array or list
---@param func fun(item: ReObj, index: number, length: number)
---@param get_Count REMethodDefinition
---@param get_Item REMethodDefinition
function _M.ForEach(list, func, get_Count, get_Item)
    if list == nil then
        return
    end

    if type(list) == "table" then
        -- 退化为 Lua Table：
        -- 1. 检查是否为纯数组（或者至少我们希望按顺序遍历）
        -- #t > 0 是一个常用的启发式判断
        if #list == 0 then
            return
        end
        if #list > 0 then
            for i = 1, #list do
                local ret = func(list[i], i-1, #list)
                if ret == _M.ForEachBreak then
                    break
                end
            end
        end
    end


    if not get_Count then
        get_Count = list.get_Count
    end
    if not get_Count then
        return
    end

    if not get_Item then
        get_Item = list.get_Item
    end
    if not get_Item then
        return
    end

    local len = get_Count:call(list)
    for i = 0, len - 1, 1 do
        local item = get_Item:call(list, i)
        local ret = func(item, i, len)
        if ret == _M.ForEachBreak then
            break
        end
    end
end

---@param dict System.Dictionary
---@param func fun(k: any, v: any)
function _M.ForEachDict(dict, func)
    if not dict then
        return
    end
    local entries = dict:get_field('_entries')
    _M.ForEach(entries, function(entry)
        local k = entry:get_field("key")
        local v = entry:get_field("value")
        return func(k, v)
    end)
end

---@param table table
---@param key any
---@return boolean
function _M.IsInTable(table, key)
    for k, v in pairs(table) do
        if v == key then
            return true
        end
    end
    return false
end

---@param dict System.Dictionary
---@param key any
function _M.TryGetDict(dict, key)
    if not dict then
        return
    end
    if dict:ContainsKey(key) then
        return dict:get_Item(key)
    end
    return nil
end

local EnumValToNameMapCache = {}
local EnumNameToValMapCache = {}
---@param enumTypeName string
---@param cache boolean use cache
---@return table<integer, string>, table<string, integer>
function _M.GetEnumMap(enumTypeName, cache)
    if cache and EnumValToNameMapCache[enumTypeName] ~= nil and EnumNameToValMapCache[enumTypeName] ~= nil then
        return EnumValToNameMapCache[enumTypeName], EnumNameToValMapCache[enumTypeName]
    end

    local t = sdk.find_type_definition(enumTypeName)
    if not t then
        return {}, {}
    end

    local fields = t:get_fields()
    local valToName = {}
    local nameToVal = {}

    for i, field in ipairs(fields) do
        if field:is_static() then
            local name = field:get_name()
            local raw_value = field:get_data(nil)
            valToName[raw_value] = name
            nameToVal[name] = raw_value
        end
    end

    if cache then
        EnumValToNameMapCache[enumTypeName] = valToName
        EnumNameToValMapCache[enumTypeName] = nameToVal
    end
    return valToName, nameToVal
end

function _M.EnumToFixed(enumTypeName, value)
    local originNames, originVals = _M.GetEnumMap(enumTypeName, true)
    local fixedNames, fixedVals = _M.GetEnumMap(enumTypeName .. "_Fixed", true)

    local name = originNames[value]
    return fixedVals[name]
end

function _M.FixedToEnum(enumTypeName, value)
    local originNames, originVals = _M.GetEnumMap(enumTypeName, true)
    local fixedNames, fixedVals = _M.GetEnumMap(enumTypeName .. "_Fixed", true)

    local name = fixedNames[value]
    return originVals[name]
end

---@param t table
---@return integer
function _M.GetTableSize(t)
    if type(t) ~= "table" then
        return 0
    end
    local i = 0
    for _, _ in pairs(t) do
        i = i + 1
    end
    return i
end

---@param float number
---@return string
function _M.FloatFixed1(float)
    if not float then
        return "nil"
    end
    return string.format("%0.1f", float)
end

---@param a integer[]
---@param b integer[]
function _M.CSharpIntArrayEquals(a, b)
    if a == nil and b == nil then
        return true
    end
    if a == nil or b == nil then
        return false
    end

    local len = a:get_Count()
    if len ~= b:get_Count() then
        return false
    end

    for i = 0, len - 1, 1 do
        local l = a:get_Item(i)
        local r = b:get_Item(i)
        if l ~= r then
            return false
        end
    end

    return true
end

--- 将多个表合并为一个表。
--- 后面的表的字段会覆盖前面表的字段。
--- 仅合并根部的表，不会递归合并子表。需要递归合并，使用 `MergeTablesRecursive`
---@param result table
---@vararg table[]
---@return table
function _M.MergeTables(result, ...)
    local tables = {...}
    local changed = false
    for i, tbl in ipairs(tables) do
        if tbl == nil then
            goto continue_merge_tables
        end
        if type(tbl) ~= "table" then
            error(string.format("MergeTables: expected a table at index %d, got %s", i, type(tbl)))
        end

        for k, v in pairs(tbl) do
            if result[k] ~= v then
                result[k] = v
                changed = true
            end
        end

        ::continue_merge_tables::
    end

    return result, changed
end

---@param str string
---@param target string
---@return boolean
function _M.StringStartsWith(str, target)
    return string.sub(str, 1, string.len(target)) == target
end
---@param str string
---@param target string
---@return boolean
function _M.StringEndsWith(str, target)
    return string.sub(str, -#target) == target
end

---@param str string
---@param target string
---@return boolean
function _M.StringContains(str, target)
    return string.find(str, target, 1, true)
end

--- 将多个表递归合并为一个表，包含子表。
--- 后面的表的字段会覆盖前面表的字段。
---
--- 注: 如果同一字段不同类型，则后面的表的字段会覆盖前面表的字段。
---     如果同一字段都是表，则会递归合并。
---@param result table
---@vararg table[]
---@return table
function _M.MergeTablesRecursive(result, ...)
    local tables = {...}
    local changed = false
    for i, tbl in ipairs(tables) do
        if tbl == nil then
            goto continue_merge_tables_recursive
        end
        if type(tbl) ~= "table" then
            error(string.format("MergeTables: expected a table at index %d, got %s", i, type(tbl)))
        end

        for k, v in pairs(tbl) do
            if type(v) == "table" then
                if result[k] == nil or type(result[k]) ~= "table" then
                    result[k] = {}
                    changed = true
                end
                local tableChanged = false
                result[k], tableChanged = _M.MergeTablesRecursive(result[k], v)
                changed = changed or tableChanged
            else
                if result[k] ~= v then
                    result[k] = v
                    changed = true
                end
            end
        end

        ::continue_merge_tables_recursive::
    end

    return result, changed
end

-- Re-export methods

---@type FormatPretty
local format_pretty = require("_CatLib.utils.format_pretty")
if format_pretty then
    _M["format"] = format_pretty
    _M["format_table"] = format_pretty.table
    _M["format_table_pretty"] = format_pretty.table_pretty
end

local try_catch = require("_CatLib.utils.try_catch")
if try_catch then
    _M["try"] = try_catch
end

---@type LazyStatic
local lazy_static = require("_CatLib.utils.lazy_static")
if lazy_static then
    _M["new_lazy"] = lazy_static.new
end

return _M
