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

local FontUtils = require("_CatLib.font")
local Typeset = require("_CatLib.typeset")

local LibConf = require("_CatLib.config")

local D2dUtils = require("_CatLib.d2d")

local _M = {}

local Rect = D2dUtils.Rect
local OutlineRect = D2dUtils.OutlineRect
local Line = D2dUtils.Line
local Text = D2dUtils.Text

_M.Measure = D2dUtils.Measure

_M.Rect = Rect
_M.OutlineRect = OutlineRect
_M.Line = Line
_M.Text = Text
_M.Ring = D2dUtils.Ring
_M.LoadImage = D2dUtils.LoadImage
_M.Image = D2dUtils.Image
_M.Quad = D2dUtils.Quad
_M.FillQuad = D2dUtils.FillQuad
_M.Circle = D2dUtils.Circle
_M.FillCircle = D2dUtils.FillCircle
_M.Pie = D2dUtils.Pie
_M.LoadFont = D2dUtils.LoadFont
_M.LoadD2dFont = FontUtils.LoadD2dFont

---------------------------------
-- Basic Render Utilities
---------------------------------

function _M.RandomColor(alpha)
    if not alpha then
        alpha = 0xFF
    end
    local b = math.random(0, 0xFF) << 16
    local g = math.random(0, 0xFF) << 8
    local r = math.random(0, 0xFF) << 0
    local a = alpha << 24
    return a | b | g | r
end

-- 0xABGR -> 0xARGB
function _M.ReverseRGB(color)
    if not color then return end
	local b = ((color >>  0) & 0xFF) << 16
	local g = ((color >>  8) & 0xFF) << 8
	local r = ((color >> 16) & 0xFF) << 0
	local a = ((color >> 24) & 0xFF) << 24
	return a | b | g | r
end

function _M.DarkenRGB(color, ratio)
    if ratio == nil then
        ratio = 0.9
    end
	local b = ((color >>  0) & 0xFF)
	local g = ((color >>  8) & 0xFF)
	local r = ((color >> 16) & 0xFF)
	local a = ((color >> 24) & 0xFF) << 24

    r = (math.floor(r * ratio) & 0xFF) << 16
    g = (math.floor(g * ratio) & 0xFF) << 8
    b = (math.floor(b * ratio) & 0xFF) << 0

    return a | r | g | b
end

function _M.LinearGradientColor(colorA, colorB, t)
    t = math.max(0, math.min(1, t))

    local aA = (colorA >> 24) & 0xFF
    local rA = (colorA >> 16) & 0xFF
    local gA = (colorA >> 8)  & 0xFF
    local bA = colorA & 0xFF

    local aB = (colorB >> 24) & 0xFF
    local rB = (colorB >> 16) & 0xFF
    local gB = (colorB >> 8)  & 0xFF
    local bB = colorB & 0xFF

    local a = math.floor(aA + (aB - aA) * t) << 24
    local r = math.floor(rA + (rB - rA) * t) << 16
    local g = math.floor(gA + (gB - gA) * t) << 8
    local b = math.floor(bA + (bB - bA) * t)

    return a | r | g | b
end

-- 0xABGR -> 0xARGB
function _M.SetAlpha(color, alpha)
	local rgb = (color & 0xFFFFFF)
	local a = alpha << 24
	return a | rgb
end

-- 0xABGR -> 0xARGB
function _M.SetAlphaRatio(color, ratio)
    if ratio == 1 then return color end

    local rgb = (color & 0xFFFFFF)

    local a = (color >> 24) & 0xFF
    -- if a < 0x0F then
    --     a = 0
    -- end

	a = (math.floor(a*ratio) & 0xFF) << 24
	return a | rgb
end

function _M.Bar(x, y, width, height, ratio, bgColor, barColor, shadowColor)
    -- Rect(x - 1, y - 1, width + 2, height + 2, 0xFF000000)
    local barWidth = ratio*width
    if bgColor then
        OutlineRect(x, y, width, height, 2, bgColor)
        Rect(x+barWidth, y, width-barWidth, height, bgColor)
    end
    if shadowColor then
        local h = math.floor(height / 2)
        Rect(x, y, barWidth, h, barColor)
        Rect(x, y+h, barWidth, h, shadowColor)
    else
        Rect(x, y, barWidth, height, barColor)
    end
end

function _M.UIRing(x, y, outerR, innerR, ratio, color, clockwise, angle)
    if ratio <= 0 or not color then
        return
    end
    if clockwise == nil then
        clockwise = false
    end
    if not angle then
        angle = 0
    end
    D2dUtils.Ring(x, y, outerR, innerR, angle-90, ratio*360, color, clockwise)
end

function _M.UIRingOutline(x, y, outerR, innerR, ratio, thickness, color, clockwise, angle)
    if ratio <= 0 or not color then
        return
    end
    if clockwise == nil then
        clockwise = false
    end
    if not angle then
        angle = 0
    end
    D2dUtils.RingOutline(x, y, outerR, innerR, angle-90, ratio*360, thickness, color, clockwise)
end

