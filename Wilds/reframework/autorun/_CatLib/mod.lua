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

local FontUtils = require("_CatLib.font")
local Game = require("_CatLib.game")
local Utils = require("_CatLib.utils")
local LanguageUtils = require("_CatLib.language")
local Draw = require("_CatLib.draw")
local LibConf = require("_CatLib.config")
local IsD2d = LibConf.RenderBackend == 1

local _M = {}

local HOOK_PRE_DEFAULT = function (args)
end

local HOOK_POST_DEFAULT = function (retval)
    return retval
end

---@class ModConfig
---@field Enable boolean
---@field Debug boolean

---@class ModCreator
---@field LoadConfig fun(filename: string|nil): ModConfig
---@field SaveConfig fun(filename: string|nil, conf: table|nil)
---@field EnableCJKFont fun(size: number|nil)
---@field Menu fun(func: fun(): boolean)
---@field SubMenu fun(name: string, func: fun(): boolean)
---@field SubDebugMenu fun(name: string, func: fun(): boolean)
---@field ShowCost fun(tag: string|nil)
---@field InitCost fun(tag: string)
---@field CostCompare fun(tag: string, targetTag: string)
---@field RecordCost fun(tag: string, func: fun(), sum: boolean)
---@field OnUpdateBehavior fun(func: fun())
---@field OnPreUpdateBehavior fun(func: fun())
---@field OnFrame fun(func: fun())
---@field OnDebugFrame fun(func: fun())
---@field D2dRegister fun(init: fun(), drawCall: fun()|nil)
---@field HookFunc fun(typename: string, method: string, preFunc: HookPreFunc, postFunc: HookPostFunc|nil)
---@field LoadImage fun(path: string): Image
---@field indent fun()
---@field deindent fun()
---@field info fun(msg: string, args...)
---@field error fun(msg: string, args...)
---@field debug fun(msg: string, args...)
---@field verbose fun(msg: string, args...)
---@field ModName string
---@field ModNamePath string
---@field ConfigFileName string
---@field CJKFontSize number
---@field D2dFontSize number
---@field Runtime table -- runtime data, wont be saved
---@field Run fun()


