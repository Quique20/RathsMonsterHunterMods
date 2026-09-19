local setmetatable = setmetatable
local pairs = pairs
local ipairs = ipairs
local type = type
local tostring = tostring
local tonumber = tonumber
local table = table
local math = math

---@type Div
local Div = {}
Div.__index = Div

---@class Square
---@field top number
---@field right number
---@field bottom number
---@field left number

---@class Vec2
---@field x number
---@field y number

---@class Box
---@field width number
---@field height number

---@class RenderParam
---@field x number
---@field y number
---@field width number
---@field height number
---@field margin Square
---@field padding Square
---@field border Square
---@field backgroundColor number
---@field displayMode string
---@field childrenCount number
---@field debug boolean

---@class Div
---@field parent Div|nil
---@field children Div[]
---@field renderer function(param: RenderParam)
---@field position Vec2
---@field width number|string
---@field height number|string
---@field margin Square
---@field padding Square
---@field border Square
---@field computed Box
---@field display string 显示模式。block为块模式，flex为自动/弹性模式
---@field flexDirection string
---@field justifyContent string
---@field breakBefore boolean 【块模式】该元素换行
---@field breakAfter boolean 【块模式】下一个元素换行
---@field autoBreak boolean 【块模式】溢出宽度或高度时自动换行
---@field horizontalDirection string 水平方向，默认从左到右
---@field verticalDirection string 垂直方向，默认从上到下

---@return Div
function Div.new()
    local self = setmetatable({
        children = {},
        renderer = nil, -- 渲染回调函数
        -- 默认属性
        position = {x=0, y=0},
        width = 0, height = 0,
        margin = {top=0, right=0, bottom=0, left=0},
        padding = {top=0, right=0, bottom=0, left=0},
        border = {top=0, right=0, bottom=0, left=0},
        display = "block",
        -- flexDirection = "row",
        -- justifyContent = "flex-start",
        breakAfter = false,
        breakBefore = false,
        autoBreak = true,
        horizontalDirection = "left-to-right",
        verticalDirection = "top-to-down",
        computed = {width=0, height=0} -- 最终计算的宽高
    }, Div)
    return self
end

---@param x number
---@param y number
function Div:RePos(x, y)
    self.position.x = x
    self.position.y = y
end

---@param w number|nil width
---@param h number|nil height
function Div:ReSize(w, h)
    if w ~= nil then
        self.width = w
    end
    if h ~= nil then
        self.height = h
    end
end

---@param child Div
function Div:add(child)
    if not child then return end
    child.parent = self
    table.insert(self.children, child)
end

-- 触发渲染回调的私有方法
function Div:_fireRenderer(debug)
    if debug then
        d2d.outline_rect(self.position.x, self.position.y, self.computed.width, self.computed.height, 1, 0xff00ff00)
        if self.margin.left ~= 0 or self.margin.right ~= 0 or self.margin.bottom ~= 0 or self.margin.top ~= 0 then
            d2d.outline_rect(self.position.x-self.margin.left, self.position.y-self.margin.top, self.computed.width+self.margin.left+self.margin.right, self.computed.height+self.margin.top+self.margin.bottom, 1, 0x88ff0000)
        end
        if self.padding.left ~= 0 or self.padding.right ~= 0 or self.padding.bottom ~= 0 or self.padding.top ~= 0 then
            d2d.outline_rect(self.position.x+self.padding.left, self.position.y+self.padding.top, self.computed.width-self.padding.left-self.padding.right, self.computed.height-self.padding.top-self.padding.bottom, 1, 0x880000ff)
        end
    end
    if not self.renderer then
        return
    end
    local params = {
        -- 基础布局信息
        x = self.position.x,
        y = self.position.y,
        width = self.computed.width,
        height = self.computed.height,
        
        -- 盒子模型细节
        margin = self.margin,
        padding = self.padding,
        border = self.border,
        
        -- 样式属性
        backgroundColor = self.backgroundColor,
        displayMode = self.display,
        
        -- 层级信息
        childrenCount = #self.children,
        
        -- 原始对象引用（谨慎使用）
        raw = self, -- 用于高级操作,

        debug = debug,
    }
    
    -- 执行渲染回调
    self.renderer.render(params)
end

local FontUtils = require("_CatLib.font")