function _M.UIPie(x, y, radius, ratio, color, clockwise, angle)
    if ratio <= 0 or not color then
        return
    end
    if clockwise == nil then
        clockwise = false
    end
    if not angle then
        angle = 0
    end
    D2dUtils.Pie(x, y, radius, angle-90, ratio*360, color, clockwise)
end

function _M.UIPieOutline(x, y, radius, ratio, thickness, color, clockwise, angle)
    if ratio <= 0 or not color then
        return
    end
    if clockwise == nil then
        clockwise = false
    end
    if not angle then
        angle = 0
    end
    D2dUtils.PieOutline(x, y, radius, angle-90, ratio*360, thickness, color, clockwise)
end

function _M.QuadRect(x, y, width, height, offsetX, color)
    local x1, y1 = x, y
    local x2, y2 = x + width, y1
    local x4, y4 = x + offsetX, y1 + height
    local x3, y3 = x + offsetX + width, y4
    
    D2dUtils.FillQuad(x1, y1, x2, y2, x3, y3, x4, y4, color)
end

function _M.OutlineQuadRect(x, y, width, height, offsetX, thickness, color)
    local x1, y1 = x, y
    local x2, y2 = x + width, y1
    local x4, y4 = x + offsetX, y1 + height
    local x3, y3 = x + offsetX + width, y4
    
    D2dUtils.Quad(x1, y1, x2, y2, x3, y3, x4, y4, thickness, color)
end

function _M.QuadRectBar(x, y, width, height, ratio, offsetX, bgColor, color, border)
    _M.QuadRect(x, y, width, height, offsetX, bgColor)

    if border == nil then
        border = 0
    end
    if border > 0 and height > 2*border then
        local CoTanTheta = offsetX/height

        local SinTheta = height / math.sqrt(height*height+offsetX*offsetX)
        local xEndDelta = border /SinTheta
        local xStartDelta = border * CoTanTheta
        -- log.info(string.format("B: %d, sin: %0.1f, xD: %0.1f", border, SinTheta, xDelta))
        height = height - 2*border
        width = width - 2*xEndDelta
        x = x + xStartDelta + xEndDelta
        y = y + border
        offsetX = height*CoTanTheta
    end
    local w = width*ratio
    local h = height
    _M.QuadRect(x, y, w, h, offsetX, color)
    return x, y, w, h
end

function _M.QuadHealthBar(x, y, width, height, ratio, redRatio, offsetX, bgColor, color, redColor, border)
    _M.QuadRect(x, y, width, height, offsetX, bgColor)

    if border == nil then
        border = 0
    end

    local xStartDelta, xEndDelta = 0, 0
    if border > 0 and height > 2*border then
        local CoTanTheta = offsetX/height
        local SinTheta = height / math.sqrt(height*height+offsetX*offsetX)

        xStartDelta = border * CoTanTheta
        xEndDelta = border /SinTheta

        -- log.info(string.format("B: %d, sin: %0.1f, xD: %0.1f", border, SinTheta, xDelta))
        height = height - 2*border
        width = width - 2*xEndDelta
        x = x + xStartDelta + xEndDelta
        y = y + border
        offsetX = height*CoTanTheta
    end
    local hpW = width*ratio
    local h = height
    _M.QuadRect(x, y, hpW, h, offsetX, color)

    if redRatio > 0 then
        local redW = width*redRatio
        _M.QuadRect(x+hpW, y, redW, h, offsetX, redColor)        
    end
end

---------------------------------
-- Complex Render Funcs
---------------------------------

-- from x, y, down to top, dimmed, dir: 1 = down to top, -1 = top to down
function _M.DimmedRect(x, y, width, height, color, dir)
    if dir == nil then
        dir = 1
    end
    -- color = SetAlpha(color, 0xFF)

    local iteration = math.min(math.abs(height), 32)
    local alpha = ((color >> 24) & 0xFF)

    local offsetH = math.max(math.floor(math.abs(height)/iteration), 1)
    if height < 0 then
        offsetH = -offsetH
    end
    for i = 1, iteration, 1 do
        local c = _M.SetAlpha(color, math.floor((iteration-i)*alpha/iteration))
        local posY = y-(i-1)*offsetH*dir
        Rect(x, posY, width, offsetH, c)
    end
end