---@param modName string display mod name in imgui menu
---@param configFileName string? alt config file name, can be nil
---@return ModCreator # mod object
function _M.NewMod(modName, configFileName)
    local Mod = {}

    Mod.Runtime = {}

    Mod.MenuFuncs = {}

    Mod.ProfileMode = false
    Mod.RenderCost = {}
    Mod.RenderCostOrder = {}
    Mod.PerfCost = {}
    Mod.PerfCostCount = {}
    Mod.PerfCostCompare = {}
    Mod.PerfCostOrder = {}

    Mod.Indent = 0
    -- Mod.UpdateFuncs = {}
    -- Mod.D2dInitFuncs = {}
    -- Mod.D2dFuncs = {}
    -- Mod.OnFrameFuncs = {}
    -- Mod.OnDebugFrameFuncs = {}

    ---@return ModConfig # config object
    function Mod.LoadConfig(filename)
        if not filename then
            filename = Mod.ConfigFileName
        end
        local obj = json.load_file(filename)
        if not obj then
            if filename == Mod.ConfigFileName then
                obj = { Enabled = true, Debug = false, Verbose = false, }
                json.dump_file(filename, obj)
            end
        end
        return obj
    end

    ---@param size number nil as disable
    function Mod.EnableCJKFont(size)
        Mod.CJKFontSize = size
        if size then
            FontUtils.LoadImguiCJKFont(size)
        end
    end

    ---@param localization table<language, table>
    function Mod.SetLocalization(localization)
        Mod.LocalizationData = localization
    end

    ---@param size number nil as disable
    function Mod.DisableDefaultOptions()
        Mod.DefaultOptions = false
    end

    function Mod.SaveConfig(filename, config)
        if not filename then
            filename = Mod.ConfigFileName
            config = Mod.Config
        end
        json.dump_file(filename, config)
    end

    ---@param func fun(): boolean
    function Mod.Menu(func)
        table.insert(Mod.MenuFuncs, func)
    end

    ---@param name string
    ---@param func fun(): boolean
    function Mod.SubMenu(name, func)
        table.insert(Mod.MenuFuncs, function ()
            local changed = false
            if imgui.tree_node(name) then
                changed = func()
                imgui.tree_pop()
            end
            return changed
        end)
    end

    ---@param name string
    ---@param func fun(): boolean
    function Mod.SubDebugMenu(name, func)
        name = name .. " [Debug]"
        table.insert(Mod.MenuFuncs, function ()
            if not Mod.Config.Debug then
                return
            end
            local changed = false
            if imgui.tree_node(name) then
                changed = func()
                imgui.tree_pop()
            end
            return changed
        end)
    end

    re.on_draw_ui(function()
        -- if #Mod.MenuFuncs <= 0 then return end

        local configChanged = false

        local displayName = modName
        if Mod.LocalizationData then
            local conf = LanguageUtils.GetLocalizedTextConfig(Mod.LocalizationData)
            if conf and conf.ModName then
                displayName = conf.ModName
            end
        end

        if imgui.tree_node(displayName) then
            if Mod.Config.Enabled == nil then Mod.Config.Enabled = true end

            if Mod.CJKFontSize ~= nil and imgui.push_font_size == nil then
                imgui.push_font(FontUtils.LoadImguiCJKFont(Mod.CJKFontSize))
            end
    
            local changed

            if Mod.DefaultOptions ~= false then
                changed, Mod.Config.Enabled = imgui.checkbox("Enabled", Mod.Config.Enabled)
                configChanged = configChanged or changed
    
                changed, Mod.Config.Debug = imgui.checkbox("Debug", Mod.Config.Debug)
                configChanged = configChanged or changed
            end

            if Mod.DefaultOptions == false and Mod.HasVerbose then
                changed, Mod.Config.Debug = imgui.checkbox("Debug", Mod.Config.Debug)
                configChanged = configChanged or changed
            end

            if Mod.HasVerbose or Mod.Config.Verbose then
                changed, Mod.Config.Verbose = imgui.checkbox("Verbose Log", Mod.Config.Verbose)
                configChanged = configChanged or changed
            end

            for i = 1, #Mod.MenuFuncs, 1 do
                local func = Mod.MenuFuncs[i]
                configChanged = func() or configChanged
            end

            if Mod.CJKFontSize ~= nil and imgui.push_font_size == nil then
                imgui.pop_font();
            end
    
            imgui.tree_pop();
        end

        if configChanged ~= nil and configChanged ~= false then
            Mod.SaveConfig()
        end
    end)

    ---@param func fun()
    function Mod.OnUpdateBehavior(func)
        -- table.insert(Mod.UpdateFuncs, func)
        re.on_application_entry("UpdateBehavior", function ()
            if not Mod.Config.Enabled then return end
            func()
        end)
    end

    ---@param func fun()
    function Mod.OnPreUpdateBehavior(func)
        -- table.insert(Mod.UpdateFuncs, func)
        re.on_pre_application_entry("UpdateBehavior", function ()
            if not Mod.Config.Enabled then return end
            func()
        end)
    end

    function Mod.Run()
        if true then
            return
        end
        if #Mod.UpdateFuncs > 0 then
            re.on_application_entry("UpdateBehavior", function ()
                if not Mod.Config.Enabled then return end

                for i = 1, #Mod.UpdateFuncs, 1 do
                    local func = Mod.UpdateFuncs[i]
                    func()
                end
            end)
        end

        if d2d and #Mod.D2dInitFuncs > 0 or #Mod.D2dFuncs > 0 then
            d2d.register(function()
                FontUtils.LoadD2dFont(Mod.D2dFontSize)
                for i = 1, #Mod.D2dInitFuncs, 1 do
                    local func = Mod.D2dInitFuncs[i]
                    func()
                end
            end, function ()
                if not Mod.Config.Enabled then return end

                for i = 1, #Mod.D2dFuncs, 1 do
                    local func = Mod.D2dFuncs[i]
                    func()
                end
            end)
        end

        if #Mod.OnFrameFuncs > 0 or #Mod.OnDebugFrameFuncs > 0 then
            re.on_frame(function ()
                if not Mod.Config.Enabled then return end

                for i = 1, #Mod.OnFrameFuncs, 1 do
                    local func = Mod.OnFrameFuncs[i]
                    func()
                end

                if Mod.Config.Debug and #Mod.OnDebugFrameFuncs > 0 then
                    imgui.text("----- [" .. Mod.ModName .. "] -----")
                    for i = 1, #Mod.OnDebugFrameFuncs, 1 do
                        local func = Mod.OnDebugFrameFuncs[i]
                        func()
                    end
                end
            end)
        end
    end

    ---@param func fun()
    function Mod.OnFrame(func)
        -- table.insert(Mod.OnFrameFuncs, func)
        re.on_frame(function (tag)
            if not Mod.Config.Enabled then return end

            tag = tag or Mod.ModName
            -- imgui.begin_window(tag)
            func()
            -- imgui.end_window()
        end)
    end

    ---@param func fun()
    function Mod.OnDebugFrame(func, tag)
        -- table.insert(Mod.OnDebugFrameFuncs, func)
        re.on_frame(function ()
            if not Game.IsLoaded() then
                return
            end
            if not Mod.Config.Enabled or not Mod.Config.Debug then return end

            tag = tag or Mod.ModName
            imgui.begin_window(tag.. " [Debug]")
            func()
            imgui.end_window()
        end)
    end

    local function ShowCostTable(data, order, count, compare)
        local size = Utils.GetTableSize(data)
        if size <= 0 then return end

        local total = 0

        for _, key in pairs(order) do
            local delta = data[key]
            total = total + delta
            local msg = string.format("%s: %0.4f ms", key, delta)
            if count and count[key] then
                msg = msg .. string.format(", call count: %d", count[key])
            end
            if compare and compare[key] then
                local target = data[compare[key]]
                local compareDelta = delta-target

                local state = "better than"
                if compareDelta > 0 then
                    state = "worse than"
                end
                msg = msg .. string.format(", %s `%s`: %0.4f ms", state, compare[key], compareDelta)
            end

            imgui.text(msg)
        end
        
        imgui.text(string.format("Total: %0.4f ms", total))
    end

    function Mod.InitCost(key)
        if not Mod.ProfileMode then return end
        if Mod.PerfCost[key] then
            Mod.PerfCost[key] = 0
        end
        Mod.PerfCostCount[key] = 0
    end
    function Mod.CostCompare(key, keyTarget)
        if not Mod.ProfileMode then return end
        Mod.PerfCostCompare[key] = keyTarget
    end
    function Mod.RecordCost(key, func, sum)
        if not Mod.ProfileMode then
            return func()
        end
        local was = 0
        if sum then
            was = Mod.PerfCost[key] or 0
            Mod.PerfCostCount[key] = Mod.PerfCostCount[key] + 1
        end
        if not Mod.PerfCost[key] then
            table.insert(Mod.PerfCostOrder, key)
        end


        local result = {}
        Mod.PerfCost[key] = Utils.GetElapsedTimeMs()
        if Mod.Config.Enabled then
            result = {func()}
        end
        Mod.PerfCost[key] = Utils.GetElapsedTimeMs() - Mod.PerfCost[key] + was

        return table.unpack(result)
    end

    function Mod.ShowCost(tag)
        re.on_frame(function ()
            if not Mod.Config.Enabled then return end
    
            local total = 0
            tag = tag or Mod.ModName
            imgui.begin_window(tag .. " [Performance]")
            imgui.text("[Render]")
            ShowCostTable(Mod.RenderCost, Mod.RenderCostOrder)

            imgui.text("")
            
            imgui.text("[Perf]")
            ShowCostTable(Mod.PerfCost, Mod.PerfCostOrder, Mod.PerfCostCount, Mod.PerfCostCompare)
            imgui.end_window()
        end)
    end

    ---@param init fun()
    ---@param drawCall fun()?, if nil, init as draw call
    function Mod.D2dRegister(init, drawCall, key)
        if d2d == nil or init == nil then return end

        -- if drawCall == nil then
        --     table.insert(Mod.D2dFuncs, init)
        -- else
        --     table.insert(Mod.D2dInitFuncs, init)
        --     table.insert(Mod.D2dFuncs, drawCall)
        -- end

        if drawCall == nil or type(drawCall) == "string" then
            key = drawCall
            drawCall = init
            init = function()
                FontUtils.LoadD2dFont(Mod.D2dFontSize)
            end
        end
        local RenderFunc = function ()
            if key and not Mod.RenderCost[key] then
                table.insert(Mod.RenderCostOrder, key)
            end
            if key then
                Mod.RenderCost[key] = Utils.GetElapsedTimeMs()
            end
            if Mod.Config.Enabled then
                drawCall()
            end
            
            if key then
                Mod.RenderCost[key] = Utils.GetElapsedTimeMs() - Mod.RenderCost[key]
            end
        end
        if IsD2d then
            d2d.register(function()
                Mod.D2dReset()
                init()
            end, RenderFunc)
        else
            -- init()
            re.on_frame(RenderFunc)
        end
    end

    ---@param typename string
    ---@param method string
    ---@param preFunc HookPreFunc
    ---@param postFunc HookPostFunc|nil
    function Mod.HookFunc(typename, methodName, preFunc, postFunc)
        -- Mod.info(tostring(typename) .. ":" .. tostring(methodName) .. " hooking")
        if typename == nil or methodName == nil then return end
        if preFunc == nil and postFunc == nil then return end
        if preFunc == nil then preFunc = HOOK_PRE_DEFAULT end
        if postFunc == nil then postFunc = HOOK_POST_DEFAULT end

        local type = sdk.find_type_definition(typename)
        if type == nil then
            Mod.error("unknown type: " .. tostring(typename) .. ":" .. tostring(methodName))
            return
        end
        local method = type:get_method(methodName)
        if method == nil then
            Mod.error("unknown type method: " .. tostring(typename) .. ":" .. tostring(methodName))
            return
        end
        sdk.hook(
            method,
            function (args)
                if not Mod.Config.Enabled then return end
                return preFunc(args)
            end, function (retval)
                if not Mod.Config.Enabled then return retval end
                local ret = postFunc(retval)
                if ret == nil then return retval end
                return ret
            end
        )
        -- Mod.info(typename .. ":" .. methodName .. " hooked.")
    end

    function Mod.DisabledHookFunc(type, method, preFunc, postFunc) end

    function Mod.LoadImage(path)
        if Mod.IMAGE_CACHE == nil then
            Mod.IMAGE_CACHE = {}
        end
        if Mod.IMAGE_CACHE[path] == nil then
            local fullPath = Mod.ModNamePath .. "/" .. path

            local img = Draw.LoadImage(fullPath)
            if img then
                if Mod.Config.Debug or Mod.Config.Verbose then
                    Mod.info("Image loaded: %s", fullPath)
                end
                Mod.IMAGE_CACHE[path] = img
            end
        end
        return Mod.IMAGE_CACHE[path]
    end

    function Mod.D2dReset()
        Mod.IMAGE_CACHE = {}
    end

    function Mod.indent()
        Mod.Indent = Mod.Indent + 1
    end

    function Mod.deindent()
        Mod.Indent = Mod.Indent - 1
        if Mod.Indent < 0 then
            Mod.Indent = 0
        end
    end

    function Mod.get_indent()
        return string.rep("  ", Mod.Indent)
    end

    function Mod.verbose(msg, ...)
        Mod.HasVerbose = true
        if Mod.Config.Verbose or Mod.Config.Debug then
            log.info(Mod.LogPrefix .. Mod.get_indent() .. string.format(msg, ...))
        end
    end
    
    function Mod.debug(msg, ...)
        if Mod.Config.Debug then
            log.info(Mod.LogPrefix .. Mod.get_indent() .. string.format(msg, ...))
        end
    end
    
    function Mod.info(msg, ...)
        log.info(Mod.LogPrefix .. Mod.get_indent() .. string.format(msg, ...))
    end
    
    function Mod.error(msg, ...)
        log.error(Mod.LogPrefix .. Mod.get_indent() .. string.format(msg, ...))
    end
    
    Mod.ModName = modName
    Mod.ModNamePath = string.lower(modName):gsub(" ", "_")
    if configFileName == nil then
        configFileName = Mod.ModNamePath .. ".json"
    end
    Mod.ConfigFileName = configFileName
    Mod.CJKFontSize = nil
    Mod.D2dFontSize = 18
    Mod.Config = Mod.LoadConfig()

    Mod.LogPrefix = "[" .. Mod.ModName .. "] "
    log.info(Mod.LogPrefix .. "Loaded, config file: " .. Mod.ConfigFileName);

    return Mod
end

return _M