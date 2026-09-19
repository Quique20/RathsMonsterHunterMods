local pairs = pairs
local setmetatable = setmetatable

local _M = {
}

local Cache = {
    Singletons = {},
    WrapSingletons = {},
}

local function ClearCache()
    for key in pairs(Cache.Singletons) do
        Cache.Singletons[key] = nil
    end
    for key in pairs(Cache.WrapSingletons) do
        Cache.WrapSingletons[key] = nil
    end
    for key in pairs(Cache) do
        if key ~= "Singletons" and key ~= "WrapSingletons" then
            Cache[key] = nil
        end
    end
end

local mt = {
    __index = function(_, key)
        if key == "ClearCache" then return ClearCache end
        return Cache[key]
    end,
    __newindex = function(_, key, value)
        Cache[key] = value
    end
}

setmetatable(_M, mt)

return _M