-- colors: number[1], datas: (number[1])[1], max: max of all datas elements
function _M.FilledLinePlots(x, y, h, thickness, colors, solidColors, datas, max, fill)
    if not datas or not colors or not solidColors then return end

    for idx = 1, #datas, 1 do
        -- local idx = j
        if not colors[idx] then goto continue end
        local color = colors[idx]

        if not solidColors[idx] then goto continue end
        local solidColor = solidColors[idx]

        local data = datas[idx]
        local topPoints = {}
        -- filled lines
        for i = 1, #data, 1 do
            local ratio = 1
            if max > 0 then
                ratio = data[i] / max
            elseif max <= 0 then
                ratio = 0
            end
            if ratio > 1 then
                ratio = 1
            end

            local height = math.floor(ratio * h)
            if height <= 0 then
                height = 1
            end

            local posX = x + (i - 1) * thickness
            local posY = y
            -- Rect(posX, posY - height, thickness, -thickness, SetAlpha(colors[idx], 0xFF))
            topPoints[i] = {
                x = posX,
                y = posY - height,
            }

            if fill then
                if thickness == 1 or i == 1 then
                    Rect(posX, posY, thickness, -height, color)
                    -- DimmedRect(posX, posY-height, thickness, height, color, -1)
                else
                    local k = (topPoints[i].y - topPoints[i-1].y) / (topPoints[i].x - topPoints[i-1].x)
                    Rect(posX, posY, 1, -height, color, -1)
                    -- DimmedRect(posX, posY-height, 1, height, color, -1)
                    for j = 1, thickness-1, 1 do
                        -- local x1 = topPoints[i-1].x + i
                        local y1 = math.floor(k*j + topPoints[i-1].y - posY)
                        Rect(posX - thickness + j, posY, 1, y1, color)
                        -- DimmedRect(posX - thickness + j, posY + y1, 1, math.abs(y1), color, -1)
                    end
                end
            end
        end
        -- lines
        for i = 1, #data - 1, 1 do
            if topPoints[i] and topPoints[i+1] then
                Line(topPoints[i].x, topPoints[i].y, topPoints[i+1].x, topPoints[i+1].y, 1, solidColor)
            end
        end
        ::continue::
    end
end


---------------------------------
-- Typeset Utilities
---------------------------------
---@class FontConfig : TypesetConfig
---@field FontSize number
---@field Color number color from imgui picker
---@field Bold boolean
---@field Italic boolean

---@param cfg FontConfig
---@return FontConfig, boolean
function _M.DefaultFontConfig(cfg)
    local changed = false
    cfg, changed = Typeset.DefaultConfig(cfg)

    if not cfg.Color then
        cfg.Color = 0xFFFFFFFF
        changed = true
    end
    if not cfg.FontSize then
        cfg.FontSize = 18 *LibConf.UIScale
        changed = true
    end
    if cfg.Bold == nil then
        cfg.Bold = false
        changed = true
    end
    if cfg.Italic == nil then
        cfg.Italic = false
        changed = true
    end

    return cfg, changed
end

---@param cfg FontConfig
function _M.LoadD2dFontWithConfig(cfg)
    if not cfg then return FontUtils.LoadD2dFont() end
    return FontUtils.LoadD2dFont(cfg.FontSize, cfg.Bold, cfg.Italic)
end

---@param cfg FontConfig
function _M.TextWithConfig(x, y, msg, cfg)
    cfg = _M.DefaultFontConfig(cfg)
    if not cfg.Enable then return end
    Text(x, y, cfg.Color, msg, cfg.FontSize, cfg.Bold, cfg.Italic)
end

---@param cfg FontConfig
---@param text string
function _M.TextRenderer(cfg, text)
    local Renderer = {}
    Renderer.render =
    ---@param param RenderParam
    function(param)
        _M.SmartText(param.x, param.y, param.width, param.height, cfg, text)
    end
    Renderer.size = function()
        return _M.TextSize(cfg, text)
    end
    return Renderer
end

---@param cfg FontConfig
---@param text string
function _M.TextSize(cfg, text)
    local textW, textH = 0, 0
    if cfg.Width == nil or cfg.Height == nil then
        textW, textH = _M.Measure(cfg, text)
    end
    if cfg.Width ~= nil then
        textW = cfg.Width
    end
    if cfg.Height ~= nil then
        textH = cfg.Height
    end

    return textW, textH
end

---@param divX number
---@param divY number
---@param divWidth number
---@param divHeight number
---@param cfg FontConfig
---@param text string
---@return number, number, number, number # actual x, y, text w, text h 
function _M.SmartText(divX, divY, divWidth, divHeight, cfg, text)
    if not text or text == "" then return divX, divY, 0, 0 end

    cfg = _M.DefaultFontConfig(cfg)
    if not cfg.Enable then return divX, divY, 0, 0 end

    local textW, textH = 0, 0
    if cfg.Width == nil or cfg.Height == nil then
        textW, textH = _M.Measure(cfg, text)
    end
    if cfg.Width ~= nil then
        textW = cfg.Width
    end
    if cfg.Height ~= nil then
        textH = cfg.Height
    end

    local x, y, w, h = Typeset.Calculate(divX, divY, divWidth, divHeight, textW, textH, cfg)

    Text(x, y, _M.ReverseRGB(cfg.Color), text, cfg.FontSize, cfg.Bold, cfg.Italic)

    return x, y, textW, textH
end

---@param config FontConfig
---@param title string
---@param simpleMode boolean|nil
function _M.FontConfigMenu(config, title, simpleMode)
    local configChanged = false
    local changed

    config, configChanged = _M.DefaultFontConfig(config)

    if imgui.tree_node(title) then
        changed, config = Typeset.Menu(config, config.Absolute or simpleMode)
        configChanged = configChanged or changed

        changed, config.FontSize = imgui.slider_int("Font Size", config.FontSize, 4, 40)
        configChanged = configChanged or changed
        changed, config.Bold = imgui.checkbox("Bold", config.Bold)
        configChanged = configChanged or changed
        changed, config.Italic = imgui.checkbox("Italic", config.Italic)
        configChanged = configChanged or changed
    
        changed, config.Color = imgui.color_picker("Font Color", config.Color)
        configChanged = configChanged or changed
        imgui.tree_pop()
    end
    
    return configChanged, config