function Div:_render(parentContentX, parentContentY, parentContentWidth, parentContentHeight, debug)
    -- 触发渲染回调（此时position已包含全局坐标）
    self:_fireRenderer(debug)
    for _, child in pairs(self.children) do
        child:_render(parentContentX, parentContentY, parentContentWidth, parentContentHeight, debug)
    end
end

-- 渲染入口函数
function Div:render(parentContentX, parentContentY, parentContentWidth, parentContentHeight, debug)
    -- self:_debugLog(string.format("Render Start"))
    if (parentContentX == nil and self.position.x) or (parentContentX == true or parentContentX == false) then
        -- self:_debugLog(string.format("auto pick params"))
        debug = parentContentX == true

        parentContentX = self.position.x
        parentContentY = self.position.y
        parentContentWidth = self.width
        parentContentHeight = self.height

        -- d2d.text(FontUtils.LoadD2dFont(18), string.format("Debug: %s", tostring(debug)), parentContentX-100, parentContentY-20, 0xffffffff)
    end
    -- self:_debugLog(string.format("Render at %0.2f,%0.2f, Size: %0.2f,%0.2f", parentContentX, parentContentY, parentContentWidth, parentContentHeight))

    self:measure(parentContentX, parentContentY, parentContentWidth, parentContentHeight, debug)
    
    -- 触发渲染回调（此时position已包含全局坐标）
    -- self:_debugLog(string.format("Measure End"))
    self:_render(parentContentX, parentContentY, parentContentWidth, parentContentHeight, debug)
    -- self:_debugLog(string.format("_Render End"))
end

-- 布局计算
function Div:measure(parentContentX, parentContentY, parentContentWidth, parentContentHeight, debug)
    -- self:_debugLog(string.format("Measure at %0.2f,%0.2f, Size: %0.2f,%0.2f", parentContentX, parentContentY, parentContentWidth, parentContentHeight))

    -- 计算自身位置（考虑外边距）
    self.position.x = parentContentX + self.margin.left
    self.position.y = parentContentY + self.margin.top

    -- 计算自身尺寸
    -- d2d.text(FontUtils.LoadD2dFont(18), string.format("W,H: %s,%s", tostring(parentContentWidth), tostring(parentContentHeight)), parentContentX-100, parentContentY-40, 0xffffffff)
    self:_calculateDimensions(parentContentWidth, parentContentHeight)
    -- d2d.text(FontUtils.LoadD2dFont(18), string.format("W,H: %s,%s", tostring(self.computed.width), tostring(self.computed.height)), parentContentX-100, parentContentY-20, 0xffffffff)

    -- 计算实际内容区域（扣除padding和border）
    local contentX = self.position.x + self.padding.left + self.border.left
    local contentY = self.position.y + self.padding.top + self.border.top
    local contentWidth = self.computed.width 
        - self.padding.left - self.padding.right
        - self.border.left - self.border.right
    local contentHeight = self.computed.height 
        - self.padding.top - self.padding.bottom
        - self.border.top - self.border.bottom

    -- self:_debugLog(string.format("Measure: %s", self.display))
    -- 根据显示模式布局子元素
    if self.display == "flex" then
        self:_layoutFlex(contentX, contentY, contentWidth, contentHeight, debug)
    else
        self:_layoutDefault(contentX, contentY, contentWidth, contentHeight, debug)
    end
end

function Div:_debugLog(msg)
    if not self.computed.debugLog then
        self.computed.debugLog = {}
    end
    table.insert(self.computed.debugLog, msg)
end

function Div:_widthCalcLog(msg)
    if not self.computed.widthWay then
        self.computed.widthWay = msg
        return
    end
    self.computed.widthWay = self.computed.widthWay .. "," .. msg
end

function Div:_heightCalcLog(msg)
    if not self.computed.heightWay then
        self.computed.heightWay = msg
        return
    end
    self.computed.heightWay = self.computed.heightWay .. "," .. msg
end

-- 块模式下，默认换行，auto填满宽度
function Div:_calculateBlockLayoutDimension()
    -- self:_debugLog("checking BlockLayout")
    if self.computed.width <= 0 and self.width == "auto" then
        -- self:_debugLog("BlockLayout: Fill auto Width")
        self.width = "100%"
    end
end

-- 行内模式下，默认换列，auto填满高度
function Div:_calculateInlineLayoutDimensions()
    -- self:_debugLog("checking InlineLayout")
    if self.computed.height <= 0 and self.height == "auto" then
        -- self:_debugLog("InlineLayout: Fill auto Height")
        self.height = "100%"
    end
