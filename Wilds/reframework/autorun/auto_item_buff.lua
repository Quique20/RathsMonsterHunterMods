-- auto_item_buff.lua : written by archwizard1204
-- Only on NexusMods, my profile page : https://next.nexusmods.com/profile/archwizard1204?8964
-- version : 1.3

local CONFIG_PATH = "auto_item_buff.json"

local config = {
    cold_drink  = true,
    hot_drink   = true,
    free_meal   = false,
    prolonger   = true,
    consume     = true,
    enable      = true,
    time        = 5,
    item        = {
        ["125"] = true,   -- 鬼人の種
        ["175"] = false,  -- 鬼人の粉塵
        ["167"] = false,  -- 鬼人薬
        ["168"] = false,  -- 怪力の丸薬
        ["169"] = false,  -- 鬼人薬グレート

        ["126"] = false,  -- 忍耐の種
        ["170"] = false,  -- 硬化薬
        ["171"] = false,  -- 忍耐の丸薬
        ["172"] = false,  -- 硬化薬グレート
        ["176"] = false,  -- 硬化の粉塵

        ["163"] = false,  -- 強走薬
        ["164"] = false,  -- 活力剤

        ["112"] = false,  -- 毒テングダケ
        ["113"] = false,  -- マヒダケ
        ["127"] = false,  -- ニトロダケ
        ["128"] = false,  -- 鬼ニトロダケ
    }
}

local ITEM = {
    ["125"] = { -- 鬼人の種
        id      = 125,
        timer   = "get_Kairiki_Timer",
        buff    = 1,
    },
    ["167"] = { -- 鬼人薬
        id      = 167,
        timer   = "get_KijinDrink_Timer",
        buff    = 4,
    },
    ["168"] = { -- 怪力の丸薬
        id      = 168,
        timer   = "get_Kairiki_G_Timer",
        buff    = 2,
    },
    ["169"] = { -- 鬼人薬グレート
        id      = 169,
        timer   = "get_KijinDrink_G_Timer",
        buff    = 5,
    },
    ["175"] = { -- 鬼人の粉塵
        id      = 175,
        timer   = "get_KijinPowder_Timer",
        buff    = 6,
    },
    ["126"] = { -- 忍耐の種
        id      = 126,
        timer   = "get_Nintai_Timer",
        buff    = 7,
    },
    ["170"] = { -- 硬化薬
        id      = 170,
        timer   = "get_KoukaDrink_Timer",
        buff    = 10,
    },
    ["171"] = { -- 忍耐の丸薬
        id      = 171,
        timer   = "get_Nintai_G_Timer",
        buff    = 8,
    },
    ["172"] = { -- 硬化薬グレート
        id      = 172,
        timer   = "get_KoukaDrink_G_Timer",
        buff    = 11,
    },
    ["176"] = { -- 硬化の粉塵
        id      = 176,
        timer   = "get_KoukaPowder_Timer",
        buff    = 12,
    },
    ["163"] = { -- 強走薬
        id      = 163,
        timer   = "get_DashJuice_Timer",
        buff    = 13,
    },
    ["164"] = { -- 活力剤
        id      = 164,
        timer   = "get_Immunizer_Timer",
        buff    = 14,
    },
    ["165"] = { -- クーラードリンク
        id      = 165,
        timer   = "get_CoolerDrink_Timer",
        buff    = 18,
    },
    ["166"] = { -- ホットドリング
        id      = 166,
        timer   = "get_HotDrink_Timer",
        buff    = 17,
    },
    ["112"] = { -- 毒テングダケ
        id      = 112,
        timer   = "get_Immunizer_Timer",
        buff    = 14,
    },
    ["113"] = { -- マヒダケ
        id      = 113,
        timer   = "get_KoukaDrink_Timer",
        buff    = 10,
    },
    ["127"] = { -- ニトロダケ
        id      = 127,
        timer   = "get_KijinDrink_Timer",
        buff    = 4,
    },
    ["128"] = { -- 鬼ニトロダケ
        id      = 128,
        timer   = "get_DashJuice_Timer",
        buff    = 13,
    },
}