end

---@class RectConfig : TypesetConfig
---@field Width number
---@field Height number
---@field UseBackground boolean
---@field BackgroundColor number color from imgui picker
---@field Absolute boolean
---@field IsFillRect boolean
---@field ParallelogramOffsetX number
---@field OutlineThickness number
---@field OutlineColor number
---@field ShrinkSize number
---@field Color number color from imgui picker
---@field RightToLeft boolean
---@field TopToDown boolean
---@field DownToTop boolean

---@param cfg RectConfig
---@return RectConfig, boolean
function _M.DefaultRectConfig(cfg)
    local changed = false
    cfg, changed = Typeset.DefaultConfig(cfg)

    if cfg.Width == nil then
        cfg.Width = 0
        changed = true
    end
    if cfg.Height == nil then
        cfg.Height = 0
        changed = true
    end
    if not cfg.Color then
        cfg.Color = 0xFFFFFFFF
        changed = true
    end
    if cfg.UseBackground == nil then
        cfg.UseBackground = true
        changed = true
    end
    if not cfg.BackgroundColor then
        cfg.BackgroundColor = 0x90000000
        changed = true
    end
    if cfg.Absolute == nil then
        cfg.Absolute = false
        changed = true
    end
    if cfg.IsFillRect == nil then
        cfg.IsFillRect = false
        changed = true
    end
    if cfg.ParallelogramOffsetX == nil then
        cfg.ParallelogramOffsetX = 0
        changed = true
    end
    if not cfg.OutlineThickness then
        cfg.OutlineThickness = 0
        changed = true
    end
    if not cfg.OutlineColor then
        cfg.OutlineColor = 0xFF000000
        changed = true
    end
    if not cfg.ShrinkSize then
        cfg.ShrinkSize = 0
        changed = true
    end
    if cfg.RightToLeft == nil then
        cfg.RightToLeft = false
        changed = true
    end
    if cfg.TopToDown == nil then
        cfg.TopToDown = false
        changed = true
    end
    if cfg.DownToTop == nil then
        cfg.DownToTop = false
        changed = true
    end
    return cfg, changed
end

function _M.__FillRect(cfg, posX, posY, width, height, rectW, rectH, ratio, ratio2, color2, captureRatio)
    -- if ratio <= 0 then return end

    local paralleX = cfg.ParallelogramOffsetX
    local shrinkSize = cfg.ShrinkSize
    local shrinkSizeX = math.min(shrinkSize, math.floor(width/2))
    local shrinkSizeY = math.min(shrinkSize, math.floor(height/2))

    local CoTanTheta = 0
    local SinTheta = 1
    if paralleX == 0 then
        if shrinkSize > 0 then
            posX = posX + shrinkSizeX
            posY = posY + shrinkSizeY
            width = width - 2*shrinkSize
            height = height - 2*shrinkSize
            if width < 0 then
                width = 1
            end
            if height < 0 then
                height = 1
            end
        end
    else
        if shrinkSize > 0 then
            CoTanTheta = paralleX/height
            SinTheta = height / math.sqrt(height*height+paralleX*paralleX)
            local xEndDelta = shrinkSizeX /SinTheta
            local xStartDelta = shrinkSizeX *CoTanTheta
            height = height - 2*shrinkSize
            width = width - 2*xEndDelta
            posX = posX + xStartDelta + xEndDelta
            posY = posY + shrinkSizeY
            paralleX = height*CoTanTheta
            if width < 0 then
                width = 1
            end
            if height < 0 then
                height = 1
            end
        end

        local xStartDelta = 0
        if cfg.RightToLeft then
        elseif cfg.TopToDown then
            paralleX = paralleX*ratio -- paralleX/rectH *height
        elseif cfg.DownToTop then
            posX = posX + paralleX*(1-ratio) -- paralleX/rectH *(rectH*(1-ratio))
            paralleX = paralleX*ratio
        end
    end

    local x, y, w, h = posX, posY, width, height
    local x2, y2, w2, h2 = posX, posY, width, height
    local p2 = paralleX
    if cfg.RightToLeft then
        w = math.floor(width * ratio)
        x = posX + width - w

        if ratio2 and color2 then
            w2 = math.floor(width*ratio2)
            x2 = x - w2
        end
    elseif cfg.TopToDown then
        h = math.floor(height * ratio)

        if ratio2 and color2 then
            h2 = math.floor(height*ratio2)
            x2 = x + h*CoTanTheta
            y2 = y + h
            p2 = h2*CoTanTheta
        end
    elseif cfg.DownToTop then
        h = math.floor(height * ratio)
        y = posY + height - h
        
        if ratio2 and color2 then
            h2 = math.floor(height*ratio2)
            y2 = y - h2
            p2 = h2*CoTanTheta
            x2 = x - p2
        end
    else
        w = math.floor(width * ratio)
        if ratio2 and color2 then
            w2 = math.floor(width*ratio2)
            x2 = x + w
        end
    end

    if paralleX == 0 then
        _M.Rect(x, y, w, h, _M.ReverseRGB(cfg.Color))
        if ratio2 and color2 then
            _M.Rect(x2, y2, w2, h2, _M.ReverseRGB(color2))
        end
    else
        _M.QuadRect(x, y, w, h, paralleX, _M.ReverseRGB(cfg.Color))
        if ratio2 and color2 then
            _M.QuadRect(x2, y2, w2, h2, p2, _M.ReverseRGB(color2))
        end
    end
