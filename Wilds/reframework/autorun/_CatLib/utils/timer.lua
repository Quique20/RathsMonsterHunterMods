-- Timer模块实现
local _M = {}

_M.timers = {}
_M.precise_timers = {} -- 新增精确计时器表

-- 检查计时器是否存在
-- @param tag string 计时器标签
-- @return boolean 计时器是否存在
function _M:exists(tag)
    return self.timers[tag] ~= nil
end

-- 检查精确计时器是否存在
-- @param tag string 计时器标签
-- @return boolean 精确计时器是否存在
function _M:existsPrecise(tag)
    return self.precise_timers[tag] ~= nil
end

-- 获取计时器剩余帧数
-- @param tag string 计时器标签
-- @return number|nil 剩余帧数，如果计时器不存在则返回nil
function _M:getRemainingFrames(tag)
    if not self.timers[tag] then
        return nil
    end
    return self.timers[tag].frame - self.timers[tag].current
end

-- 获取精确计时器剩余时间（毫秒）
-- @param tag string 计时器标签
-- @return number|nil 剩余时间（毫秒），如果计时器不存在则返回nil
function _M:getRemainingTimePrecise(tag)
    if not self.precise_timers[tag] then
        return nil
    end
    local current_time = os.clock() * 1000
    local end_time = self.precise_timers[tag].start_time + self.precise_timers[tag].duration
    return math.max(0, end_time - current_time)
end

function _M:getDebugRemainingFrames()
    local debug_string = ""
    for tag, t in pairs(self.timers) do
        debug_string = debug_string .. tag .. ": " .. (t.frame - t.current) .. "\n"
    end
    return debug_string
end

-- 获取所有精确计时器的调试信息
function _M:getDebugRemainingTimePrecise()
    local debug_string = ""
    local current_time = os.clock() * 1000
    for tag, t in pairs(self.precise_timers) do
        local remaining = math.max(0, (t.start_time + t.duration) - current_time)
        debug_string = debug_string .. tag .. ": " .. remaining .. "ms\n"
    end
    return debug_string
end

-- 运行计时器函数
-- @param tag string 计时器标签
-- @param frame number 计时器帧数
-- @param func function 计时器函数，每帧执行
-- @param stop_func function 计时器停止函数，可选
function _M:run(tag, frame, func, stop_func)
    if self.timers[tag] then
        -- 如果已存在同名计时器，刷新它
        self.timers[tag].frame = frame
        self.timers[tag].func = func
        self.timers[tag].stop_func = stop_func
    else
        -- 创建新计时器
        self.timers[tag] = {
            frame = frame,
            func = func,
            stop_func = stop_func,
            current = 0
        }
    end
end

-- 运行精确计时器函数
-- @param tag string 计时器标签
-- @param millisecond number 计时器时长（毫秒）
-- @param can_refreash boolean 是否可以刷新计时器，默认为true
-- @param func function 计时器函数，每帧执行
-- @param stop_func function 计时器停止函数，可选
function _M:runPrecise(tag, millisecond,can_refreash, func, stop_func)
    local current_time = os.clock() * 1000
    
    if self.precise_timers[tag] then
        if can_refreash then
            -- 如果已存在同名计时器，刷新它
            self.precise_timers[tag].duration = millisecond
            self.precise_timers[tag].start_time = current_time
            self.precise_timers[tag].func = func
            self.precise_timers[tag].stop_func = stop_func
        else
            return
        end
    else
        -- 创建新计时器
        self.precise_timers[tag] = {
            duration = millisecond,
            start_time = current_time,
            func = func,
            stop_func = stop_func
        }
    end
end

-- 计时器主循环，需要放在一个update函数中
-- 执行所有活动计时器的函数，更新计时，并在完成时移除计时器
function _M:runner()
    -- 处理基于帧的计时器
    for tag, t in pairs(self.timers) do
        -- 执行函数
        if t.func then
            t.func()
        end
        
        -- 更新计时
        t.current = t.current + 1
        
        -- 检查是否完成
        if t.current >= t.frame then
            -- 如果有停止回调函数，执行它
            if t.stop_func then
                t.stop_func()
            end
            -- 移除计时器
            self.timers[tag] = nil
        end
    end
    
    -- 处理精确计时器
    local current_time = os.clock() * 1000
    local tags_to_remove = {}
    
    for tag, t in pairs(self.precise_timers) do
        -- 执行函数
        if t.func then
            t.func()
        end
        
        -- 检查是否完成
        if current_time >= (t.start_time + t.duration) then
            -- 如果有停止回调函数，执行它
            if t.stop_func then
                t.stop_func()
            end
            -- 标记要移除的计时器
            table.insert(tags_to_remove, tag)
        end
    end
    
    -- 移除已完成的精确计时器
    for _, tag in ipairs(tags_to_remove) do
        self.precise_timers[tag] = nil
    end
end

-- 停止计时器
-- @param tag string 计时器标签
-- @param runStopFunc boolean 是否执行停止函数，默认为true
function _M:stop(tag, runStopFunc)
    if not self.timers[tag] then
        return
    end
    
    if runStopFunc ~= false and self.timers[tag].stop_func then
        self.timers[tag].stop_func()
    end
    
    self.timers[tag] = nil
end

-- 停止精确计时器
-- @param tag string 计时器标签
-- @param runStopFunc boolean 是否执行停止函数，默认为true
function _M:stopPrecise(tag, runStopFunc)
    if not self.precise_timers[tag] then
        return
    end
    
    if runStopFunc ~= false and self.precise_timers[tag].stop_func then
        self.precise_timers[tag].stop_func()
    end
    
    self.precise_timers[tag] = nil
end

-- 停止所有计时器
-- @param runStopFunc boolean 是否执行停止函数，默认为true
function _M:stopAll(runStopFunc)
    for tag, _ in pairs(self.timers) do
        self:stop(tag, runStopFunc)
    end
end

-- 停止所有精确计时器
-- @param runStopFunc boolean 是否执行停止函数，默认为true
function _M:stopAllPrecise(runStopFunc)
    for tag, _ in pairs(self.precise_timers) do
        self:stopPrecise(tag, runStopFunc)
    end
end

-- 停止所有类型的计时器
-- @param runStopFunc boolean 是否执行停止函数，默认为true
function _M:stopAllTimers(runStopFunc)
    self:stopAll(runStopFunc)
    self:stopAllPrecise(runStopFunc)
end


-- 返回模块
return _M
