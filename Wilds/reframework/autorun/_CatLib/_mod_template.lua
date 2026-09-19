local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw
local thread = thread
local require = require
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local math = math
local string = string
local table = table
local type = type

local Core = require("_CatLib")
local CONST = require("_CatLib.const")
local Utils = require("_CatLib.utils")

local MOD_NAME = "Mod Template"
local mod = Core.NewMod(MOD_NAME)
-- mod.EnableCJKFont(18) -- use CJK font if needed. Localized CJK font will be picked automatically

if mod.Config.SomeOption == nil then
    mod.Config.SomeOption = true
    mod.SaveConfig()
end

-- runtime data without persistence
mod.Runtime.SomeData = true

local function NewModConfig()
    return {
        SomeOption = true,
    }    
end

-- Recommended: merge current config into default config to avoid nil checks
mod.Config = Utils.MergeTablesRecursive(NewModConfig(), mod.Config)
mod.SaveConfig()

local anotherConfig = mod.LoadConfig("another_mod_config.json")
if anotherConfig == nil then
    anotherConfig = {}
    mod.SaveConfig("another_mod_config.json", anotherConfig)
end

-- Not Recommended: Use mod.HookFunc instead
Core.HookFunc("XXXType", "XXXMethod",
function (args)
    -- do something
end, function (retval)
    return retval
end)

-- Recommended: HookFunc with mod.Config.Enabled check
mod.HookFunc("XXXType", "XXXMethod",
function (args)
    -- do something

    -- pass `this` to post func
    local storage = thread.get_hook_storage()
    storage["this"] = Core.Cast(args[2])
end, function (retval)
    -- Post hook can be nil

    -- get `this` from pre hook
    local storage = thread.get_hook_storage()
    local this = storage["this"]
    storage["this"] = nil
    if this then
        -- do something
    end

    
    -- Post hook can return nil, original retval will be automatically returned
    return retval
end)

-- Recommended: OnLoading, use to initialize/clear data. This can avoid invalid object access
Core.OnLoading(function ()
    -- ClearData()
    -- Init()
end)

-- Recommended: OnUpdateBehavior with mod.Config.Enabled check
mod.OnUpdateBehavior(function ()
    -- CalculateSomething()
end)

-- Not Recommended: Use OnUpdateBehavior instead. OnFrame with mod.Config.Enabled check.
mod.OnFrame(function ()
    -- CalculateSomething()
end)

-- OnFrame with mod.Config.Enabled and mod.Config.Debug check
mod.OnDebugFrame(function ()
    -- DisplaySomeDebugInfo()
end)

-- D2dRegister with mod.Config.Enabled check. Do nothing if no d2d installed
mod.D2dRegister(function ()
    -- DrawSomething()
end)

-- D2dRegister with init function
mod.D2dRegister(function ()
    -- init something
end, function ()
    -- DrawSomething()
end)

-- imgui menu with mod config save, and mod.Config.Enabled/Debug options
-- returns non-false value to save config
mod.Menu(function ()
	local configChanged = false
    local changed = false

    changed, mod.Config.SomeOption = imgui.checkbox("SomeOption", mod.Config.SomeOption)
    configChanged = configChanged or changed
    if changed then
        -- apply sth
    end

    -- return true to save config
    return configChanged
end)