end

---@param cfg RectConfig
---@param ratio number
function _M.RectRenderer(cfg, ratio, ratio2, color2)
    local Renderer = {}
    Renderer.render =
    ---@param param RenderParam
    function(param)
        _M.SmartRect(param.x, param.y, param.width, param.height, cfg, ratio, ratio2, color2)
    end
    Renderer.size = function(div)
        return _M.RectSize(div, cfg)
    end
    return Renderer
end

---@param div Div
---@param cfg RectConfig
function _M.RectSize(div, cfg)
    local rectW, rectH = cfg.Width, cfg.Height
    -- if not rectW or rectW <= 0 then
    --     rectW = div.width
    -- end
    -- if not rectH or rectH <= 0 then
    --     rectH = div.height
    -- end
    return rectW, rectH
end

---@param divX number
---@param divY number
---@param divWidth number
---@param divHeight number
---@param cfg RectConfig
---@param ratio number rect fill ratio
---@return number, number, number, number # actual x, y, rect w, rect h 
function _M.SmartRect(divX, divY, divWidth, divHeight, cfg, ratio, ratio2, color2, captureRatio)
    cfg = _M.DefaultRectConfig(cfg)
    if not cfg.Enable then return divX, divY, 0, 0 end

    local rectW, rectH = cfg.Width, cfg.Height
    if not rectW or rectW <= 0 then
        rectW = divWidth
    end
    if not rectH or rectH <= 0 then
        rectH = divHeight
    end

    local paralleX = cfg.ParallelogramOffsetX

    local x, y, w, h = Typeset.Calculate(divX, divY, divWidth, divHeight, rectW, rectH, cfg)

    if cfg.UseBackground then
        if paralleX == 0 then
            Rect(x, y, rectW, rectH, _M.ReverseRGB(cfg.BackgroundColor))
        else
            _M.QuadRect(x, y, rectW, rectH, paralleX, _M.ReverseRGB(cfg.BackgroundColor))
        end
    end
    if cfg.IsFillRect and ratio then
        if ratio >= 1 then
            ratio = 1
        end

        local posX, posY, width, height = x, y, rectW, rectH
        _M.__FillRect(cfg, posX, posY, width, height, rectW, rectH, ratio, ratio2, color2, captureRatio)
    end

    if cfg.OutlineThickness > 0 then
        if paralleX == 0 then
            OutlineRect(x, y, rectW, rectH, cfg.OutlineThickness, _M.ReverseRGB(cfg.OutlineColor))
        else
            _M.OutlineQuadRect(x, y, rectW, rectH, paralleX, cfg.OutlineThickness, _M.ReverseRGB(cfg.OutlineColor))
        end
    end

    if captureRatio then
        if paralleX == 0 then
            if captureRatio ~= nil then
                -- Text(x, y, 0xffffffff, string.format("%0.2f", captureRatio*100))
                local upX = x + rectW * captureRatio
                local upY = y - 4
                local downX = upX
                local downY = y + rectH + 4
                Line(upX, upY, downX, downY, 2, 0xffffffff)
            end
        else
            if captureRatio ~= nil then
                -- Text(x, y, 0xffffffff, string.format("%0.2f", captureRatio*100))
                local upX = x + rectW * captureRatio
                local upY = y - 4
                local downX = upX + paralleX
                local downY = y + rectH + 4
                Line(upX, upY, downX, downY, 2, 0xffffffff)
            end
        end
    end
    return x, y, rectW, rectH
end

