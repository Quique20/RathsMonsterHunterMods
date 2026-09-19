-- FriendChecker类
local FriendChecker = {}
FriendChecker.__index = FriendChecker

local SESSION_TYPE = {
    LOBBY = 1,
    QUEST = 2,
    LINK = 3,
}

-- 创建一个新的FriendChecker实例
function FriendChecker.new()
    local self = setmetatable({}, FriendChecker)
    self.Network_Manager = sdk.get_managed_singleton("app.NetworkManager")
    self.friendCache = {}
    self:updateFriendList()
    return self
end

-- 更新好友列表
function FriendChecker:updateFriendList()
    if not self.Network_Manager then
        self.Network_Manager = sdk.get_managed_singleton("app.NetworkManager")
    end
    local FriendManager = self.Network_Manager:get_FriendManager()
    local FriendList = FriendManager:get_FriendList()
    
    -- 清空缓存
    self.friendCache = {}
    
    -- 更新缓存
    for i = 0, #FriendList - 2 do
        local FriendInfo = FriendList[i]
        if FriendInfo then
            local ShortHunterID = FriendInfo:get_RawShortId()
            if ShortHunterID then
                self.friendCache[ShortHunterID] = true
            end
        end
    end
end

-- 判断是否所有成员都是好友或PartyMember或自己
function FriendChecker:isAllFriends(strict)
    if not self.Network_Manager then
        self.Network_Manager = sdk.get_managed_singleton("app.NetworkManager")
    end
    -- 获取UserInfoManager
    local UserInfoManager = self.Network_Manager:get_UserInfoManager()
    
    -- 检查是否是自己主持的任务
    local isSelfHosted = false
    local HostUserInfo = UserInfoManager:getHostUserInfo(SESSION_TYPE.QUEST)
    
    if not HostUserInfo then
        -- 不在任务中
        return true
    end
    
    if HostUserInfo:get_IsSelf() then
        isSelfHosted = true
        -- 如果不是严格模式且是自己主持的任务，直接返回true
        if not strict then
            return true
        end
    end
    
    -- 获取任务中的成员数量
    local MemberNum = UserInfoManager:getMemberNum(SESSION_TYPE.QUEST)
    
    -- 如果没有成员，返回true（只有自己）
    if MemberNum <= 1 then
        return true
    end
    
    -- 获取成员列表
    local UserInfoList = UserInfoManager:getUserInfoList(SESSION_TYPE.QUEST)
    local UserInfoArray = UserInfoList._ListInfo
    
    -- 检查每个成员
    for i = 0, MemberNum - 1 do
        local UserInfo = UserInfoArray[i]
        local ShortHunterID = UserInfo:get_ShortHunterId()
        local isPartyMember = UserInfo:get_IsPartyMember()
        local isSelf = UserInfo:get_IsSelf()
        local isFriend = self.friendCache[ShortHunterID] or false
        
        -- 如果不是自己、不是PartyMember、也不是好友，返回false
        if not (isSelf or isPartyMember or isFriend) then
            return false
        end
    end
    
    -- 所有成员都是好友或PartyMember或自己
    return true
end

-- 导出FriendChecker类
return FriendChecker 