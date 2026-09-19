log.info("[VIP Dango Ticket] started loading")

local config = {
		InfiniteDangoTickets = false,
		TicketByDefault = false,
		ShowAllDango = false,
		skewerLvs = {4, 3, 1}
	}

local VIPDT_debugLogs = false;

local configPath = "VIP_Dango_Ticket_Config.json"

local function fixOldConfig()
	if config.skewerLvs == nil then
		config.skewerLvs = {4, 3, 1}
		json.dump_file(configPath, config)
	end
end

if json ~= nil then
    local file = json.load_file(configPath)
    if file ~= nil then
		config = file
		fixOldConfig()
		for i, n in pairs(config.skewerLvs) do
			config.skewerLvs[i] = tonumber(string.format("%d", n))
		end
    else
        json.dump_file(configPath, config)
    end
end

function VIPDT_logDebug(argStr)
	local debugString = "[VIP Dango Ticket] "..argStr;
	if VIPDT_debugLogs then
		log.info(debugString);
	end
end

local DangoListType = sdk.find_type_definition("System.Collections.Generic.List`1<snow.data.DangoData>")

local SavedDangoChance = 100;
local SavedDango = nil;
local DangoTicketState = false;

sdk.hook(sdk.find_type_definition("snow.data.DangoData"):get_method("get_SkillActiveRate"),--force 100% activation
function(args)
	local FacilityManager = sdk.get_managed_singleton("snow.data.FacilityDataManager");
	local KitchenMealFunc = FacilityManager:get_field("_Kitchen"):get_field("_MealFunc");

	DangoTicketState = KitchenMealFunc:call("getMealTicketFlag");
	if DangoTicketState then
		SavedDango = sdk.to_managed_object(args[2]);
		SavedDangoChance = SavedDango:get_field("_Param"):get_field("_SkillActiveRate")
		SavedDango:get_field("_Param"):set_field("_SkillActiveRate", 100);
	end
end,
function(retval)
	if DangoTicketState then
		SavedDango:get_field("_Param"):set_field("_SkillActiveRate", SavedDangoChance);
	end
	return retval;
end
);

sdk.hook(sdk.find_type_definition("snow.gui.fsm.kitchen.GuiKitchen"):get_method("setDangoDetailWindow"),--inform Gui of Dango Lv changes
function(args)
	local thisGui = sdk.to_managed_object(args[2])
	local SkewerLvList = thisGui:get_field("SpecialSkewerDangoLv")
	for i=0,2 do
		local newSkewerLv = sdk.create_instance("System.UInt32")
		newSkewerLv:set_field("mValue", config.skewerLvs[i+1])
		SkewerLvList[i] = newSkewerLv
	end
end,
function(retval)

	return retval;
end
);

sdk.hook(sdk.find_type_definition("snow.facility.kitchen.MealFunc"):get_method("updateList"),--inform Dango order constructor of Dango Lv changes
function(args)
	local FacilityManager = sdk.get_managed_singleton("snow.data.FacilityDataManager");
	local KitchenMealFunc = FacilityManager:get_field("_Kitchen"):get_field("_MealFunc");
	if config.TicketByDefault then
		KitchenMealFunc:call("setMealTicketFlag", true)
	end
	local SkewerLvList = KitchenMealFunc:get_field("SpecialSkewerDangoLv")
	for i=0,2 do
		local newSkewerLv = sdk.create_instance("System.UInt32")
		newSkewerLv:set_field("mValue", config.skewerLvs[i+1])
		SkewerLvList[i] = newSkewerLv
	end
end,
function(retval)
	if config.ShowAllDango then
		local FacilityManager = sdk.get_managed_singleton("snow.data.FacilityDataManager")
		local KitchenMealFunc = FacilityManager:get_field("_Kitchen"):get_field("_MealFunc")
		local DangoData = KitchenMealFunc:get_field("<DangoDataList>k__BackingField"):call("ToArray")
		local FlagManager = sdk.get_managed_singleton("snow.data.FlagDataManager");
		for i, dango in ipairs(DangoData) do
			local isDangoUnlock = FlagManager:call("isUnlocked(snow.data.DataDef.DangoId)", dango:get_field("_Param"):get_field("_Id"))
			if isDangoUnlock then
				dango:get_field("_Param"):set_field("_DailyRate", 0)
			end
		end
	end
	return retval;
end
);

sdk.hook(sdk.find_type_definition("snow.facility.kitchen.MealFunc"):get_method("order"),
function(args)

end,
function(retval)
	if config.InfiniteDangoTickets then
		local DataManager = sdk.get_managed_singleton("snow.data.DataManager");
		local ItemBox = DataManager:get_field("_PlItemBox")
		ItemBox:call("tryAddGameItem(snow.data.ContentsIdSystem.ItemId, System.Int32)", 68157564, 1)
	end
	return retval;
end
);

local function intSlider(label, index1, index2, min, max)
	local changed, value = imgui.slider_int(label, config[index1][index2], min, max)
	if changed then
		config[index1][index2] = value
		json.dump_file(configPath, config)
	end
end

re.on_draw_ui(function()
	if imgui.button("[VIP Dango Ticket]") then
		drawDangoTicketOptionsWindow = true
	end
	
    if drawDangoTicketOptionsWindow then
        if imgui.begin_window("[VIP Dango Ticket] Options", true, 64) then
			local doWrite = false
			changed, value = imgui.checkbox('Get Dango Ticket back after use##VIPDango', config.InfiniteDangoTickets)
			if changed then
				doWrite = true
				config.InfiniteDangoTickets = value
			end
			changed, value = imgui.checkbox('Use Dango Ticket as default choice##VIPDango', config.TicketByDefault)
			if changed then
				doWrite = true
				config.TicketByDefault = value
			end
			changed, value = imgui.checkbox('Show all available Dango (including Daily Dango)##VIPDango', config.ShowAllDango)
			if changed then
				doWrite = true
				config.ShowAllDango = value
			end
			imgui.text("Note: To toggle OFF requires game restart after.")
			if imgui.tree_node("Configure Hopping Skewer Dango Levels") then
				intSlider("Top Dango##VIPDango", "skewerLvs", 1, 1, 4)
				intSlider("Mid Dango##VIPDango", "skewerLvs", 2, 1, 4)
				intSlider("Bot Dango##VIPDango", "skewerLvs", 3, 1, 4)
				if imgui.button("Reset to Defaults##VIPDango") then
					config.skewerLvs = {4, 3, 1}
				end
				imgui.tree_pop()
			end
			if doWrite then
				json.dump_file(configPath, config)
			end
			imgui.end_window()
        else
            drawDangoTicketOptionsWindow = false
        end
    end
end)

log.info("[VIP Dango Ticket] finished loading")