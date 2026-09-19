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

local _M = {}

---@class TypesetConfig
---@field Enable boolean
---@field VerticalCenter boolean
---@field Top boolean
---@field Bottom boolean
---@field HorizontalCenter boolean
---@field LeftAlign boolean
---@field RightAlign boolean
---@field OffsetX number
---@field OffsetY number
---@field OffsetXHalfWidth boolean
---@field OffsetYHalfHeight boolean
---@field OffsetXPercentage number
---@field OffsetYPercentage number
---@field BlockRenderX boolean div render arg. if true, the w will be counted in Div renderer
---@field BlockRenderY boolean div render arg. if true, the h will be counted in Div renderer
---@field MarginX number
---@field MarginY number
---@field PaddingX number
---@field PaddingY number
---@field Absolute boolean if true, menu is simple mode

---@param cfg TypesetConfig
---@return TypesetConfig, boolean
function _M.DefaultConfig(cfg)
    local changed = false
    if cfg == nil then
        cfg = {}
        changed = true
    end

    if cfg.Enable == nil then
        cfg.Enable = true
        changed = true
    end
    if cfg.VerticalCenter == nil then
        cfg.VerticalCenter = false
        changed = true
    end
    if cfg.Top == nil then
        cfg.Top = true
        changed = true
    end
    if cfg.Bottom == nil then
        cfg.Bottom = false
        changed = true
    end
    if cfg.HorizontalCenter == nil then
        cfg.HorizontalCenter = false
        changed = true
    end
    if cfg.LeftAlign == nil then
        cfg.LeftAlign = true
        changed = true
    end
    if cfg.RightAlign == nil then
        cfg.RightAlign = false
        changed = true
    end

    if cfg.OffsetX == nil then
        cfg.OffsetX = 0
        changed = true
    end
    if cfg.OffsetY == nil then
        cfg.OffsetY = 0
        changed = true
    end
    if cfg.OffsetXHalfWidth == nil then
        cfg.OffsetXHalfWidth = false
        changed = true
    end
    if cfg.OffsetYHalfHeight == nil then
        cfg.OffsetYHalfHeight = false
        changed = true
    end
    if cfg.OffsetXPercentage == nil then
        cfg.OffsetXPercentage = 0
        changed = true
    end
    if cfg.OffsetYPercentage == nil then
        cfg.OffsetYPercentage = 0
        changed = true
    end
    
    if cfg.BlockRenderX == nil then
        cfg.BlockRenderX = true
        changed = true
    end
    if cfg.BlockReserveX == nil then
        cfg.BlockReserveX = false
        changed = true
    end
    if cfg.BlockRenderY == nil then
        cfg.BlockRenderY = false
        changed = true
    end
    if cfg.BlockReserveY == nil then
        cfg.BlockReserveY = false
        changed = true
    end
    return cfg, changed
end

---@param conf TypesetConfig
---@return boolean
function _M.IsBlockRender(conf)
    if conf.BlockRenderX == false and conf.BlockRenderY == false then
        return false
    end
    if conf.BlockRenderX == true or conf.BlockRenderY == true then
        return true
    end
    if conf.BlockRenderX == nil and conf.BlockRenderX == nil then
        if conf.HorizontalCenter or conf.RightAlign then
            return false
        end

        if conf.VerticalCenter or conf.Bottom then
            return false
        end
    end

    return true
end