end

-- 如果没有设置宽高，则计算自身宽高。
-- 对于父元素控制的情形，应在父元素的布局函数中设置 child.computed 的值
---@return number, number
function Div:_calculateDimensions(parentWidth, parentHeight)
    -- 在没有渲染器时，设置默认值 auto
    if not self.renderer then
        if not self.width then
            self.width = "auto"
        end
        if not self.height then
            self.height = "auto"
        end
    end
    
    -- self:_debugLog(string.format("CalculateDimensions; Display mode %s, W,H: %s, %s", self.display, tostring(self.width), tostring(self.height)))
    -- 处理块模式、行内模式
    if self.parent and self.parent.display == "block" then
        self:_calculateBlockLayoutDimension()
    elseif self.parent and self.parent.display == "inline" then
        self:_calculateInlineLayoutDimensions()
    end

    -- self:_widthCalcLog("calc " .. tostring(self.computed.width))
    -- self:_heightCalcLog("calc " .. tostring(self.computed.height))
    self:_widthCalcLog("calc")
    self:_heightCalcLog("calc")
    -- 处理宽度
    if self.computed.width <= 0 then
        self:_widthCalcLog("proc")
        -- if self.width == "auto" then
        --     self.width = "100%"
        -- end
        if type(self.width) == "string" then
            if self.width:sub(-1) == "%" then
                self.computed.width = parentWidth * tonumber(self.width:sub(1,-2))/100
                self:_widthCalcLog("percentage")
            end
        else
            self.computed.width = self.width
            self:_widthCalcLog("direct")
        end
        if self.computed.width <= 0 then
            self.computed.width = self:contentWidth()
            self:_widthCalcLog("content")
        end
    end

    -- 处理高度
    if self.computed.height <= 0 then
        self:_heightCalcLog("proc")
        -- if self.height == "auto" then
        --     self.height = "100%"
        -- end
        if type(self.height) == "string" then
            if self.height:sub(-1) == "%" then
                self.computed.height = parentHeight * tonumber(self.height:sub(1,-2))/100
                self:_heightCalcLog("percentage")
            end
        else
            self.computed.height = self.height
            self:_heightCalcLog("direct")
        end
        if self.computed.height <= 0 then
            self.computed.height = self:contentHeight()
            self:_heightCalcLog("content")
        end
    end

    self:_widthCalcLog(";")
    self:_heightCalcLog(";")
    return self.computed.width, self.computed.height
end

function Div:contentWidth()
    if self.computed.width and self.computed.width > 0 then
        return self.computed.width
    end
    if self.width and type(self.width) == "number" and self.width > 0 then
        return self.width
    end
    if self.renderer then
        local width = self.renderer.size(self)
        return width
    end
    return 0
end

function Div:contentHeight()
    if self.computed.height and self.computed.height > 0 then
        return self.computed.height
    end
    if self.height and type(self.height) == "number" and self.height > 0 then
        return self.height
    end
    if self.renderer then
        local _, height = self.renderer.size(self)
        return height
    end
    return 0
end