---@param config RectConfig
---@param title string
---@param simpleMode boolean|nil
function _M.RectConfigMenu(config, title, simpleMode)
    local configChanged = false
    local changed

    config, configChanged = _M.DefaultRectConfig(config)

    if imgui.tree_node(title) then
        changed, config = Typeset.Menu(config, config.Absolute or simpleMode)
        configChanged = configChanged or changed

        changed, config.Width = imgui.drag_int("Width", config.Width, 1, -3840, 3840)
        configChanged = configChanged or changed
        changed, config.Height = imgui.drag_int("Height", config.Height, 1, -2160, 2160)
        configChanged = configChanged or changed

        changed, config.ParallelogramOffsetX = imgui.drag_int("Parallelogram OffsetX", config.ParallelogramOffsetX, 1, -2160, 2160)
        configChanged = configChanged or changed

        changed, config.ShrinkSize = imgui.drag_int("Shrink Size", config.ShrinkSize, 1, 0, math.min(config.Width, config.Height)/2)
        configChanged = configChanged or changed

        changed, config.OutlineThickness = imgui.drag_int("Outline Thickness", config.OutlineThickness, 1, 0, 40)
        configChanged = configChanged or changed

        if config.OutlineThickness > 0 and imgui.tree_node("Outline Options") then
            changed, config.OutlineColor = imgui.color_picker("Outline Color", config.OutlineColor)
            configChanged = configChanged or changed
            
            imgui.tree_pop()
        end

        if config.IsFillRect then
            if imgui.tree_node("Fill Options") then
                    changed, config.RightToLeft = imgui.checkbox("Right to Left", config.RightToLeft)
                    configChanged = configChanged or changed

                    changed, config.TopToDown = imgui.checkbox("Top to Down", config.TopToDown)
                    configChanged = configChanged or changed

                    changed, config.DownToTop = imgui.checkbox("Down to Top", config.DownToTop)
                    configChanged = configChanged or changed

                    changed, config.Color = imgui.color_picker("Color", config.Color)
                    configChanged = configChanged or changed
                
                    changed, config.UseBackground = imgui.checkbox("Use Background", config.UseBackground)
                    configChanged = configChanged or changed
        
                    if config.UseBackground then
                        changed, config.BackgroundColor = imgui.color_picker("Background Color", config.BackgroundColor)
                        configChanged = configChanged or changed
                    end
                imgui.tree_pop()
            end
        else
            changed, config.UseBackground = imgui.checkbox("Use Color", config.UseBackground)
            configChanged = configChanged or changed
            if config.UseBackground then
                changed, config.BackgroundColor = imgui.color_picker("Color", config.BackgroundColor)
                configChanged = configChanged or changed
            end
        end


        imgui.tree_pop()
    end
    
    return configChanged, config
end

---@class CircleConfig : TypesetConfig
---@field Radius number
---@field Color number color from imgui picker
---@field IsFill boolean
---@field IsRing boolean
---@field RingWidth number
---@field UseBackground boolean
---@field BackgroundRatio boolean
---@field BackgroundColor number color from imgui picker
---@field IsFillOutline boolean
---@field OutlineThickness number
---@field OutlineColor number
---@field Clockwise boolean
---@field RingUseCircleBackground boolean
---@field RingAutoCircleBackgroundRadius boolean
---@field RingCircleBackgroundRadius number
---@field FillAngleOffset number

---@param cfg CircleConfig
---@return CircleConfig, boolean
function _M.DefaultCircleConfig(cfg)
    local changed = false
    cfg, changed = Typeset.DefaultConfig(cfg)

    if cfg.Radius == nil then
        cfg.Radius = 40 *LibConf.UIScale
        changed = true
    end
    if not cfg.Color then
        cfg.Color = 0xFFFFFFFF
        changed = true
    end
    if cfg.IsFill == nil then
        cfg.IsFill = false
        changed = true
    end
    if cfg.IsRing == nil then
        cfg.IsRing = false
        changed = true
    end
    if cfg.RingWidth == nil then
        cfg.RingWidth = 4 *LibConf.UIScale
        changed = true
    end
    if cfg.UseBackground == nil then
        cfg.UseBackground = true
        changed = true
    end
    if cfg.BackgroundRatio == nil then
        cfg.BackgroundRatio = 1
        changed = true
    end
    if not cfg.BackgroundColor then
        cfg.BackgroundColor = 0x90000000
        changed = true
    end
    if cfg.IsFillOutline == nil then
        cfg.IsFillOutline = false
        changed = true
    end
    if not cfg.OutlineThickness then
        cfg.OutlineThickness = 0
        changed = true
    end
    if not cfg.OutlineColor then
        cfg.OutlineColor = 0xFF000000
        changed = true
    end
    if cfg.Clockwise == nil then
        cfg.Clockwise = false
        changed = true
    end
    if cfg.RingUseCircleBackground == nil then
        cfg.RingUseCircleBackground = false
        changed = true
    end
    if cfg.RingAutoCircleBackgroundRadius == nil then
        cfg.RingAutoCircleBackgroundRadius = true
        changed = true
    end
    if cfg.RingCircleBackgroundRadius == nil then
        cfg.RingCircleBackgroundRadius = cfg.Radius+cfg.RingWidth/2
        changed = true
    end
    if not cfg.FillAngleOffset then
        cfg.FillAngleOffset = 0
        changed = true
    end
    return cfg, changed
end

---@param cfg CircleConfig
---@param ratio number
function _M.CircleRenderer(cfg, ratio, ratio2, color2)
    local Renderer = {}
    Renderer.render =
    ---@param param RenderParam
    function(param)
        _M.SmartCircle(param.x, param.y, param.width, param.height, cfg, ratio, ratio2, color2)
    end
    Renderer.size = function()
        return _M.CircleSize(cfg)
    end
    return Renderer
end

---@param cfg CircleConfig
function _M.CircleSize(cfg)
    local D = cfg.Radius*2
    return D, D
end

