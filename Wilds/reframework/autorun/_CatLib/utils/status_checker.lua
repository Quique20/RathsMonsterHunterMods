local _M = {}

_M.status_list = {}


-- 状态检查
-- 只有当状态从false切换为true时，才会返回true
-- @param status_name string 状态名称
-- @param expression boolean 表达式
-- @return boolean 
function _M:StatusCheckTF(status_name,expression)
    -- 初始化状态（如果不存在）
    if not self.status_list[status_name] then
        self.status_list[status_name] = false
    end

    local old_status = self.status_list[status_name]
    self.status_list[status_name] = expression
    
    -- 只在状态从 false 变为 true 时返回 true
    return old_status == false and expression == true
end


-- 获取状态
-- @param status_name string 状态名称
-- @return boolean 
function _M:GetStatus(status_name)
    return self.status_list[status_name]
end

-- 设置状态
-- @param status_name string 状态名称
-- @param status boolean 状态
function _M:SetStatus(status_name,status)
    self.status_list[status_name] = status
end

-- 显示所有状态
-- @return string 所有状态
function _M:DisplayAllStatusDebug()
    local str = "\n"
    for status_name,status in pairs(self.status_list) do
        str = str .. status_name .. ": " .. tostring(status) .. "\n"
    end
    return str
end



return _M