-- 块模式与行内模式渲染
-- 块模式下，每个元素默认换行、auto填满宽度；行内模式下，每个元素默认在同一行、auto填满高度。
-- 默认轴向中，水平坐标为X（宽度），垂直坐标为Y（高度）
function Div:_layoutDefault(contentX, contentY, contentWidth, contentHeight, debug)
    -- 根据显示模式选择布局方向
    local isInline = self.display == "inline"
    local isLeftToRight = self.horizontalDirection == "left-to-right"
    local isTopToDown = self.verticalDirection == "top-to-down"
    
    -- self:_debugLog(string.format("IsInline: %s, LtR: %s, TtD: %s", tostring(isInline), tostring(isLeftToRight), tostring(isTopToDown)))

    -- 初始化布局变量
    local startX = contentX
    if not isLeftToRight then
        -- 右到左
        startX = contentX + contentWidth
    end

    local startY = contentY
    if not isTopToDown then
        -- 下到上
        startY = contentY + contentHeight
    end

    -- 计算中的坐标指针
    local offsetX, offsetY = 0, 0

    local maxLineHeight = 0 -- 【行内模式】当前行最大高度
    local maxLineWidth = 0 -- 【块模式】当前列最大宽度

    -- 遍历所有子元素
    for i, child in ipairs(self.children) do
        -- self:_debugLog(string.format("Child: %d", i))
        -- self:_debugLog(string.format("offset: %0.2f,%0.2f", offsetX, offsetY))
        -- 处理强制换行属性
        local shouldBreak = child.breakBefore or 
            (i > 1 and self.children[i-1].breakAfter)
        -- self:_debugLog(string.format("first ShouldBreak: %s", tostring(shouldBreak)))

        child:_calculateDimensions(contentWidth, contentHeight)
        -- 计算子元素内容尺寸
        local childContentWidth = child:contentWidth()
        local childContentHeight = child:contentHeight()
        -- self:_debugLog(string.format("   Size: %0.2f (%s,%s),%0.2f (%s,%s)", childContentWidth, tostring(child.width), tostring(child.computed.width), childContentHeight, tostring(child.height), tostring(child.computed.height)))
        
        -- 计算子元素总尺寸
        local childTotalWidth, childTotalHeight
        childTotalWidth = childContentWidth + child.margin.left + child.margin.right
        childTotalHeight = childContentHeight + child.margin.top + child.margin.bottom

        -- 处理自动换行属性。必须不能是第一个元素，否则会导致一个元素都放不下
        if not shouldBreak and self.autoBreak and i > 1 then
            if isInline then
                -- 行内模式下，X坐标超过宽度
                local examWidth = offsetX + childTotalWidth
                if isLeftToRight then
                    -- 从左到右，那么最后一个元素的margin right可以被忽略
                    examWidth = examWidth - child.margin.right
                else
                    -- 反之，margin left可以被忽略
                    examWidth = examWidth - child.margin.left
                end
                shouldBreak = examWidth > contentWidth
                -- self:_debugLog(string.format("exceed inline? %0.2f > %0.2f: %s", examWidth, contentWidth, tostring(shouldBreak)))
            else
                -- 块模式下，Y坐标超过高度
                local examHeight = offsetY + childTotalHeight
                if isTopToDown then
                    examHeight = examHeight - child.margin.bottom
                else
                    examHeight = examHeight - child.margin.top
                end
                shouldBreak = examHeight > contentHeight
                -- self:_debugLog(string.format("exceed block? %0.2f > %0.2f: %s", examHeight, contentHeight, tostring(shouldBreak)))
            end
        end

        -- self:_debugLog(string.format("-- ShouldBreak: %s", tostring(shouldBreak)))

        -- 换行计算
        -- 行内模式：溢出换行Y
        -- 块模式：溢出换列X
        if shouldBreak then
            if isInline then
                offsetX = 0
                offsetY = offsetY + maxLineHeight
                maxLineHeight = 0
            else
                offsetY = 0
                offsetX = offsetX + maxLineWidth
                maxLineWidth = 0
            end
        end
        
        -- self:_debugLog(string.format("-- Before Pos: %0.2f,%0.2f", child.position.x, child.position.y))
        -- self:_debugLog(string.format("   offset: %0.2f,%0.2f", offsetX, offsetY))
        -- 定位子元素：根据水平、垂直朝向，修正坐标、添加 margin/padding
        if isLeftToRight then
            -- 从左到右
            child.position.x = startX + offsetX
            child.position.x = child.position.x + child.margin.left
        else
            child.position.x = startX - offsetX
            child.position.x = child.position.x - child.margin.right - child.margin.left
            -- 由于渲染器只能从左到右渲染，因此需要将X坐标额外左偏元素宽度
            child.position.x = child.position.x - childContentWidth
        end

        if isTopToDown then
            -- 从上到下
            child.position.y = startY + offsetY
            child.position.y = child.position.y + child.margin.top
        else
            child.position.y = startY - offsetY
            child.position.y = child.position.y - child.margin.bottom - child.margin.top
            -- 由于渲染器只能从上到下渲染，因此需要将Y坐标额外左偏元素高度
            child.position.y = child.position.y - childContentHeight
        end
        
        -- self:_debugLog(string.format("-- Child Pos: %0.2f,%0.2f, Size: %0.2f,%0.2f", child.position.x, child.position.y, childContentWidth, childContentHeight))
        -- 递归布局子元素
        child:measure(
            child.position.x,
            child.position.y,
            childContentWidth,
            childContentHeight,
            debug
        )
        
        maxLineHeight = math.max(maxLineHeight, childTotalHeight)
        maxLineWidth = math.max(maxLineWidth, childTotalWidth)

        -- 更新布局指针
        -- 行内模式：自动换列X
        -- 块模式：自动换行Y
        if isInline then
            offsetX = offsetX + childTotalWidth
        else
            offsetY = offsetY + childTotalHeight
        end
        -- self:_debugLog(string.format("-- next offset: %0.2f,%0.2f", offsetX, offsetY))
    end
    
    -- 自动调整容器尺寸（当高度为auto时）
    -- if self.height == "auto" then
    --     if isInline then
    --         self.computed.height = offsetY + maxLineHeight - contentY
    --             + self.padding.top + self.padding.bottom
    --             + self.border.top + self.border.bottom
    --     else
    --         self.computed.height = offsetY - contentY
    --             + self.padding.top + self.padding.bottom
    --             + self.border.top + self.border.bottom
    --     end
    -- end