---@param divX number
---@param divY number
---@param divWidth number
---@param divHeight number
---@param cfg CircleConfig
---@param ratio number
---@return number, number, number, number # actual x, y, w, h 
function _M.SmartCircle(divX, divY, divWidth, divHeight, cfg, ratio, ratio2, color2)
    cfg = _M.DefaultCircleConfig(cfg)
    if not cfg.Enable then return divX, divY, 0, 0 end

    local radius = cfg.Radius
    local D = radius*2

    local xStart, yStart, w, h = Typeset.Calculate(divX, divY, divWidth, divHeight, D, D, cfg)

    local x = xStart + radius
    local y = yStart + radius
    if not ratio then
        ratio = 1
    end

    if cfg.IsRing then
        if cfg.UseBackground then
            if cfg.RingUseCircleBackground then
                if cfg.RingAutoCircleBackgroundRadius then
                    _M.FillCircle(x, y, radius-cfg.RingWidth/2, _M.ReverseRGB(cfg.BackgroundColor))
                else
                    _M.FillCircle(x, y, cfg.RingCircleBackgroundRadius, _M.ReverseRGB(cfg.BackgroundColor))
                end
            else
                _M.UIRing(x, y, radius, radius-cfg.RingWidth, cfg.BackgroundRatio, _M.ReverseRGB(cfg.BackgroundColor), cfg.Clockwise, cfg.FillAngleOffset)
            end
        end

        _M.UIRing(x, y, radius, radius-cfg.RingWidth, ratio, _M.ReverseRGB(cfg.Color), cfg.Clockwise, cfg.FillAngleOffset)

        if ratio2 and color2 then
            local start = cfg.FillAngleOffset + 360*(1-ratio)
            _M.UIRing(x, y, radius, radius-cfg.RingWidth, ratio2, _M.ReverseRGB(color2), cfg.Clockwise, start)
        end

        if cfg.IsFillOutline and cfg.OutlineThickness > 0 then
            _M.UIRingOutline(x, y, radius, radius-cfg.RingWidth, ratio, cfg.OutlineThickness, _M.ReverseRGB(cfg.OutlineColor), cfg.Clockwise, cfg.FillAngleOffset)
        end
    else
        if cfg.UseBackground then
            _M.FillCircle(x, y, radius, _M.ReverseRGB(cfg.BackgroundColor))
        end

        if cfg.IsFill then
            _M.UIPie(x, y, radius, ratio, _M.ReverseRGB(cfg.Color), cfg.Clockwise, cfg.FillAngleOffset)

            if cfg.IsFillOutline and cfg.OutlineThickness > 0 then
                _M.UIPieOutline(x, y, radius, ratio, cfg.OutlineThickness, _M.ReverseRGB(cfg.OutlineColor), cfg.Clockwise, cfg.FillAngleOffset)
            end
        else
            _M.FillCircle(x, y, radius, _M.ReverseRGB(cfg.Color))
        end
    end

    if not cfg.IsFillOutline and cfg.OutlineThickness > 0 then
        if cfg.IsRing then
            _M.Circle(x, y, radius, cfg.OutlineThickness, _M.ReverseRGB(cfg.OutlineColor))
            _M.Circle(x, y, radius-cfg.RingWidth, cfg.OutlineThickness, _M.ReverseRGB(cfg.OutlineColor))
        else
            _M.Circle(x, y, radius, cfg.OutlineThickness, _M.ReverseRGB(cfg.OutlineColor))
        end
    end

    return xStart, yStart, D, D
end

---@param config CircleConfig
---@param title string
---@param simpleMode boolean|nil
function _M.CircleConfigMenu(config, title, simpleMode)
    local configChanged = false
    local changed

    config, configChanged = _M.DefaultCircleConfig(config)

    if imgui.tree_node(title) then
        changed, config = Typeset.Menu(config, config.Absolute or simpleMode)
        configChanged = configChanged or changed

        changed, config.Radius = imgui.drag_int("Radius", config.Radius, 1, -3840, 3840)
        configChanged = configChanged or changed

        changed, config.IsRing = imgui.checkbox("Ring Mode", config.IsRing)
        configChanged = configChanged or changed

        if config.IsRing then
            changed, config.RingWidth = imgui.drag_int("Ring Width", config.RingWidth, 1, -3840, config.Radius-1)
            configChanged = configChanged or changed

            if config.UseBackground then
                changed, config.RingUseCircleBackground = imgui.checkbox("Use Circle Background", config.RingUseCircleBackground)
                configChanged = configChanged or changed

                if config.RingUseCircleBackground then
                    changed, config.RingAutoCircleBackgroundRadius = imgui.checkbox("Auto Circle Background Radius", config.RingAutoCircleBackgroundRadius)
                    configChanged = configChanged or changed

                    if not config.RingAutoCircleBackgroundRadius then
                        changed, config.RingCircleBackgroundRadius = imgui.drag_int("Background Radius", config.RingCircleBackgroundRadius, 1, -3840, 3840)
                        configChanged = configChanged or changed
                    end
                end
            end
        end

        if config.IsFill then
            if imgui.tree_node("Fill Options") then
                changed, config.Clockwise = imgui.checkbox("Clockwise", config.Clockwise)
                configChanged = configChanged or changed

                changed, config.FillAngleOffset = imgui.drag_int("Start Angle Offset", config.FillAngleOffset, 1, 0, 360)
                configChanged = configChanged or changed

                changed, config.Color = imgui.color_picker("Color", config.Color)
                configChanged = configChanged or changed
            
                changed, config.UseBackground = imgui.checkbox("Use Background", config.UseBackground)
                configChanged = configChanged or changed
    
                if config.UseBackground then
                    changed, config.BackgroundRatio = imgui.drag_float("Background Ratio", config.BackgroundRatio, 0.001, 0, 1)
                    configChanged = configChanged or changed
                    changed, config.BackgroundColor = imgui.color_picker("Background Color", config.BackgroundColor)
                    configChanged = configChanged or changed
                end
                imgui.tree_pop()
            end
        else
            changed, config.UseBackground = imgui.checkbox("Use Color", config.UseBackground)
            configChanged = configChanged or changed
            if config.UseBackground then
                changed, config.BackgroundColor = imgui.color_picker("Color", config.BackgroundColor)
                configChanged = configChanged or changed
            end
        end

        changed, config.OutlineThickness = imgui.drag_int("Outline Thickness", config.OutlineThickness, 1, 0, 40)
        configChanged = configChanged or changed

        if config.OutlineThickness > 0 and imgui.tree_node("Outline Options") then
            changed, config.IsFillOutline = imgui.checkbox("Outline Fill Mode", config.IsFillOutline)
            configChanged = configChanged or changed
    
            changed, config.OutlineColor = imgui.color_picker("Outline Color", config.OutlineColor)
            configChanged = configChanged or changed
            
            imgui.tree_pop()
        end

        imgui.tree_pop()
    end
    
    return configChanged, config