-- calculate offset and central/align config
---@param divX number
---@param divY number
---@param divWidth number
---@param divHeight number
---@param targetW number
---@param targetH number
---@param cfg TypesetConfig
---@return number, number, number, number # actual div x, y, w, h
function _M.Calculate(divX, divY, divWidth, divHeight, targetW, targetH, cfg)
    cfg = _M.DefaultConfig(cfg)
    if not cfg.Enable then return end

    local x, y, w, h = divX, divY, divWidth, divHeight

    local aligned = cfg.VerticalCenter or cfg.Bottom or cfg.HorizontalCenter or cfg.RightAlign
    if aligned then
        if cfg.HorizontalCenter then
            x = x + math.floor((w - targetW) / 2)
        elseif cfg.RightAlign then
            x = x + w
            if w > targetW then
                -- only w > 0 are left ->right, need to reverse the width
                x = x - targetW
            else
                -- no enough width, simply append to last
                x = x - w
            end
        end

        if cfg.VerticalCenter then
            y = y + math.floor((h - targetH) / 2)
        elseif cfg.Bottom then
            y = y + h
            if h > targetH then
                -- only h > 0 are top ->down, need to reverse the height
                y = y - targetH
            else
                -- no enough height, simply append to last
                y = y - h
            end
        end
    end

    if cfg.OffsetXPercentage then
        -- abs to ensure x% >0 results right offset if w <0
        local delta = math.abs(divWidth) * cfg.OffsetXPercentage
        x = x + delta
        w = w - delta
    end
    if cfg.OffsetYPercentage then
        -- abs to ensure y% >0 results down offset if h <0
        local delta = math.abs(divHeight) * cfg.OffsetYPercentage
        y = y + delta
        h = h - delta
    end

    if cfg.OffsetX then
        x = x + cfg.OffsetX
        w = w - cfg.OffsetX
    end
    if cfg.OffsetY then
        y = y + cfg.OffsetY
        h = h - cfg.OffsetY
    end

    if cfg.OffsetXHalfWidth then
        x = x - math.floor(targetW/2)
    end
    if cfg.OffsetYHalfHeight then
        y = y - math.floor(targetH/2)
    end

    return x, y, w, h
end

---@param cfg TypesetConfig
---@param simpleMode nil|boolean
function _M.Menu(cfg, simpleMode, func)
    local isSimpleMode = false
    if simpleMode == true then
        isSimpleMode = true
    end

    local configChanged = false
    local changed

    cfg, configChanged = _M.DefaultConfig(cfg)

    changed, cfg.Enable = imgui.checkbox("Enable", cfg.Enable)
    configChanged = configChanged or changed

    if isSimpleMode then
        changed, cfg.OffsetX = imgui.drag_int("OffsetX", cfg.OffsetX, 1, -3840, 3840)
        configChanged = configChanged or changed
        changed, cfg.OffsetY = imgui.drag_int("OffsetY", cfg.OffsetY, 1, -2160, 2160)
        configChanged = configChanged or changed

        changed, cfg.MarginX = imgui.drag_int("MarginX", cfg.MarginX, 1, -3840, 3840)
        configChanged = configChanged or changed
        changed, cfg.MarginY = imgui.drag_int("MarginY", cfg.MarginY, 1, -2160, 2160)
        configChanged = configChanged or changed

        changed, cfg.PaddingX = imgui.drag_int("PaddingX", cfg.PaddingX, 1, -3840, 3840)
        configChanged = configChanged or changed
        changed, cfg.PaddingY = imgui.drag_int("PaddingY", cfg.PaddingY, 1, -2160, 2160)
        configChanged = configChanged or changed
    else
        if imgui.tree_node("Horizontal (X)") then
            changed, cfg.HorizontalCenter = imgui.checkbox("Center", cfg.HorizontalCenter)
            configChanged = configChanged or changed

            changed, cfg.RightAlign = imgui.checkbox("RightAlign", cfg.RightAlign)
            configChanged = configChanged or changed

            changed, cfg.OffsetX = imgui.drag_int("Offset", cfg.OffsetX, 1, -3840, 3840)
            configChanged = configChanged or changed
            changed, cfg.MarginX = imgui.drag_int("MarginX", cfg.MarginX, 1, -3840, 3840)
            configChanged = configChanged or changed
            changed, cfg.PaddingX = imgui.drag_int("PaddingX", cfg.PaddingX, 1, -3840, 3840)
            configChanged = configChanged or changed

            changed, cfg.OffsetXPercentage = imgui.drag_float("Offset Percentage", cfg.OffsetXPercentage, 0.01, -5, 5)
            configChanged = configChanged or changed

            changed, cfg.OffsetXHalfWidth = imgui.checkbox("Offset Half Width", cfg.OffsetXHalfWidth)
            configChanged = configChanged or changed

            changed, cfg.BlockRenderX = imgui.checkbox("Block Render", cfg.BlockRenderX)
            configChanged = configChanged or changed

            imgui.tree_pop()
        end

        if imgui.tree_node("Vertical (Y)") then
            changed, cfg.VerticalCenter = imgui.checkbox("Center", cfg.VerticalCenter)
            configChanged = configChanged or changed

            changed, cfg.Bottom = imgui.checkbox("Bottom", cfg.Bottom)
            configChanged = configChanged or changed

            changed, cfg.OffsetY = imgui.drag_int("Offset", cfg.OffsetY, 1, -2160, 2160)
            configChanged = configChanged or changed
            changed, cfg.MarginY = imgui.drag_int("MarginY", cfg.MarginY, 1, -2160, 2160)
            configChanged = configChanged or changed
            changed, cfg.PaddingY = imgui.drag_int("PaddingY", cfg.PaddingY, 1, -2160, 2160)
            configChanged = configChanged or changed

            changed, cfg.OffsetYPercentage = imgui.drag_float("Offset Percentage", cfg.OffsetYPercentage, 0.01, -5, 5)
            configChanged = configChanged or changed

            changed, cfg.OffsetYHalfHeight = imgui.checkbox("Offset Half Height", cfg.OffsetYHalfHeight)
            configChanged = configChanged or changed

            changed, cfg.BlockRenderY = imgui.checkbox("Block Render", cfg.BlockRenderY)
            configChanged = configChanged or changed

            imgui.tree_pop()
        end
    end

    return configChanged, cfg
