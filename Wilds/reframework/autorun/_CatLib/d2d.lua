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
local LibConf = require("_CatLib.config")
local IsD2d = LibConf.RenderBackend == 1

local _M = {}

---@param func fun()
---@param postFunc fun()?, if nil, func as postFunc
function _M.D2dRegister(func, postFunc)
    if d2d == nil then return end

    if IsD2d then
        if postFunc == nil then
            d2d.register(function()
                FontUtils.LoadD2dFont()
            end, func)
        else
            d2d.register(func, postFunc)
        end
    else
        if postFunc == nil then
            re.on_frame(func)
        else
            -- func()
            re.on_frame(postFunc)
        end
    end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param color number
function _M.Rect(x, y, w, h, color)
    if not color then return end

    if IsD2d then
        d2d.fill_rect(x, y, w, h, color)
    else
        draw.filled_rect(x, y, w, h, color)
    end
end

---@param x number
---@param y number
---@param w number
---@param h number
---@param thickness number
---@param color number
function _M.OutlineRect(x, y, w, h, thickness, color)
    if not color then return end
    if IsD2d then
        d2d.outline_rect(x, y, w, h, thickness, color)
    else
        draw.outline_rect(x, y, w, h, color)
    end
end

---@param fontCfg FontConfig|number
function _M.LoadFont(fontCfg, bold, italic)
    if IsD2d then
        if type(fontCfg) == "number" then
            return FontUtils.LoadD2dFont(fontCfg, bold, italic)
        elseif fontCfg then
            return FontUtils.LoadD2dFont(fontCfg.FontSize, fontCfg.Bold, fontCfg.Italic)
        end
        return FontUtils.LoadD2dFont()
    else
        if type(fontCfg) == "number" then
            return FontUtils.LoadImguiCJKFont(fontCfg)
        elseif fontCfg then
            return FontUtils.LoadImguiCJKFont(fontCfg.FontSize)
        end
        return FontUtils.LoadImguiCJKFont()
    end
end

---@param x number
---@param y number
---@param color number
---@param msg string
---@param size number|nil
---@param bold boolean|nil
---@param italic boolean|nil
function _M.Text(x, y, color, msg, size, bold, italic)
    if not color then return end
    if IsD2d then
        d2d.text(FontUtils.LoadD2dFont(size, bold, italic), msg, x, y, color)
    else
        if imgui.push_font_size then
            size = FontUtils.GetNormalizedFontSize(size)
            imgui.push_font_size(size)
        else
            -- imgui.push_font(_M.LoadFont(size))
        end
        draw.text(msg, x, y, color)
        if imgui.pop_font_size then
            imgui.pop_font_size()
        else
            -- imgui.pop_font()
        end
    end
end

---@param x1 number
---@param y2 number
---@param x2 number
---@param y2 number
---@param thickness number
---@param color number
function _M.Line(x1, y1, x2, y2, thickness, color)
    if not color then return end
    if IsD2d then
        d2d.line(x1, y1, x2, y2, thickness, color)
    else
        draw.line(x1, y1, x2, y2, color)
    end
end

function _M.LoadImage(fullPath)
    if IsD2d then
        local img = d2d.Image.new(fullPath)
        if not img then
            log.error(string.format("Image not found: %s", fullPath))
        end
        return img
    end
end

function _M.Image(image, x, y, sizeX, sizeY)
    if not image then return end
    if IsD2d then
        d2d.image(image, x, y, sizeX, sizeY)
    else
    end
end

function _M.Quad(x1, y1, x2, y2, x3, y3, x4, y4, thickness, color)
    if not color then return end
    if IsD2d then
        d2d.quad(x1, y1, x2, y2, x3, y3, x4, y4, thickness, color)
    else
        draw.outline_quad(x1, y1, x2, y2, x3, y3, x4, y4, color)
    end
end

function _M.FillQuad(x1, y1, x2, y2, x3, y3, x4, y4, color)
    if not color then return end
    if IsD2d then
        d2d.fill_quad(x1, y1, x2, y2, x3, y3, x4, y4, color)
    else
        draw.filled_quad(x1, y1, x2, y2, x3, y3, x4, y4, color)
    end
end

function _M.Circle(x, y, r, thickness, color)
    if not color then return end
    if IsD2d then
        d2d.circle(x, y, r, thickness, color)
    else
        draw.outline_circle(x, y, r, color)
    end
end

function _M.FillCircle(x, y, r, color)
    if not color then return end
    if IsD2d then
        d2d.fill_circle(x, y, r, color)
    else
        draw.filled_circle(x, y, r, color)
    end
end

function _M.Pie(x, y, r, startAngle, sweepAngle, color, clockwise)
    if not color then return end
    if IsD2d then
        d2d.pie(x, y, r, startAngle, sweepAngle, color, clockwise)
    else
    end
end

function _M.PieOutline(x, y, r, startAngle, sweepAngle, thickness, color, clockwise)
    if not color then return end
    if IsD2d then
        d2d.outline_pie(x, y, r, startAngle, sweepAngle, thickness, color, clockwise)
    else
    end
end

function _M.Ring(x, y, outerR, innerR, start, sweep, color, clockwise)
    if not color then return end
    if innerR > outerR then
        outerR, innerR = innerR, outerR
    end
    if IsD2d then
        d2d.ring(x, y, outerR, innerR, start, sweep, color, clockwise)
    else
    end
end

function _M.RingOutline(x, y, outerR, innerR, start, sweep, thickness, color, clockwise)
    if not color then return end
    if innerR > outerR then
        outerR, innerR = innerR, outerR
    end
    if IsD2d then
        d2d.outline_ring(x, y, outerR, innerR, start, sweep, thickness, color, clockwise)
    else
    end
end

---@param fontCfg FontConfig|number
function _M.Measure(fontCfg, text)
    if IsD2d then
        if type(fontCfg) == "number" then
            return FontUtils.LoadD2dFont(fontCfg):measure(text)
        elseif fontCfg then
            return FontUtils.LoadD2dFont(fontCfg.FontSize, fontCfg.Bold, fontCfg.Italic):measure(text)
        end
        return FontUtils.LoadD2dFont():measure(text)
    else
        local needPopFontSize = false
        if imgui.push_font_size then
            if type(fontCfg) == "number" then
                local size = FontUtils.GetNormalizedFontSize(fontCfg)
                imgui.push_font_size(size)
                needPopFontSize = true
            elseif fontCfg then
                local size = FontUtils.GetNormalizedFontSize(fontCfg.FontSize)
                imgui.push_font_size(size)
                needPopFontSize = true
            end
        end
        local size = imgui.calc_text_size(text)

        if needPopFontSize and imgui.pop_font_size then
            imgui.pop_font_size()
        end

        return size.x, size.y
    end    
end

return _M