local COLD_REQUIRED_STAGE = {
    [2]  = true, -- 油湧き谷
    [13] = true, -- 遺忘の械墟
}

local HOT_REQUIRED_STAGE = {
    [3]  = true, -- 氷霧の断崖
    [10] = true, -- 氷鎖の凍峰
}

local BOX_STOCK_TYPE    = 1

local PlayerManager     = nil
local PlayerManageInfo  = nil
local PlayerCatalog     = nil
local PlayerItemParam   = nil
local HunterCharacter   = nil
local HunterStatus      = nil
local HunterItemBuff    = nil
local HunterExtendBase  = nil
local isInitialized     = false
local isLocaleLoaded    = false

local getItemName       = sdk.find_type_definition("app.ItemDef"):get_method("NameString(app.ItemDef.ID)")
local changeItemNum     = sdk.find_type_definition("app.ItemUtil"):get_method("changeItemNum(app.ItemDef.ID, System.Int16, app.ItemUtil.STOCK_TYPE)")
local activateItemBuff  = sdk.find_type_definition("app.cHunterItemBuff"):get_method("activateItemBuff(app.HunterDef.ITEM_BUFF_TYPE, System.Single, System.Single)")

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

local function init()
    PlayerManager     = sdk.get_managed_singleton("app.PlayerManager")
    if not PlayerManager    then return end

    PlayerManageInfo  = PlayerManager:call("getMasterPlayer")
    if not PlayerManageInfo then return end

    PlayerCatalog  = PlayerManager:call("get_Catalog")
    if not PlayerCatalog then return end

    PlayerItemParam  = PlayerCatalog:call("get_PlayerItemParam")
    if not PlayerItemParam then return end

    HunterCharacter   = PlayerManageInfo:call("get_Character")
    if not HunterCharacter  then return end

    HunterStatus      = HunterCharacter:call("get_HunterStatus")
    if not HunterStatus     then return end

    HunterItemBuff    = HunterStatus:call("get_ItemBuff")
    if not HunterItemBuff   then return end

    HunterExtendBase  = HunterCharacter:call("get_CharacterExtend")
    if not HunterExtendBase then return end

    isInitialized = true
end

local function initLocale()
    for ID, ItemName in pairs(ITEM) do
        ITEM[ID].locale = getItemName(nil, tonumber(ID))
    end

    isLocaleLoaded = true
end

local function applyItemBuff(itemId)
    if (HunterItemBuff:call(ITEM[itemId].timer) > (config.time * 60.0)) then
        return
    end

    if config.consume then
        local useItem = true
        if config.free_meal and math.random(0, 100) <= 45 then
            useItem = false
        end
        if useItem and changeItemNum(nil, tonumber(itemId), -1, BOX_STOCK_TYPE) < 0 then
            return
        end
    end

    local durationMultiplier = 1.0

    if config.prolonger then
        durationMultiplier = 1.5
    end

    activateItemBuff(HunterItemBuff, ITEM[itemId].buff, 1.0, durationMultiplier)
end

local function useEnabledItem()
    if not config.enable then
        return
    end

    if not isInitialized then
        init()
    end

    for ID, enable in pairs(config.item) do
        if not enable then
            goto continue
        end

        applyItemBuff(ID)

        ::continue::
    end
end

local function getFieldStage(args)
    if not config.enable then
        return sdk.PreHookResult.CALL_ORIGINAL
    end

    if not isInitialized then
        init()
    end

    local cActiveQuestData = sdk.to_managed_object(args[3])

    if cActiveQuestData:call("isArenaQuest") then
        return sdk.PreHookResult.CALL_ORIGINAL
    end

    local stage = cActiveQuestData:getStage()

    if COLD_REQUIRED_STAGE[stage] and config.cold_drink then
        applyItemBuff("165")
    elseif HOT_REQUIRED_STAGE[stage] and config.hot_drink then
        applyItemBuff("166")
    end

    useEnabledItem()

    if config.item["128"] or config.item["163"] then
        local HunterStamina = HunterStatus:call("get_Stamina")
        if HunterStamina then
            HunterStamina:call("setStaminaMax(System.Single)", 150.0)
            HunterStamina:call("setStamina(System.Single)", 150.0)
        end
    end

    return sdk.PreHookResult.CALL_ORIGINAL
