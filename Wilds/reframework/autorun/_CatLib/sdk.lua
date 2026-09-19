local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local ValueType = ValueType
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local require = require

local CACHE = require("_CatLib.cache")

---@alias HookPreFunc fun(args: any[]): any
---@alias HookPostFunc fun(retval: any): any

local _M = {}

---@alias ReArg ReObj|string|number

---@class ReObj
---@field get_field fun(name: string): ReArg
---@field set_field fun(name: string, val: ReArg)
---@field call fun(method: string, ...: ReArg[])
---@field get_type_definition fun(): ReTypedef
---@field get_address fun(): integer

---@class ReTypedef
---@field get_method fun(name: string): ReMethod
---@field get_field fun(name: string): ReField
---@field get_name fun(): string
---@field get_full_name fun(): string
---@field get_namespace fun(): string

---@class ReMethod
---@field call fun(instance: ReObj, ...: ReArg[]): ReArg

---@class ReField
---@field get_data fun(instance: ReObj|nil): ReArg

---@param typename string type name
---@return ReTypedef
function _M.Typedef(typename)
    return sdk.find_type_definition(typename)
end

---@return ReObj
function _M.Cast(arg)
    return sdk.to_managed_object(arg)
end

local TypeGUID = sdk.find_type_definition("System.Guid")
---@return System.Guid
function _M.CastGUID(arg)
    return sdk.to_valuetype(arg, TypeGUID)
end

---@class WrappedTypedef
---@field typedef ReTypedef
---@field typename string
---@field fields table<string, ReField>
---@field static_methods table<string, ReField>
---@field get_method fun(self: WrappedTypedef, ...): any
---@field StaticCall fun(self: WrappedTypedef, method: string, ...): any
---@field StaticField fun(self: WrappedTypedef, field: string): any

---@param typename string type name
---@return WrappedTypedef # returns a wrapped typedef, with WrapType:StaticCall("method()", args ...)
function _M.WrapTypedef(typename)
    local typedef = _M.Typedef(typename)

    ---@type WrappedTypedef
    local Wrap = {}
    Wrap.typedef = typedef
    Wrap.typename = typename
    Wrap.fields = {}
    Wrap.static_methods = {}

    function Wrap.get_method(self, ...)
        return self:get_method(...)
    end

    function Wrap.StaticCall(self, methodSig, ...)
        local typename = self.typename
        local method = self.static_methods[methodSig]
        if method == nil then
            method = self.typedef:get_method(methodSig)
            self.static_methods[methodSig] = method
        end

        return method:call(nil, ...)
    end

    function Wrap.StaticField(self, fieldName)
        local typename = self.typename
        local field = self.fields[fieldName]
        if field == nil then
            local field = self.typedef:get_field(fieldName)
            self.fields[fieldName] = field
        end

        return self.fields[fieldName]:get_data()
    end

    return Wrap
end

---@return ReMethod
function _M.TypeMethod(typename, methodName)
    local method = sdk.find_type_definition(typename):get_method(methodName)
    if not method then
        log.error(string.format("type %s method %s not found", typename, methodName))
    end
    return method
end

---@return ReField
function _M.TypeField(typename, fieldName)
    local field = sdk.find_type_definition(typename):get_field(fieldName)
    if not field then
        log.error(string.format("type %s field %s not found", typename, fieldName))
    end
    return field
end

---@return System.Type
function _M.Typeof(typename)
    return sdk.typeof(typename)
end

function _M.GetSingleton(typename)
    if CACHE.Singletons[typename] == nil then
        CACHE.Singletons[typename] = sdk.get_managed_singleton(typename)
    end

	return CACHE.Singletons[typename]
end

---@param typename string type name
function _M.GetNativeSingleton(typename)
    if CACHE.Singletons[typename] == nil then
        CACHE.Singletons[typename] = sdk.get_native_singleton(typename)
    end

	return CACHE.Singletons[typename]
end

---@class WrappedNativeSingleton
---@field singleton any
---@field typename string
---@field typedef ReTypedef
---@field call fun(self, method: string, ...: ReArg[]): any

---@param typename string type name
---@return WrappedNativeSingleton # returns a wrapped native singleton, with WrapNativeSingleton:call("method()", args ...)
function _M.GetWrapNativeSingleton(typename)
    local singleton = _M.GetNativeSingleton(typename)
    if CACHE.WrapSingletons[typename] == nil then
        local Wrap = {}
        Wrap.singleton = singleton
        Wrap.typename = typename
        Wrap.typedef = _M.Typedef(typename)
        function Wrap.call(self, method, ...)
            return sdk.call_native_func(self.singleton, self.typedef, method, ...);
        end

        CACHE.WrapSingletons[typename] = Wrap
    end
    return CACHE.WrapSingletons[typename]
