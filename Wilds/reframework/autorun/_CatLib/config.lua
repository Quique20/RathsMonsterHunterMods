local re = re
local sdk = sdk
local json = json
local imgui = imgui

local CONST = require("_CatLib.const")

local LANGUAGES = {
    [CONST.LanguageType.Japanese] = "Japanese",
    [CONST.LanguageType.English] = "English",
    [CONST.LanguageType.Korean] = "Korean",
    [CONST.LanguageType.SimplifiedChinese] = "Chinese",
}

local RENDER_BACKENDS = {
    [1] = "reframework-d2d",
    [2] = "imgui",
}

local SceneManagerType = sdk.find_type_definition("via.SceneManager")

local ScreenW, ScreenH
local function GetScreenSize()
    if ScreenW and ScreenH then
        return ScreenW, ScreenH
    end

    ---@type via.SceneManager
    local mgr = sdk.get_native_singleton("via.SceneManager")
    if not mgr then
        return 1920, 1080
    end

    ---@type via.SceneView
    local view = sdk.call_native_func(mgr, SceneManagerType,  "get_MainView")
    if not view then
        return 1920, 1080
    end

    ---@type via.Size
    local size = view:get_Size()
    if not size then
        return 1920, 1080
    end

    ScreenW, ScreenH = size.w, size.h
    return ScreenW, ScreenH
end

local CONF_FILE_NAME = "_catlib_config.json"
local Conf = json.load_file(CONF_FILE_NAME) or {}

local function NewConfig(conf)
    if conf == nil or type(conf) ~= "table" then
        conf = {}
    end

    if conf.UIScale == nil then
        local w, h = GetScreenSize()
        if h then
            conf.UIScale = h / 2160
        else
            conf.UIScale = 1
        end

        -- Conf.DefaultFontSize = 9 * Conf.UIScale
        -- if Conf.DefaultFontSize < 10 then
        --     Conf.DefaultFontSize = 10
        -- end
    end

    if conf.Language == nil then
        conf.LanguageOverride = false
        conf.Language = CONST.LanguageType.English

        local mgr = sdk.get_managed_singleton("app.GUIManager")
        if mgr then
            conf.Language = mgr:getSystemLanguageToApp()
        end
    end

    if conf.RenderBackend == nil then
        conf.RenderBackend = 1
    end
    if conf.DefaultFontSize == nil then
        conf.DefaultFontSize = imgui.get_default_font_size()
    end
    if conf.FontScale == nil then
        conf.FontScale = 1
    end

    if conf.Experimental == nil then
        conf.Experimental = false
    end

    return conf
end

Conf = NewConfig(Conf)

re.on_draw_ui(function()
    local changed = false
    local configChanged = false

    if imgui.tree_node("_CatLib Global Config") then
        if imgui.button("Restore to default (require reset script)") then
            Conf = NewConfig()
            configChanged = true
        end

        imgui.begin_rect()
        imgui.text("UI Scale: by default, 0.5x for 1080p, 0.75x for 2K, 1x for 4K (2160p).")
        imgui.text("This option is used to initialize mod configuration, doesn't work if the config file has been generated.")
        imgui.text("You need to delete existed config files under reframework/data directory.")
        changed, Conf.UIScale = imgui.drag_float("UI Scale", Conf.UIScale, 0.05, 0.5, 4)
        configChanged = configChanged or changed
        imgui.same_line()
        if imgui.button("-0.05##GlobalUIScaleInc") then
            Conf.UIScale = Conf.UIScale - 0.05
            configChanged = true
        end

        imgui.same_line()
        if imgui.button("+0.05##GlobalUIScaleDec") then
            Conf.UIScale = Conf.UIScale + 0.05
            configChanged = true
        end
        imgui.end_rect()
        
        imgui.text("")

        imgui.begin_rect()
        imgui.text("You need to reset script or restart the game after changing this")

        changed, Conf.LanguageOverride = imgui.checkbox("Override Language", Conf.LanguageOverride)
        configChanged = configChanged or changed

        changed, Conf.Language = imgui.combo("Language", Conf.Language, LANGUAGES)
        configChanged = configChanged or changed
        imgui.end_rect()
        
        imgui.text("")
        imgui.text("Default font size only affects fonts that using default size")
        changed, Conf.DefaultFontSize = imgui.drag_int("Default Font Size", Conf.DefaultFontSize, 1, 12, 40)
        configChanged = configChanged or changed
        imgui.same_line()
        if imgui.button("-1##GlobalFontSizeInc") then
            Conf.DefaultFontSize = Conf.DefaultFontSize - 1
            configChanged = true
        end

        imgui.same_line()
        if imgui.button("+1##GlobalFontSizeDec") then
            Conf.DefaultFontSize = Conf.DefaultFontSize + 1
            configChanged = true
        end
        
        if imgui.push_font_size then
            imgui.text("")
            imgui.text("Global font scale affects all texts")
    
            changed, Conf.FontScale = imgui.drag_float("Global Font Scale", Conf.FontScale, 0.1, 0.5, 4)
            configChanged = configChanged or changed
            imgui.same_line()
            if imgui.button("-0.1##GlobalFontScaleInc") then
                Conf.FontScale = Conf.FontScale - 0.1
                configChanged = true
            end

            imgui.same_line()
            if imgui.button("+0.1##GlobalFontScaleDec") then
                Conf.FontScale = Conf.FontScale + 0.1
                configChanged = true
            end
        else
            -- imgui.text(string.format("Global Font Scal: %0.1f", Conf.FontScale))
            
            -- imgui.same_line()
            -- if imgui.button("-0.1") then
            --     Conf.FontScale = Conf.FontScale - 0.1
            --     configChanged = true
            -- end

            -- imgui.same_line()
            -- if imgui.button("+0.1") then
            --     Conf.FontScale = Conf.FontScale + 0.1
            --     configChanged = true
            -- end
        end
        
        imgui.text("")
        changed, Conf.Experimental = imgui.checkbox("Experimental [don't use]", Conf.Experimental)
        configChanged = configChanged or changed

        if Conf.Experimental then
            imgui.begin_rect()
            changed, Conf.RenderBackend = imgui.combo("Render Backend", Conf.RenderBackend, RENDER_BACKENDS)
            configChanged = configChanged or changed
            imgui.end_rect()
        end
        
        imgui.tree_pop();
    end

    if configChanged then
        json.dump_file(CONF_FILE_NAME, Conf)
    end
end)


return Conf