end

re.on_draw_ui(function()
    if imgui.tree_node("Auto Item Buff") then
        if not isLocaleLoaded then
            initLocale()
        end

        changed,    config.enable      = imgui.checkbox("Enable", config.enable);
        changed,    config.consume     = imgui.checkbox("Consume Item", config.consume);
        changed,    config.free_meal   = imgui.checkbox("Apply Free Meal Lv.3 (45% chance of not consuming item)", config.free_meal);
        changed,    config.prolonger   = imgui.checkbox("Apply Item Prolonger Lv.3 (Buff duration x 1.5)", config.prolonger);
        imgui.text("Rebuff when buff time less than ")
        imgui.push_item_width(150)
        changed,    config.time        = imgui.slider_int("Minutes", config.time, 0, 45);
        imgui.pop_item_width()

        imgui.new_line()
        imgui.text("Auto use item:")
        changed,    config.item["125"] = imgui.checkbox(ITEM["125"].locale, config.item["125"]);
        changed,    config.item["168"] = imgui.checkbox(ITEM["168"].locale, config.item["168"]);

        changed,    config.item["175"] = imgui.checkbox(ITEM["175"].locale, config.item["175"]);

        changedB,   config.item["167"] = imgui.checkbox(ITEM["167"].locale, config.item["167"]);
        if changedB then
            config.item["169"] = false
            config.item["127"] = false
        end
        imgui.same_line()
        changedB,   config.item["127"] = imgui.checkbox(ITEM["127"].locale, config.item["127"]);
        if changedB then
            config.item["169"] = false
            config.item["167"] = false
        end
        imgui.same_line()
        changedB,   config.item["169"] = imgui.checkbox(ITEM["169"].locale, config.item["169"]);
        if changedB then
            config.item["167"] = false
            config.item["127"] = false
        end

        changed,    config.item["126"] = imgui.checkbox(ITEM["126"].locale, config.item["126"]);
        changed,    config.item["171"] = imgui.checkbox(ITEM["171"].locale, config.item["171"]);

        changed,    config.item["176"] = imgui.checkbox(ITEM["176"].locale, config.item["176"]);

        changedD,   config.item["170"] = imgui.checkbox(ITEM["170"].locale, config.item["170"]);
        if changedD then
            config.item["113"] = false
            config.item["172"] = false
        end
        imgui.same_line()
        changedD,   config.item["113"] = imgui.checkbox(ITEM["113"].locale, config.item["113"]);
        if changedD then
            config.item["170"] = false
            config.item["172"] = false
        end
        imgui.same_line()
        changedD,   config.item["172"] = imgui.checkbox(ITEM["172"].locale, config.item["172"]);
        if changedD then
            config.item["170"] = false
            config.item["113"] = false
        end

        changedE,   config.item["163"] = imgui.checkbox(ITEM["163"].locale, config.item["163"]);
        if changedE then config.item["128"] = false end
        imgui.same_line()
        changedE,   config.item["128"] = imgui.checkbox(ITEM["128"].locale, config.item["128"]);
        if changedE then config.item["163"] = false end

        changedF,   config.item["164"] = imgui.checkbox(ITEM["164"].locale, config.item["164"]);
        if changedF then config.item["112"] = false end
        imgui.same_line()
        changedF,   config.item["112"] = imgui.checkbox(ITEM["112"].locale, config.item["112"]);
        if changedF then config.item["164"] = false end

        changed,    config.cold_drink  = imgui.checkbox(ITEM["165"].locale, config.cold_drink);
        changed,    config.hot_drink   = imgui.checkbox(ITEM["166"].locale, config.hot_drink);

        if changed or changedB or changedD or changedE or changedF then
            saveConfig()
        end

		imgui.tree_pop()
    end
end)

re.on_config_save(function()
	saveConfig()
end)

sdk.hook(sdk.find_type_definition("app.cQuestDirector"):get_method("acceptQuest(app.cActiveQuestData, app.cQuestAcceptArg, System.Boolean, System.Boolean)"), getFieldStage, nil)