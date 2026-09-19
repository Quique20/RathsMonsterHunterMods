local re = re
local sdk = sdk
local d2d = d2d
local imgui = imgui
local log = log
local json = json
local draw = draw

local Core = require("_CatLib")
local Draw = require("_CatLib.draw")
local Div = require("_CatLib.div")

local MOD_NAME = "_CatLib Test"
local mod = Core.NewMod(MOD_NAME)

local DebugXStart = 1000
local DebugYStart = 800

local DebugX = DebugXStart
local DebugY = DebugYStart
local DebugYDelta = 30

local LastDebugInfo = ""

mod.OnFrame(function ()
    imgui.text(LastDebugInfo)
end)

local function PrintDebugInfo(msg)
    LastDebugInfo = LastDebugInfo .. "\n" .. msg
    -- Draw.Text(DebugX, DebugY, 0xffffffff, tostring(msg))
    -- DebugY = DebugY + DebugYDelta
end

local function PrintDivSizeInfo(div)
    PrintDebugInfo(string.format("X,Y=%0.2f,%0.2f | W,H=%0.2f,%0.2f(%s|%s)", div.position.x, div.position.y, div.computed.width, div.computed.height, div.computed.widthWay, div.computed.heightWay))
end

local function PrintDivInfo(div)
    if not div.computed.debugLog then
        return
    end
    for i, log in pairs(div.computed.debugLog) do
        PrintDebugInfo(log)
    end
end

