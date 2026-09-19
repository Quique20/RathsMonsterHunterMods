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

local _M = {}

---@param text string
function _M.Tooltip(text, ...)
	if imgui.is_item_hovered() then
		imgui.set_tooltip(string.format(text, ...))
	end
end

---@param tag string
---@param func fun(): boolean
---@param closeFunc nil|fun(): boolean
---@param flags nil|number
---@return boolean
function _M.OpenWindow(tag, func, closeFunc, flags)
    local open = imgui.begin_window(tag, true, flags)
    if open then
        func()
        imgui.end_window()
    else
        if closeFunc then
            closeFunc()
        end
    end

    return open
end

---@param func fun(): boolean
function _M.Rect(func)
    imgui.begin_rect()
    func()
    imgui.end_rect()
end

---@param tag string
---@param func fun(): boolean
function _M.Header(tag, func)
    local open = imgui.collapsing_header(tag)
    if open and func then
        func()
    end
    return open
end

---@param tag string
---@param func fun(): boolean
---@return boolean
function _M.Tree(tag, func)
    local open = imgui.tree_node(tag)
    if open and func then
        func()
        imgui.tree_pop()
    end
    return open
end

---@param tag string
---@param func fun(): boolean
function _M.Button(tag, func)
    local clicked = imgui.button(tag)
    if clicked and func then
        func()
    end
    return clicked
end

return _M