end

---@param cfg RectConfig
---@param image Image
function _M.ImageRenderer(cfg, image)
    local Renderer = {}
    Renderer.render =
    ---@param param RenderParam
    function(param)
        _M.SmartImage(param.x, param.y, param.width, param.height, cfg, image)
    end
    Renderer.size = function(div)
        return _M.ImageSize(div, cfg)
    end
    return Renderer
end

---@param div Div
---@param cfg RectConfig
function _M.ImageSize(div, cfg)
    local rectW, rectH = cfg.Width, cfg.Height
    return rectW, rectH
end

---@param divX number
---@param divY number
---@param divWidth number
---@param divHeight number
---@param cfg RectConfig
---@param image Image
---@return number, number, number, number # actual x, y, rect w, rect h 
function _M.SmartImage(divX, divY, divWidth, divHeight, cfg, image)
    cfg = _M.DefaultRectConfig(cfg)
    if not cfg.Enable then return divX, divY, 0, 0 end

    local rectW, rectH = cfg.Width, cfg.Height

    local x, y, w, h = Typeset.Calculate(divX, divY, divWidth, divHeight, rectW, rectH, cfg)

    D2dUtils.Image(image, x, y, rectW, rectH)

    return x, y, rectW, rectH
end

---------------------------------
-- DIV
-- Div is a render helper class that defines several useful auto-calculated functions and config menu
-- It is a horizontal layout, not a real div with vertical support.
---------------------------------
---@class DivCanvas : DivRenderer
---@field CanvasRect RectConfig
---@field Background fun(color: number)
---@field Text fun(cfg: FontConfig, msg: string)
---@field Rect fun(cfg: RectConfig, ratio: number|nil, ratio2: number|nil, color2: number|nil)
---@field Circle fun(cfg: CircleConfig, ratio: number|nil)
---@field Image fun(cfg: RectConfig, image: Image)

---@param rect RectConfig
---@param x number
---@param y number
---@param w number
---@param h number
---@return DivCanvas
function _M.NewDivCanvas(rect)
    rect = _M.DefaultRectConfig(rect)

    local Canvas = Typeset.NewDivRenderer(rect.OffsetX, rect.OffsetY, rect.Width, rect.Height, rect.Enable, rect.MarginX, rect.MarginY)

    Canvas.CanvasRect = rect

    Canvas._Init = Canvas.Init
    function Canvas.Init()
        Canvas.Enable = Canvas.CanvasRect.Enable
        if not Canvas.Enable then
            return
        end

        if Canvas.CanvasRect and Canvas.CanvasRect.UseBackground then
            Rect(Canvas.PosX, Canvas.PosY, Canvas.Width, Canvas.Height, _M.ReverseRGB(Canvas.CanvasRect.BackgroundColor))
        end

        Canvas._Init()
    end

    ---@param conf FontConfig
    ---@param msg string
    function Canvas.Text(conf, msg)
        return Canvas.Render(conf, _M.SmartText, msg)
    end

    ---@param conf RectConfig
    ---@param ratio number color ratio percentage
    function Canvas.Rect(conf, ratio, ratio2, color2, captureRatio)
        return Canvas.Render(conf, _M.SmartRect, ratio, ratio2, color2, captureRatio)
    end

    ---@param conf CircleConfig
    ---@param ratio number color ratio percentage
    function Canvas.Circle(conf, ratio, ratio2, color2)
        return Canvas.Render(conf, _M.SmartCircle, ratio, ratio2, color2)
    end

    ---@param conf RectConfig
    ---@param image Image color ratio percentage
    function Canvas.Image(conf, image)
        return Canvas.Render(conf, _M.SmartImage, image)
    end

    return Canvas
end

return _M