end

---@class WrappedValueType
---@field typedef ReTypedef
---@field value any
---@field set_field fun(self: WrappedValueType, field: string, value: ReArg)

---@return WrappedValueType
function _M.NewWrapValueType(typename)
    ---@type WrappedValueType
    local Wrap = {}
    Wrap.typedef = _M.Typedef(typename)
    Wrap.value = ValueType.new(Wrap.typedef)

    function Wrap.set_field(self, field, value)
        return sdk.set_native_field(self.value, self.typedef, field, value)
    end

    return Wrap
end

function _M.Ctor(typename, method, ...)
	local output = (sdk.create_instance(typename) or sdk.create_instance(typename, true)):add_ref()

	if output then
        if method == nil then
            if output:get_type_definition():get_method(".ctor()") then
                output:call(".ctor()")
            end
            return output
        else
            if output:get_type_definition():get_method(method) then
                output:call(method, ...)
            end
            return output
        end
	end
end

---@param typename string
---@param method string ctor method signature
function _M.NativeCtor(typename, method, ...)
	local output = (sdk.create_instance(typename) or sdk.create_instance(typename, true)):add_ref()

	if output then
        if method == nil then
            sdk.call_native_func(output, _M.Typedef(typename), ".ctor()")
            return output
        else
            sdk.call_native_func(output, _M.Typedef(typename), method, ...)
            return output
        end
	end
end

local HOOK_PRE_DEFAULT = function (args)
end

local HOOK_POST_DEFAULT = function (retval)
    return retval
end

---@param typename string
---@param method string
---@param preFunc HookPreFunc
---@param postFunc HookPostFunc
function _M.HookFunc(typename, methodName, preFunc, postFunc)
    -- log.info(tostring(typename) .. ":" .. tostring(methodName) .. " hooking")
    if typename == nil or methodName == nil then return end
    if preFunc == nil then preFunc = HOOK_PRE_DEFAULT end
    if postFunc == nil then postFunc = HOOK_POST_DEFAULT end

    local type = _M.Typedef(typename)
    if type == nil then
        log.error("Unknown type hook: " .. tostring(typename) .. ":" .. tostring(methodName))
        return
    end
    local method = type:get_method(methodName)
    if method == nil then
        log.error("Unknown type method: " .. tostring(typename) .. ":" .. tostring(method))
        return
    end
    sdk.hook(
        method,
        preFunc, function (retval)
            local ret = postFunc(retval)
            if ret == nil then return retval end
            return ret
        end
    )

    -- log.info(typename .. ":" .. methodName .. " hooked.")
end

function _M.DisabledHookFunc(type, method, preFunc, postFunc) end

function _M.DerefPtr(ptr)
    local fake_int64 = sdk.to_valuetype(ptr, "System.UInt64")
    if not fake_int64 then
        return nil
    end
    local deref = fake_int64:get_field("m_value")

    return deref
end

---@param func fun()
function _M.OnFrame(func)
    re.on_frame(func)
end

local TargetAccessKeyType = sdk.find_type_definition("app.TARGET_ACCESS_KEY")

---@param category app.TARGET_ACCESS_KEY.CATEGORY
---@param index integer
---@return app.TARGET_ACCESS_KEY
function _M.NewTargetAccessKey(category, index)
    local key = ValueType.new(TargetAccessKeyType)
    sdk.set_native_field(key, TargetAccessKeyType, "Category", category)
    sdk.set_native_field(key, TargetAccessKeyType, "UniqueIndex", index)

    return key
end

local ActionIDType = sdk.find_type_definition("ace.ACTION_ID")

---@param category integer
---@param index integer
---@return ace.ACTION_ID
function _M.NewActionID(category, index)
    local instance = ValueType.new(ActionIDType)
    sdk.set_native_field(instance, ActionIDType, "_Category", category)
    sdk.set_native_field(instance, ActionIDType, "_Index", index)

    return instance
end

---@param str string
---@return System.Guid
function _M.NewGuid(str)
    return sdk.create_instance("System.Guid", false):Parse(str)
end

---@param m_obj System.Guid
---@return string
function _M.FormatGUID(m_obj)
    return string.format("%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x", m_obj.mData1, m_obj.mData2, m_obj.mData3, m_obj.mData4_0, m_obj.mData4_1, m_obj.mData4_2, m_obj.mData4_3, m_obj.mData4_4, m_obj.mData4_5, m_obj.mData4_6, m_obj.mData4_7)
end

return _M