end

function Div:_layoutFlex(contentX, contentY, contentWidth, contentHeight, debug)
    -- self:_debugLog(string.format("FlexLayout at %0.2f,%0.2f, Size: %0.2f,%0.2f", contentX, contentY, contentWidth, contentHeight))
    -- 确定主轴与交叉轴方向
    -- 轴为row时，从左到右
    -- 轴为column时，从上到下
    local isRow = self.flexDirection == "row" or self.flexDirection == "row-reverse"
    local isLeftToRight = self.horizontalDirection == "left-to-right"
    if self.flexDirection == "row-reverse" then
        isLeftToRight = false
    end
    local isTopToDown = self.verticalDirection == "top-to-down"
    if self.flexDirection == "column-reverse" then
        isTopToDown = false
    end

    -- 初始化布局变量
    local startX = contentX
    if not isLeftToRight then
        -- 右到左
        startX = contentX + contentWidth
    end

    local startY = contentY
    if not isTopToDown then
        -- 下到上
        startY = contentY + contentHeight
    end

    local mainAxisStart, mainAxisSize, crossAxisStart, crossAxisSize
    if isRow then
        mainAxisStart = self.padding.left + self.border.left
        mainAxisSize = contentWidth
        crossAxisStart = self.padding.top + self.border.top
        crossAxisSize = contentHeight
    else -- column
        mainAxisStart = self.padding.top + self.border.top
        mainAxisSize = contentHeight
        crossAxisStart = self.padding.left + self.border.left
        crossAxisSize = contentWidth
    end

    -- 收集子项信息 ------------------------------------------------------
    local totalMainSize = 0
    local maxCrossSize = 0 -- 用于交叉轴对齐
    local count = #self.children

    local rowColumnWidth = (contentWidth - 
        (self.padding.left + self.padding.right + self.border.left + self.border.right)) / count
    local columnRowHeight = (contentHeight - 
        (self.padding.top + self.padding.bottom + self.border.top + self.border.bottom)) / count

    -- self:_debugLog(string.format("W,H: %0.2f,%0.2f", contentWidth, contentHeight))
    for _, child in ipairs(self.children) do
        child:_calculateDimensions(contentWidth, contentHeight)

        -- Columns模式
        if self.columns then
            if isRow then
                -- 均分列宽
                child.computed.width = rowColumnWidth
            else
                -- 均分行高
                child.computed.height = columnRowHeight
            end
        end

        -- 计算主轴 交叉轴尺寸（包含margin）
        local mainSize, crossSize, mainMarginStart, mainMarginEnd, crossMarginStart, crossMarginEnd
        if isRow then
            mainSize = child.computed.width + child.margin.left + child.margin.right
            crossSize = child.computed.height + child.margin.top + child.margin.bottom
        else
            mainSize = child.computed.height + child.margin.top + child.margin.bottom
            crossSize = child.computed.width + child.margin.left + child.margin.right

        end

        totalMainSize = totalMainSize + mainSize
        maxCrossSize = math.max(maxCrossSize, crossSize)
    end
    
    -- 计算剩余空间与起始位置 ---------------------------------------------
    local remainingSpace = mainAxisSize - totalMainSize
    remainingSpace = math.max(remainingSpace, 0) -- 不允许负剩余空间
    local betweenSpace = 0 -- 元素间间隔
    
    -- 分配主轴剩余空间（JustifyContent）-----------------------------------
    if self.justifyContent == "space-between" and count > 1 then
        betweenSpace = remainingSpace / (count - 1)
    elseif self.justifyContent == "space-around" then
        betweenSpace = remainingSpace / count
    elseif self.justifyContent == "space-evenly" then
        betweenSpace = remainingSpace / (count + 1)
    end
    
    -- 计算中的坐标指针
    local offsetX, offsetY = 0, 0

    -- 布局每个子项 ------------------------------------------------------
    for _, child in ipairs(self.children) do
        
        -- 主轴位置计算
        if isRow then
            -- 水平方向
            if isLeftToRight then
                -- 从左到右
                child.position.x = startX + offsetX
                child.position.x = child.position.x + child.margin.left
            else
                -- 从右到左
                child.position.x = startX - offsetX
                child.position.x = child.position.x - child.margin.right
                -- 由于渲染器只能从左到右渲染，因此需要将X坐标额外左偏元素宽度
                child.position.x = child.position.x - child.computed.width
            end
            offsetX = offsetX + betweenSpace + child.computed.width + child.margin.left + child.margin.right
        else
            -- 垂直方向
            if isTopToDown then
                -- 从上到下
                child.position.y = startY + offsetY
                child.position.y = child.position.y + child.margin.top
            else
                child.position.y = startY - offsetY
                child.position.y = child.position.y - child.margin.bottom
                -- 由于渲染器只能从上到下渲染，因此需要将Y坐标额外左偏元素高度
                child.position.y = child.position.y - child.computed.height
            end
            offsetY = offsetY + betweenSpace + child.computed.height + child.margin.top + child.margin.bottom
        end
        
        -- 交叉轴对齐（AlignItems）-----------------------------------------
        local align = self.alignItems or "stretch"

        if isRow then
            if align == "center" then
                local size = child.computed.height + child.margin.top + child.margin.bottom
                if isTopToDown then
                    child.position.y = startY + (contentHeight - size)/2 + child.margin.top
                else
                    child.position.y = startY - (contentHeight - size)/2 - child.margin.bottom
                end
            elseif align == "flex-start" then
                if isTopToDown then
                    child.position.y = startY + child.margin.top
                else
                    child.position.y = startY - child.margin.bottom
                end
            elseif align == "flex-end" then
                local size = child.computed.height + child.margin.top + child.margin.bottom
                if isTopToDown then
                    child.position.y = startY + contentHeight - size + child.margin.top
                else
                    child.position.y = startY - (contentHeight - size + child.margin.bottom)
                end
            elseif align == "stretch" then
                if isTopToDown then
                    -- 拉伸子项到容器尺寸
                    child.computed.height = contentHeight - child.margin.top - child.margin.bottom
                    child.position.y = startY + child.margin.top
                else
                    -- 拉伸子项到容器尺寸
                    child.computed.height = contentHeight - child.margin.top - child.margin.bottom
                    child.position.y = startY + child.margin.bottom
                end
            end
        else
            if align == "center" then
                local size = child.computed.width + child.margin.left + child.margin.right
                if isLeftToRight then
                    child.position.x = startX + (contentWidth - size)/2 + child.margin.left
                else
                    child.position.x = startX - (contentWidth - size)/2 - child.margin.right
                end
            elseif align == "flex-start" then
                if isLeftToRight then
                    child.position.x = startX + child.margin.left
                else
                    child.position.x = startX - child.margin.right
                end
            elseif align == "flex-end" then
                local size = child.computed.width + child.margin.left + child.margin.right
                if isLeftToRight then
                    child.position.x = startX + contentWidth - size + child.margin.left
                else
                    child.position.x = startX - (contentWidth - size + child.margin.right)
                end
            elseif align == "stretch" then
                if isLeftToRight then
                    -- 拉伸子项到容器尺寸
                    child.computed.width = contentWidth - child.margin.left - child.margin.right
                    child.position.x = startX + child.margin.left
                else
                    child.computed.width = contentWidth - child.margin.left - child.margin.right
                    child.position.x = startX - child.margin.right
                end
            end
        end

        -- 递归布局子元素
        child:measure(
            child.position.x,
            child.position.y,
            child.computed.width,
            child.computed.height,
            debug
        )
    end
    
    -- 更新容器高度（当方向为row且高度为auto时）----------------------------
    -- if self.height == "auto" and isRow then
    --     self.computed.height = maxCrossSize + 
    --         self.padding.top + self.padding.bottom +
    --         self.border.top + self.border.bottom
    -- end
end

return Div

-- todo: children render order
-- todo: size fit content