local function debug(root, startChildIndex)
    if startChildIndex == nil then
        startChildIndex = 1
    end
    PrintDebugInfo(string.format("Size: %0.2f,%0.2f", root.computed.width, root.computed.height))
    PrintDebugInfo(string.format("Children: %d", #root.children))
    PrintDivSizeInfo(root)
    PrintDivInfo(root)
    for i, child in pairs(root.children) do
        PrintDivSizeInfo(child)
        if i >= startChildIndex then
            -- PrintDivInfo(child)
        end
    end
end

local function GenLayer1Divs(count)
    local root = Div.new()
    -- root.display = "inline"

    local function NewChild(i)
        local div = Div.new()
        div.renderer = Draw.TextRenderer({
        }, "Row Text " .. tostring(i))
        root:add(div)
    end

    for i = 1, count do
        NewChild(i)
    end

    return root
end

local function TestEdgeCase()
    local startX = 400
    local startY = 400
    local width = 400
    local height = 200

    local function Gen(caseString)
        local root = GenLayer1Divs(3)
        root.position.x = startX
        root.position.y = startY
        root.width = width
        root.height = height

        startX = startX + width

        if startX > 3000 then
            startX = 400
            startY = startY + height
        end

        if caseString then
            local div = Div.new()
            div.renderer = Draw.TextRenderer({
            }, caseString)
            root:add(div)
        end

        return root
    end

    local root = Gen("刚好填满")
    for _, child in pairs(root.children) do
        child.width = width
    end
    root:render(true)

    local root = Gen("Auto填满")
    for _, child in pairs(root.children) do
        child.width = "auto"
    end
    root:render(true)
    debug(root)

    local root = Gen("填满高度")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.height = height
    end
    root:render(true)

    local root = Gen("Auto填满高度")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.height = "auto"
    end
    root:render(true)
    debug(root)
end

local function TestBasic()
    local startX = 400
    local startY = 400
    local width = 400
    local height = 200

    local function Gen(caseString)
        local root = GenLayer1Divs(8)
        root.position.x = startX
        root.position.y = startY
        root.width = width
        root.height = height

        startX = startX + width

        if startX > 3000 then
            startX = 400
            startY = startY + height
        end

        if caseString then
            local div = Div.new()
            div.renderer = Draw.TextRenderer({
            }, caseString)
            root:add(div)
        end

        return root
    end

    local root = Gen("基本情形")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    root:render(true)

    local root = Gen("行内模式")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.top = 2
        child.margin.bottom = 8
        child.margin.right = 2
    end
    
    root:render(true)

    local root = Gen("右到左")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 8
        child.margin.right = 2
        child.margin.top = 2
    end
    
    root:render(true)

    local root = Gen("下到上")
    root.display = "inline"
    root.verticalDirection = "bottom-to-top"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.top = 12
        child.margin.bottom = 2
        child.margin.right = 4
    end
    
    root:render(true)

    local root = Gen("右到左，下到上")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    root.verticalDirection = "bottom-to-top"
    for _, child in pairs(root.children) do
        -- child.width = 90
        child.margin.top = 12
        child.margin.bottom = 2
        child.margin.left = 8
        child.margin.right = 2
    end
    
    root:render(true)

    local root = Gen("Margin恰好贴合")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.right = 10
    end
    root.children[#root.children].width = 0

    
    root:render(true)

    local root = Gen("最后一个元素的margin-right应该被忽略")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        -- 自动换行的情况下，最后一个元素的margin-right应该被忽略
        child.margin.right = 11
    end
    root.children[#root.children].width = 0
    
    root:render(true)
    
    local root = Gen("margin-left则不能被忽略")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        -- margin left 自然不能忽略
        child.margin.left = 11
    end
    
    root:render(true)

    local root = Gen("右到左则忽略margin-left")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 11
    end
    root.children[#root.children].width = 0
    
    root:render(true)

    local root = Gen("上到下忽略bottom")
    for _, child in pairs(root.children) do
        child.height = 40
        child.margin.bottom = 11
        -- (40+11)*4-11 = 193 < 200
    end
    root.children[#root.children].width = 0
    
    root:render(true)

    startX = 400
    startY = startY + height

    local root = Gen("出框了")
    for _, child in pairs(root.children) do
        child.height = 90
        child.margin.bottom = 11
        -- 29*7-4 = 199 < 200
    end
    root.children[#root.children].width = 0
    
    root:render(true)

    startX = startX + 100

    local root = Gen("超长文本出框了")
    for _, child in pairs(root.children) do
        child.height = 90
        child.margin.bottom = 11
        -- 29*7-4 = 199 < 200
    end
    root.children[#root.children].width = 0
    
    root:render(true)
    debug(root)

    startX = 400
    startY = startY + height

    local root = Gen("Auto Width")
    for _, child in pairs(root.children) do
        child.width = "auto"
        child.height = 90
        child.margin.bottom = 11
        -- 29*7-4 = 199 < 200
    end
    root.children[#root.children].width = 0
    
    root:render(true)
end

local function TestNested()
    local canvas = Div.new()
    canvas.position.x = 400
    canvas.position.y = 400
    canvas.width = 2000
    canvas.height = 1200
    canvas.display = "inline"

    local function Gen(caseString)
        local root = GenLayer1Divs(8)
        root.position.x = 400
        root.position.y = 400
        root.width = 400
        root.height = 200

        if caseString then
            local div = Div.new()
            div.renderer = Draw.TextRenderer({
            }, caseString)
            root:add(div)
        end

        canvas:add(root)

        return root
    end

    local root = Gen("基本情形")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    -- root:render(true)

    local root = Gen("行内模式")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.top = 2
        child.margin.bottom = 8
        child.margin.right = 2
    end
    
    -- root:render(true)

    local root = Gen("右到左")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 8
        child.margin.right = 2
        child.margin.top = 2
    end
    
    -- root:render(true)

    local root = Gen("下到上")
    root.display = "inline"
    root.verticalDirection = "bottom-to-top"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.top = 12
        child.margin.bottom = 2
        child.margin.right = 4
    end
    
    -- root:render(true)

    local root = Gen("右到左，下到上")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    root.verticalDirection = "bottom-to-top"
    for _, child in pairs(root.children) do
        -- child.width = 90
        child.margin.top = 12
        child.margin.bottom = 2
        child.margin.left = 8
        child.margin.right = 2
    end
    
    -- root:render(true)

    local root = Gen("Margin恰好贴合")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.right = 10
    end
    root.children[#root.children].width = 0

    
    -- root:render(true)

    local root = Gen("最后一个元素的margin-right应该被忽略")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        -- 自动换行的情况下，最后一个元素的margin-right应该被忽略
        child.margin.right = 11
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)
    
    local root = Gen("margin-left则不能被忽略")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        -- margin left 自然不能忽略
        child.margin.left = 11
    end
    
    -- root:render(true)

    local root = Gen("右到左则忽略margin-left")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 11
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)

    local root = Gen("上到下忽略bottom")
    for _, child in pairs(root.children) do
        child.height = 40
        child.margin.bottom = 11
        -- (40+11)*4-11 = 193 < 200
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)

    local root = Gen("出框了")
    for _, child in pairs(root.children) do
        child.height = 90
        child.margin.bottom = 11
        -- 29*7-4 = 199 < 200
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)

    local root = Gen("超长文本出框了")
    for _, child in pairs(root.children) do
        child.height = 90
        child.margin.bottom = 11
        -- 29*7-4 = 199 < 200
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)

    local root = Gen("子元素Auto Width应该填满")
    for _, child in pairs(root.children) do
        child.width = "auto"
        child.height = 90
        child.margin.bottom = 11
        -- 29*7-4 = 199 < 200
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)

    local root = Gen("虽然上个内容很宽，但是父元素不宽，所以这个在同一行")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    local root = Gen("父元素超级宽因此换行")
    root.width = canvas.width
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    local root = Gen("基本元素，应该换行")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    local root = Gen("基本情形")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    canvas:render(true)
    debug(canvas)
end

local function SubDivSizeVariousCases()
    local canvas = Div.new()
    canvas.position.x = 400
    canvas.position.y = 400
    canvas.width = 2000
    canvas.height = 1200
    canvas.display = "inline"
    canvas.horizontalDirection = "right-to-left"
    canvas.verticalDirection = "bottom-to-top"

    local function Gen(caseString)
        local root = GenLayer1Divs(8)
        root.position.x = 400
        root.position.y = 400
        root.width = 400
        root.height = 200

        if caseString then
            local div = Div.new()
            div.renderer = Draw.TextRenderer({
            }, caseString)
            root:add(div)
        end

        canvas:add(root)

        return root
    end

    local root = Gen("基本情形")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    root.height = 180
    
    -- root:render(true)

    local root = Gen("行内模式")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.top = 2
        child.margin.bottom = 8
        child.margin.right = 2
    end
    root.width = 380
    root.height = 220
    
    -- root:render(true)

    local root = Gen("右到左")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 8
        child.margin.right = 2
        child.margin.top = 2
    end
    
    -- root:render(true)

    local root = Gen("下到上")
    root.display = "inline"
    root.verticalDirection = "bottom-to-top"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.top = 12
        child.margin.bottom = 2
        child.margin.right = 4
    end
    root.height = 333
    
    -- root:render(true)

    local root = Gen("右到左，下到上")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    root.verticalDirection = "bottom-to-top"
    for _, child in pairs(root.children) do
        -- child.width = 90
        child.margin.top = 12
        child.margin.bottom = 2
        child.margin.left = 8
        child.margin.right = 2
    end
    
    -- root:render(true)

    local root = Gen("Margin恰好贴合")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.right = 10
    end
    root.children[#root.children].width = 0
    root.height = 220

    
    -- root:render(true)

    local root = Gen("最后一个元素的margin-right应该被忽略")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        -- 自动换行的情况下，最后一个元素的margin-right应该被忽略
        child.margin.right = 11
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)
    
    local root = Gen("margin-left则不能被忽略")
    root.display = "inline"
    for _, child in pairs(root.children) do
        child.width = 90
        -- margin left 自然不能忽略
        child.margin.left = 11
    end
    
    -- root:render(true)

    local root = Gen("右到左则忽略margin-left")
    root.display = "inline"
    root.horizontalDirection = "right-to-left"
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 11
    end
    root.children[#root.children].width = 0
    root.height = 420
    
    -- root:render(true)

    local root = Gen("上到下忽略bottom")
    for _, child in pairs(root.children) do
        child.height = 40
        child.margin.bottom = 11
        -- (40+11)*4-11 = 193 < 200
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)

    local root = Gen("出框了")
    for _, child in pairs(root.children) do
        child.height = 90
        child.margin.bottom = 11
        -- 29*7-4 = 199 < 200
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)

    local root = Gen("超长文本出框了")
    for _, child in pairs(root.children) do
        child.height = 90
        child.margin.bottom = 11
        -- 29*7-4 = 199 < 200
    end
    root.children[#root.children].width = 0
    
    -- root:render(true)

    local root = Gen("虽然上个内容很宽，但是父元素不宽，所以这个在同一行")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    local root = Gen("父元素超级宽因此换行")
    root.width = canvas.width
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    local root = Gen("基本元素，应该换行")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    local root = Gen("基本情形")
    for _, child in pairs(root.children) do
        child.width = 90
        child.margin.left = 2
        child.margin.right = 8
        child.margin.top = 2
    end
    
    canvas:render(true)
    debug(canvas)
end

local function Get3Divs()
    local root = Div.new()
    local function Gen(caseString)
        local div = Div.new()
        div.width = 50
        div.height = 50
        div.renderer = Draw.TextRenderer({
        }, caseString)

        root:add(div)

        return div
    end

    local box1 = Gen("Box1")
    box1.width = 100
    box1.height = 50
    box1.margin.left = 10
    box1.margin.right = 10
    
    local box2 = Gen("Box2")
    box2.width = 150
    box2.height = 80
    
    local box3 = Gen("Box3")
    box3.width = 200
    box3.height = 60

    return true
end

local function TestFlex()
    local startX = 400
    local startY = 400
    local width = 500
    local height = 200

    local function Gen(caseString)
        local root = GenLayer1Divs(3)
        root.position.x = startX
        root.position.y = startY
        root.width = width
        root.height = height
        root.display = "flex"

        for _, child in pairs(root.children) do
            child.margin.left = 2
            child.margin.right = 12
            child.margin.top = 2
            child.margin.bottom = 12
        end

        startX = startX + width + 20

        if startX > 3000 then
            startX = 400
            startY = startY + height + 20
        end

        if caseString then
            root.renderer = Draw.TextRenderer({
            }, caseString)
        end

        return root
    end

    local root = Gen("垂直分列居中")
    root.flexDirection = "column"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.children[1].margin.left = 10
    root.children[1].margin.right = 40
    root.children[3].margin.right = 40

    root:render(true)

    local root = Gen("垂直分列")
    root.flexDirection = "column"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("\n\n———————垂直分列左对齐")
    root.flexDirection = "column"
    root.justifyContent = "space-between"
    root.alignItems = "flex-start"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("垂直分列右对齐")
    root.flexDirection = "column"
    root.justifyContent = "space-between"
    root.alignItems = "flex-end"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("\n\n———————垂直分列拉伸")
    root.flexDirection = "column"
    root.justifyContent = "space-between"
    root.alignItems = "stretch"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    startX = 400
    startY = startY + height + 20

    local root = Gen("反向垂直分列居中")
    root.flexDirection = "column-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.children[1].margin.left = 10
    root.children[1].margin.right = 40
    root.children[3].margin.right = 40

    root:render(true)

    local root = Gen("反向垂直分列")
    root.flexDirection = "column-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("\n\n———————反向垂直分列左对齐")
    root.flexDirection = "column-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "flex-start"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("反向垂直分列右对齐")
    root.flexDirection = "column-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "flex-end"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("\n\n———————反向垂直分列拉伸")
    root.flexDirection = "column-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "stretch"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    startX = 400
    startY = startY + height + 20

    local root = Gen("水平分列居中")
    root.flexDirection = "row"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.children[1].margin.left = 10
    root.children[1].margin.right = 40
    root.children[3].margin.right = 40

    root:render(true)

    local root = Gen("水平分列")
    root.flexDirection = "row"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("\n\n\n\n水平分列上对齐")
    root.flexDirection = "row"
    root.justifyContent = "space-between"
    root.alignItems = "flex-start"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("水平分列下对齐")
    root.flexDirection = "row"
    root.justifyContent = "space-between"
    root.alignItems = "flex-end"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("\n\n\n\n水平分列拉伸")
    root.flexDirection = "row"
    root.justifyContent = "space-between"
    root.alignItems = "stretch"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)
    startX = 400
    startY = startY + height + 20

    local root = Gen("反向水平分列居中")
    root.flexDirection = "row-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.children[1].margin.left = 10
    root.children[1].margin.right = 40
    root.children[3].margin.right = 40

    root:render(true)

    local root = Gen("反向水平分列")
    root.flexDirection = "row-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("\n\n\n\n反向水平分列上对齐")
    root.flexDirection = "row-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "flex-start"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("反向水平分列下对齐")
    root.flexDirection = "row-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "flex-end"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    local root = Gen("\n\n\n\n反向水平分列拉伸")
    root.flexDirection = "row-reverse"
    root.justifyContent = "space-between"
    root.alignItems = "stretch"
    root.children[1].margin.top = 10
    root.children[1].margin.bottom = 40
    root.children[3].margin.bottom = 40

    root:render(true)

    startX = 400
    startY = startY + height + 20

    local root = Gen("水平均分")
    root.flexDirection = "row"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.columns = 3
    root.children[1].margin.left = 10
    root.children[1].margin.right = 40
    root.children[3].margin.right = 40

    root:render(true)

    local root = Gen("垂直均分")
    root.flexDirection = "column"
    root.justifyContent = "space-between"
    root.alignItems = "center"
    root.columns = 3
    root.children[1].margin.left = 10
    root.children[1].margin.right = 40
    root.children[3].margin.right = 40

    root:render(true)
end

mod.D2dRegister(function ()
    DebugX = DebugXStart
    DebugY = DebugYStart
    LastDebugInfo = ""
    -- TestBasic()
    -- TestNested()
    -- TestEdgeCase()
    -- SubDivSizeVariousCases()
    TestFlex()
end)