end

---------------------------------
-- DIV
-- Div is a render helper class that defines several useful auto-calculated functions and config menu
---------------------------------
---@class DivRendererConfig
---@field Enable boolean
---@field PosX number
---@field PosY number
---@field Width number
---@field Height number

---@alias RenderFunc fun(x: number, y: number, w: number, h: number, conf: TypesetConfig, ...) number, number, number, number returns real x, y, size w, size h

---@class DivRenderer
---@field PosX number
---@field PosY number
---@field Width number
---@field Height number
---@field _x number
---@field _y number
---@field _w number
---@field _h number
---@field Init fun()
---@field Render fun(cfg: TypesetConfig, renderFunc: RenderFunc, varargs)
---@field End fun()
---@field DebugMode boolean
---@field Debug fun()
---@field DebugColor number
---@field MarginX number
---@field MarginY number
---@field PaddingX number
---@field PaddingY number

---@param posX number
---@param posY number
---@param width number
---@param height number
---@param enable boolean|nil
---@return DivRenderer
function _M.NewDivRenderer(posX, posY, width, height, enable, marginX, marginY, paddingX, paddingY)
    if enable ~= false then
        enable = true
    end

    ---@type DivRenderer
    local _Renderer = {
        Enable = enable,
        PosX = posX,
        PosY = posY,
        Width = width,
        Height = height,

        -- Calls = {},

        -- block mode args
        _x = posX,
        _y = posY,
        _w = width,
        _h = height,
        
        MarginX = marginX or 0,
        MarginY = marginY or 0,
        PaddingX = paddingX or 0,
        PaddingY = paddingY or 0,

        -- Debug
        DebugMode = false,
        DebugColor = 0xFF00FF00,
    }

    -- if conf.BlockRender=true, the rendered size w/h will be counted
    -- otherwise, rendered w/h will be counted when it is no "floating"
    ---@param conf TypesetConfig
    ---@param renderFunc RenderFunc
    ---@return number, number, number, number, number, number next x, next y, w,h, x,y,
    function _Renderer.Render(conf, renderFunc, ...)
        conf = _M.DefaultConfig(conf)

        if _Renderer.Enable == false or conf.Enable == false then return end

        local x, y, w, h = _Renderer.PosX, _Renderer.PosY, _Renderer.Width, _Renderer.Height

        local blockMode = _M.IsBlockRender(conf)
        if blockMode then
            if conf.BlockRenderX then
                x = _Renderer._x
                w = _Renderer._w
            end
            if conf.BlockRenderY then
                y = _Renderer._y
                h = _Renderer._h
            end
        end
        x = x + (conf.MarginX or _Renderer.MarginX)
        y = y + (conf.MarginY or _Renderer.MarginY)

        local paddingX, paddingY = (conf.PaddingX or _Renderer.PaddingX), (conf.PaddingY or _Renderer.PaddingY)
        local rx, ry, rw, rh = renderFunc(x+paddingX, y+paddingY, w, h, conf, ...)
        -- rx = rx - conf.OffsetX
        -- ry = ry - conf.OffsetY
        rw = rw + paddingX
        rh = rh + paddingY

        if blockMode then
            if conf.BlockRenderX and not conf.BlockReserveX then --and not (conf.RightAlign or conf.HorizontalCenter) then
                _Renderer._x = rx + rw
                _Renderer._w = _Renderer._w + (x - _Renderer._x) -- plus x offset
            end
            if conf.BlockRenderY and not conf.BlockReserveY then --and not (conf.Bottom or conf.VerticalCenter) then
                _Renderer._y = ry + rh
                _Renderer._h = _Renderer._h + (y - _Renderer._y) -- plus y offset
            end
        end

        _Renderer.DrawDebugBlock()

        return _Renderer._x, _Renderer._y, w, h, x, y, rw, rh
    end

    _Renderer.Calculate = _M.Calculate

    function _Renderer.Init()
        _Renderer._x, _Renderer._y, _Renderer._w, _Renderer._h = _Renderer.PosX, _Renderer.PosY, _Renderer.Width, _Renderer.Height
        _Renderer.DebugColor = 0xFF00FF00
    end

    function _Renderer.End()
        _Renderer._x, _Renderer._y, _Renderer._w, _Renderer._h = _Renderer.PosX, _Renderer.PosY, _Renderer.Width, _Renderer.Height

        _Renderer.DebugColor = 0xFFFF0000
        _Renderer.DrawDebugBlock()
        _Renderer.DebugColor = 0xFF00FF00
    end

    ---@param x number
    ---@param y number
    function _Renderer.RePos(x, y)
        _Renderer.PosX, _Renderer.PosY = x, y
        _Renderer._x, _Renderer._y = x, y
    end

    ---@param w number|nil width
    ---@param h number|nil height
    function _Renderer.ReSize(w, h)
        if w ~= nil then
            _Renderer.Width = w
        end
        if h ~= nil then
            _Renderer.Height = h
        end
    end

    function _Renderer.NextPos()
        return _Renderer._x, _Renderer._y
    end

    function _Renderer.Debug(mode)
        if mode == nil then
            mode = true
        end
        _Renderer.DebugMode = mode
    end

    function _Renderer.DrawDebugBlock()
        if not _Renderer.Enable or not _Renderer.DebugMode then return end
        if d2d then
            d2d.outline_rect(_Renderer._x, _Renderer._y, _Renderer._w, _Renderer._h, 1, _Renderer.DebugColor)
        else
            draw.outline_rect(_Renderer._x, _Renderer._y, _Renderer._w, _Renderer._h, _Renderer.DebugColor)
        end
        
        local adder = 0x08
        local R = (_Renderer.DebugColor >> 16) & 0xFF
        local G = (_Renderer.DebugColor >> 8) & 0xFF
        local B = _Renderer.DebugColor & 0xFF

        R = R + adder
        if R >= 0xFF then
            G = G + adder
            R = 0xFF
        end
        if G >= 0xFF then
            B = B + adder
            G = 0xFF
        end
        if B >= 0xFF then
            R = R + adder
            B = 0xFF
        end
        if R >= 0xFF and G >= 0xFF and B >= 0xFF then
            B = 0
            G = 0
            R = adder
        end

        _Renderer.DebugColor = 0xFF000000 | B | (G << 8) | (R << 16)
    end

    return _Renderer
end

return _M
