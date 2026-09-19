local function pre_nuke(args)
	return sdk.PreHookResult.SKIP_ORIGINAL
end

local function post_nuke(retval)
	return retval
end

sdk.hook(sdk.find_type_definition("app.cSaveDataHelper_QuestParam"):get_method("decreaseRemainingNum"), pre_nuke, post_nuke)
sdk.hook(sdk.find_type_definition("app.cSaveDataHelper_QuestParam"):get_method("increaseRemainingNum"), pre_nuke, post_nuke)

--[[ 
Start
#703BE60
Write
#703BF0A
Sig 88 88 88000000



MonsterHunterWilds.exe+703BEF9 - 48 85 C0              - test rax,rax
MonsterHunterWilds.exe+703BEFC - 74 12                 - je MonsterHunterWilds.exe+703BF10
MonsterHunterWilds.exe+703BEFE - 8A 88 88000000        - mov cl,[rax+00000088]
MonsterHunterWilds.exe+703BF04 - 84 C9                 - test cl,cl
MonsterHunterWilds.exe+703BF06 - 7E 08                 - jle MonsterHunterWilds.exe+703BF10
MonsterHunterWilds.exe+703BF08 - FE C9                 - dec cl
MonsterHunterWilds.exe+703BF0A - 88 88 88000000        - mov [rax+00000088],cl
MonsterHunterWilds.exe+703BF10 - 80 7C 24 2F 00        - cmp byte ptr [rsp+2F],00 { 0 }
MonsterHunterWilds.exe+703BF15 - 74 0B                 - je MonsterHunterWilds.exe+703BF22
MonsterHunterWilds.exe+703BF17 - 48 89 F1              - mov rcx,rsi
MonsterHunterWilds.exe+703BF1A - 48 89 FA              - mov rdx,rdi
]]