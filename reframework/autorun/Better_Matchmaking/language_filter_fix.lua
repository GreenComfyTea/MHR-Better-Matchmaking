local this = {};

local utils;
local config;
local customization_menu;

local sdk = sdk;
local tostring = tostring;
local pairs = pairs;
local ipairs = ipairs;
local tonumber = tonumber;
local require = require;
local pcall = pcall;
local table = table;
local string = string;
local Vector3f = Vector3f;
local d2d = d2d;
local math = math;
local json = json;
local log = log;
local fs = fs;
local next = next;
local type = type;
local setmetatable = setmetatable;
local getmetatable = getmetatable;
local assert = assert;
local select = select;
local coroutine = coroutine;
local utf8 = utf8;
local re = re;
local imgui = imgui;
local draw = draw;
local Vector2f = Vector2f;
local reframework = reframework;
local os = os;
local ValueType = ValueType;
local package = package;

local session_manager_type_def = sdk.find_type_definition("snow.SnowSessionManager");
local is_lobby_search_result_condition_check_2_method = session_manager_type_def:get_method(
	"isLobbySearchResultConditionCheck(via.network.session.SearchResult, System.Int32, System.Int32, System.Boolean)");

local one_session_manager_type_def = sdk.find_type_definition("snow.network.session.OneSessionManager");
local on_ans_session_search_succeed_method = one_session_manager_type_def:get_method("OnAnsSessionSearchSucceed");

local search_filter_type_def = sdk.find_type_definition("via.network.session.SearchFilter");
local push_back_u32_filter_method = search_filter_type_def:get_method("pushBackU32Filter");

local search_result_type_def = sdk.find_type_definition("via.network.session.SearchResult");
local get_session_info_method = search_result_type_def:get_method("get_SessionInfo");

local session_info_type_def = get_session_info_method:get_return_type();
local get_search_key_method = session_info_type_def:get_method("get_SearchKey");

local search_key_type_def = get_search_key_method:get_return_type();
local set_u32_key_method = search_key_type_def:get_method("setU32Key");

local language_id_shift = 965861184;

-- Hunter Connect ID = AAAA AAAA - BBBB - CCCC - DDEE - FFGG HHII JJKK

local key_names = {
	[1] = "Target Type",
	[2] = "Quest Type",
	[3] = "Host Hunter Rank",
	[4] = "Lobby Min Hunter Rank",
	[5] = "Lobby Max Hunter Rank",
	[6] = "Language",
	[7] = "Hunter Connect ID AAAA AAAA",
	[8] = "Hunter Connect ID CCCC BBBB",
	[9] = "Hunter Connect ID GGFF EEDD",
	[10] = "Hunter Connect ID KKJJ IIHH",
	[11] = "Host Master Rank",
	[12] = "Lobby Min Hunter Rank",
	[13] = "Lobby Max Hunter Rank",
	[14] = "Hunter Connect ?"
};

local comparison_signs = {
	[1] = "==",
	[2] = "!=",
	[3] = ">",
	[4] = ">=",
	[5] = "<",
	[6] = "<="
};

local value_names = {
	[4] = " (My Hunter Rank)",
	[5] = " (My Hunter Rank)",
	[12] = " (My Master Rank)",
	[13] = " (My Master Rank)",
};

-- Any Language:

-- Japanese =============== 63	---->	965861247
-- English ================ 63	---->	965861247
-- French ================= 63	---->	965861247
-- German ================= 63	---->	965861247
-- Italian ================ 63	---->	965861247
-- Spanish ================ 63	---->	965861247
-- Russian ================ 63	---->	965861247
-- Polish ================= 63	---->	965861247
-- Brazil Portuguese ====== 63	---->	965861247
-- Korean ================= 63	---->	965861247
-- Chinese Traditional ==== 63	---->	965861247
-- Chinese Simplified ===== 63	---->	965861247
-- Arabic ================= 63	---->	965861247
-- Latin Americal Spanish = 63?	---->	965861247

-- Same Language:

