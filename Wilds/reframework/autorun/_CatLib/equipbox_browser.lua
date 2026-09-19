-- 装备箱浏览增强：搜索 / 技能筛选 / 分类 / 排序 / 最近编辑定位
-- 供机械武器编辑器与护石编辑器使用

-- By @Kains https://space.bilibili.com/3706935291415181

local imgui = imgui
local string = string
local table = table
local ipairs = ipairs

local _M = {}

local canScrollHere = imgui.set_scroll_here_y ~= nil
local canNextItemOpen = imgui.set_next_item_open ~= nil

function _M.NewState()
    return {
        SearchText = "",      -- 名称搜索
        FilterKey = 0,        -- 分类选项下标（0 = 全部）
        SortMode = 0,         -- 0 = 箱子顺序，1 = 按分类值
        SkillKey = 0,         -- 技能筛选下标（0 = 全部）
        LastEditedIdx = nil,  -- 最近编辑的条目索引
        LastEditedName = nil, -- 最近编辑的条目名（每帧同步最新值）
        ScrollToIdx = nil,    -- 待滚动/展开的条目索引（一次性）
    }
end

-- 标记条目被编辑过，渲染时会自动滚到视口中央并强制展开
function _M.MarkEdited(state, idx, name)
    if idx ~= nil then
        state.LastEditedIdx = idx
        state.ScrollToIdx = idx
    end
    if name and name ~= "" then
        state.LastEditedName = name
    end
end

-- 渲染条目前调用；命中待定位条目时滚动并展开
function _M.BeginScroll(state, idx)
    if state.ScrollToIdx ~= nil and idx == state.ScrollToIdx then
        if canScrollHere then
            imgui.set_scroll_here_y(0.5)
        end
        if canNextItemOpen then
            imgui.set_next_item_open(true)
        end
        state.ScrollToIdx = nil
        return true
    end
    return false
end

-- 最近编辑信息条；条目被筛掉时提示，按钮自动清筛后定位
function _M.EditedBar(state, filtered)
    if state.LastEditedIdx == nil then
        return
    end
    imgui.text(string.format("Last edited: %s", state.LastEditedName or string.format("Item %d", state.LastEditedIdx)))
    imgui.same_line()
    if imgui.button("Go to item##goto_edited") then
        if filtered then
            local found = false
            for _, e in ipairs(filtered) do
                if e.idx == state.LastEditedIdx then
                    found = true
                    break
                end
            end
            if not found then
                state.SearchText = ""
                state.SkillKey = 0
                state.FilterKey = 0
            end
        end
        state.ScrollToIdx = state.LastEditedIdx
    end
    if state.ScrollToIdx ~= nil and filtered then
        local found = false
        for _, e in ipairs(filtered) do
            if e.idx == state.ScrollToIdx then
                found = true
                break
            end
        end
        if not found then
            imgui.text("The last edited item is not in the current results. Adjust the filters or press \"Go to item\".")
        end
    end
    imgui.separator()
end

-- 工具栏：技能筛选护石/名称搜索机械武器，分类与排序
function _M.Toolbar(state, opts)
    opts = opts or {}
    local changed = false

    if opts.skill and opts.skill.options then
        imgui.text("Skill:")
        imgui.same_line()
        local c, k = imgui.combo("##browser_skill", state.SkillKey, opts.skill.options)
        if c then
            state.SkillKey = k
            changed = true
        end
    elseif opts.search then
        imgui.text("Search:")
        imgui.same_line()
        local c, t = imgui.input_text("##browser_search", state.SearchText)
        if c then
            state.SearchText = t or ""
            changed = true
        end
        imgui.same_line()
        if imgui.button("Clear##browser_search_clear") then
            if state.SearchText ~= "" then changed = true end
            state.SearchText = ""
        end
    end

    if opts.category then
        imgui.text("Category:")
        imgui.same_line()
        local c, k = imgui.combo("##browser_category", state.FilterKey, opts.category)
        if c then
            state.FilterKey = k
            changed = true
        end
    end

    if opts.sort then
        imgui.text("Sort:")
        imgui.same_line()
        local c, k = imgui.combo("##browser_sort", state.SortMode, opts.sort)
        if c then
            state.SortMode = k
            changed = true
        end
    end

    imgui.separator()

    return changed
end

-- 过滤 + 排序。categoryKeyOf 把分类选项下标映射到实际分类值（0 = 全部）
function _M.Filter(state, entries, categoryKeyOf, skillList)
    local out = {}
    local search = state.SearchText
    if search ~= "" then search = string.lower(search) end

    local catFilter = state.FilterKey
    if catFilter == 0 then
        catFilter = -1
    elseif categoryKeyOf then
        catFilter = categoryKeyOf(catFilter)
    end

    local skillFilter = nil
    if skillList and state.SkillKey > 0 then
        skillFilter = skillList[state.SkillKey]
    end

    for _, e in ipairs(entries) do
        if catFilter < 0 or e.cat == catFilter then
            if not skillFilter or e.skill1 == skillFilter then
                if not search or string.find(string.lower(e.name or ""), search, 1, true) then
                    out[#out + 1] = e
                end
            end
        end
    end

    if state.SortMode == 1 then
        -- 按分类值排序，同类保持箱子顺序
        table.sort(out, function(a, b)
            if a.cat ~= b.cat then return a.cat < b.cat end
            return a.idx < b.idx
        end)
    end

    return out
end

return _M
