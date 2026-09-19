-- quest_stealer.lua : written by archwizard1204
-- Only on NexusMods, my profile page : https://next.nexusmods.com/profile/archwizard1204?8964
-- version : 1.21

local CONFIG_PATH = "quest_stealer.json"

local config = {
    enable = true,
}

local QuestUtil                 = sdk.find_type_definition("app.QuestUtil")
local getLocalTime              = QuestUtil:get_method("getLocalTime")
local saveInstantQuest          = QuestUtil:get_method("saveInstantQuest(app.cKeepQuestData)")
local delInstantQuestHistory    = QuestUtil:get_method("deleteInstantQuestHistory(System.Int32)")
local getInstantQuestHistory    = QuestUtil:get_method("getInstantQuestHistoryOldest_ActiveQuestData")

local KEEPQUEST                 = 4
local INSTANTQUEST              = 5
local UNSAVED_INSTANTQUEST_ID   = 392

local deleteHistory             = false
local isSteal                   = false

local function saveConfig()
	json.dump_file(CONFIG_PATH, config)
end

local function loadConfig()
	local loadedConfig = json.load_file(CONFIG_PATH);
	if loadedConfig then
		config = loadedConfig;
    end
end

loadConfig()

local function getOldestInstantHistoryIndex()
    local InstantQuestHistory = getInstantQuestHistory(nil)

    if InstantQuestHistory and #InstantQuestHistory > 0 then
        if #InstantQuestHistory == 16 then
            local oldestQuest = InstantQuestHistory[#InstantQuestHistory - 1]
            if oldestQuest then
                return oldestQuest:call("get_Index")
            end
        else
            return #InstantQuestHistory
        end
    end

    return 0
end

local function isQuestHistoryDuplicate(KeepQuestData)
    local InstantQuestHistory = getInstantQuestHistory(nil)

    local UniqueIndex = KeepQuestData:call("get_ExSpawnUniqueIndex")

    if InstantQuestHistory and #InstantQuestHistory > 0 then
        for i = 0, #InstantQuestHistory - 1 do
            local Item = InstantQuestHistory[i]
            if Item then
                local cKeepQuestData = Item:call("get_KeepQuestData")
                if cKeepQuestData then
                    if UniqueIndex == cKeepQuestData:call("get_ExSpawnUniqueIndex") then
                        return true
                    end
                end
            end
        end
    end

    return false
end

local function getQuestData(args)
    if not config.enable or not isSteal then
        return sdk.PreHookResult.CALL_ORIGINAL
    end

    isSteal = false

    local self = sdk.to_managed_object(args[2])

    local missionType = self:call("getActiveMissionType")
    if missionType ~= KEEPQUEST and missionType ~= INSTANTQUEST then
        return sdk.PreHookResult.CALL_ORIGINAL
    end

    local ActiveQuestData = self:call("get_QuestData")
    if not ActiveQuestData or ActiveQuestData:call("get_Index") ~= -1 then
        return sdk.PreHookResult.CALL_ORIGINAL
    end

    local KeepQuestData = ActiveQuestData:call("get_KeepQuestData")

    -- if not KeepQuestData or isQuestHistoryDuplicate(KeepQuestData) then
    if not KeepQuestData then
        return sdk.PreHookResult.CALL_ORIGINAL
    end

    if KeepQuestData:call("getAcceptableHR()") < 9 then
        return sdk.PreHookResult.CALL_ORIGINAL
    end

    KeepQuestData._MissionId    = UNSAVED_INSTANTQUEST_ID
    KeepQuestData._CreatedDate  = getLocalTime(nil)
    KeepQuestData._Index        = getOldestInstantHistoryIndex()

    saveInstantQuest(nil, KeepQuestData)

    return sdk.PreHookResult.CALL_ORIGINAL
end

local function enableSteal(retval)
    isSteal = true
    return retval
end

local function deleteAllInstantQuestHistroy()
    for i = 0, 15 do
        delInstantQuestHistory(nil, i)
    end
end

re.on_draw_ui(function()
    if imgui.tree_node("Quest Stealer") then
        changed, config.enable = imgui.checkbox("Enable", config.enable);
        if imgui.button("Delete All Field Survey History") then
            deleteHistory = true
        end

        if deleteHistory then
            imgui.text("You Sure?")
            if imgui.button("Yes") then
                deleteAllInstantQuestHistroy()
                deleteHistory = false
            end
            imgui.same_line()
            if imgui.button("No") then
                deleteHistory = false
            end
        end
        if changed then
            saveConfig()
        end
		imgui.tree_pop()
    end
end)

re.on_config_save(function()
	saveConfig()
end)

sdk.hook(sdk.find_type_definition("app.cQuestDirector"):get_method("requestOpenGUI020201"), getQuestData, nil)
sdk.hook(sdk.find_type_definition("app.cQuestDirector"):get_method("goQuest(System.Boolean, System.Boolean, System.Boolean, System.Boolean)"), nil, enableSteal)