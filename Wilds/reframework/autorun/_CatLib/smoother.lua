
local DebouncedUpdater = {}
DebouncedUpdater.__index = DebouncedUpdater

-- 构造函数
function DebouncedUpdater.new(smoothFactor)
    local self = setmetatable({}, DebouncedUpdater)
    self.smoothFactor = smoothFactor or 0.1
    self.lastX = nil
    self.lastY = nil
    return self
end

function DebouncedUpdater:update(x, y)
    if self.lastX and self.lastY then
        local smoothedX = self.lastX + self.smoothFactor * (x - self.lastX)
        local smoothedY = self.lastY + self.smoothFactor * (y - self.lastY)

        self.lastX, self.lastY = smoothedX, smoothedY

        return smoothedX, smoothedY
    else
        self.lastX, self.lastY = x, y
        return x, y
    end
end

return DebouncedUpdater