-- Japanese =============== 0	---->	965861184
-- English ================ 1	---->	965861185
-- French ================= 2	---->	965861186
-- German ================= 4	---->	965861188
-- Italian ================ 3	---->	965861187
-- Spanish ================ 5	---->	965861189
-- Russian ================ 6	---->	965861190
-- Polish ================= 7	---->	965861191
-- Brazil Portuguese ====== 10	---->	965861194
-- Korean ================= 11	---->	965861195
-- Chinese Traditional ==== 12	---->	965861196
-- Chinese Simplified ===== 13	---->	965861197
-- Arabic ================= 21	---->	965861205
-- Latin Americal Spanish = ?	---->	?

this.is_any_language_lobby_search_in_progress = false;

function this.get_key_name(key)
	local key_name = key_names[key];
	if key_name == nil then
		key_name = "Key " .. tostring(key);
	end

	return key_name;
end

function this.get_comparison_sign(value)
	return comparison_signs[value];
end

function this.get_value_name(value)
	local value_name = value_names[value];
	if value_name == nil then
		value_name = "";
	end
	return value_name;
end

function this.get_language_actual_id(shifted_id)
	return shifted_id - language_id_shift;
end

function this.get_language_shifted_id(actual_id)
	return actual_id + language_id_shift;
end

function this.on_push_back_u32_filter(key, comparison, value)
	if not config.current_config.language_filter_fix.enabled then
		return sdk.PreHookResult.CALL_ORIGINAL;
	end

	if key == nil then
		customization_menu.status = "[language_filter_fix.on_push_back_u32_filter] No key";
		return sdk.PreHookResult.CALL_ORIGINAL;
	end

	if comparison == nil then
		customization_menu.status = "[language_filter_fix.on_push_back_u32_filter] No comparison";
		return sdk.PreHookResult.CALL_ORIGINAL;
	end

	if value == nil then
		customization_menu.status = "[language_filter_fix.on_push_back_u32_filter] No value";
		return sdk.PreHookResult.CALL_ORIGINAL;
	end
	
	-- if key ~= language
	if key ~= 6 then
		return sdk.PreHookResult.CALL_ORIGINAL;
	end

	local language_id = this.get_language_actual_id(value);

	-- if language_id == Any Language
	if language_id == 63 then
		this.is_any_language_lobby_search_in_progress = true;
		return sdk.PreHookResult.SKIP_ORIGINAL;
	end

	return sdk.PreHookResult.CALL_ORIGINAL;
end

function this.on_is_lobby_search_result_condition_check_2(search_result)
	if not config.current_config.language_filter_fix.enabled then
		return;
	end

	if not this.is_any_language_lobby_search_in_progress then
		return;
	end

	if search_result == nil then
		customization_menu.status = "[language_filter_fix.on_is_lobby_search_result_condition_check_2] No search_result";
		return;
	end

	local session_info = get_session_info_method:call(search_result);

	if session_info == nil then
		customization_menu.status = "[language_filter_fix.on_is_lobby_search_result_condition_check_2] No session_info";
		return;
	end
	
	local search_key = get_search_key_method:call(session_info);

	if search_key == nil then
		customization_menu.status = "[language_filter_fix.on_is_lobby_search_result_condition_check_2] No search_key";
		return;
	end

	if not config.current_config.language_filter_fix.lobby_language_filter_bypass.enabled then
		return;
	end

	log.debug("\nBYPASSING\n");

	-- Set Language = Any Language
	set_u32_key_method:call(search_key, 6, this.get_language_shifted_id(63));
end

function this.on_ans_session_search_succeed()
	this.is_any_language_lobby_search_in_progress = false;

	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
	log.debug("\nDONE\n");
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");
	customization_menu = require("Better_Matchmaking.customization_menu");

	sdk.hook(push_back_u32_filter_method, function(args)
		
		local key = sdk.to_int64(args[2]);
		local comparison = sdk.to_int64(args[3]);
		local value = sdk.to_int64(args[4]) & 0xFFFFFFFF;

		return this.on_push_back_u32_filter(key, comparison, value);
		
	end, function(retval)
		return retval;
	end);
	
	sdk.hook(is_lobby_search_result_condition_check_2_method, function(args)
	
		local search_result = sdk.to_managed_object(args[2]);
		this.on_is_lobby_search_result_condition_check_2(search_result);

	end, function(retval)
		return retval;
	end);

	sdk.hook(on_ans_session_search_succeed_method, function(args)
		this.on_ans_session_search_succeed();

	end, function(retval)
		return retval;
	end);

	
end

return this;
