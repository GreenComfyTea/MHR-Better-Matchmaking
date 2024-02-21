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

local session_manager = nil;

local quest_types = {
	invalid = {},

	regular = {
		quest_id = 0
	},

	random = {
		my_hunter_rank = 0
	},

	rampage = {
		difficulty = 0,
		quest_level = {
			value = 0,
			has_value = false
		},
		target_enemy = {
			value = 0,
			has_value = false
		}
	},
	
	random_master_rank = {
		my_hunter_rank = 0,
		my_master_rank = 0
	},

	random_anomaly = {
		my_hunter_rank = 0,
		my_master_rank = 0,
		anomaly_research_level = 0
	},

	anomaly_investigation = {
		min_level = 1,
		max_level = 1,
		party_limit = 4,
		enemy_id = {
			value = 0,
			has_value = false
		},
		reward_item = 67108864,
		is_special_random_mystery = false,
	}
};

local quest_type = quest_types.invalid;

local skip_next_hook = false;

local session_manager_type_def = sdk.find_type_definition("snow.SnowSessionManager");
local on_timeout_matchmaking_method = session_manager_type_def:get_method("funcOnTimeoutMatchmaking");

local req_matchmaking_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSession");
local req_matchmaking_random_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandom");
local req_matchmaking_hyakuryu_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionHyakuryu");
local req_matchmaking_random_master_rank_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMasterRank");
local req_matchmaking_random_mystery_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMystery");
local req_matchmaking_random_mystery_quest_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMysteryQuest");

local nullable_uint32_type_def = sdk.find_type_definition("System.Nullable`1<System.UInt32>");
local nullable_uint32_get_value_or_default_method = nullable_uint32_type_def:get_method("GetValueOrDefault");
local nullable_uint32_get_has_value_method = nullable_uint32_type_def:get_method("get_HasValue");
local nullable_uint32_constructor_method = nullable_uint32_type_def:get_method(".ctor(System.UInt32)");

local t0 = 0;

function this.get_search_time()
	return os.clock() - t0;
end

function this.on_post_timeout_matchmaking()
	local timeout_fix_config = config.current_config.timeout_fix;

	if not timeout_fix_config.enabled then
		return;
	end

	if session_manager == nil then
		session_manager = sdk.get_managed_singleton("snow.SnowSessionManager");

		if session_manager == nil then
			customization_menu.status = "[timeout_fix.on_post_timeout_matchmaking] No session_manager";
			return;
		end
	end

	if quest_type == quest_types.regular then
		if timeout_fix_config.quest_types.regular then
			skip_next_hook = true;
			req_matchmaking_method:call(session_manager, quest_type.quest_id);
		end

	elseif quest_type == quest_types.random then
		if timeout_fix_config.quest_types.random then
			skip_next_hook = true;
			req_matchmaking_random_method:call(session_manager, quest_type.my_hunter_rank);
		end

	elseif quest_type == quest_types.rampage then
		if timeout_fix_config.quest_types.rampage then
			local quest_level_pointer = ValueType.new(nullable_uint32_type_def);
			local target_enemy_pointer = ValueType.new(nullable_uint32_type_def);

			nullable_uint32_constructor_method:call(quest_level_pointer, quest_type.quest_level.value);
			nullable_uint32_constructor_method:call(target_enemy_pointer, quest_type.target_enemy.value);

			quest_level_pointer:set_field("_HasValue", quest_type.quest_level.has_value);
			target_enemy_pointer:set_field("_HasValue", quest_type.target_enemy.has_value);

			skip_next_hook = true;
			req_matchmaking_hyakuryu_method:call(session_manager, quest_type.difficulty, quest_level_pointer, target_enemy_pointer);
		end

	elseif quest_type == quest_types.random_master_rank then
		if timeout_fix_config.quest_types.random_master_rank then
			skip_next_hook = true;
			req_matchmaking_random_master_rank_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank);
		end

	elseif quest_type == quest_types.random_anomaly then
		if timeout_fix_config.quest_types.random_anomaly then
			skip_next_hook = true;
			req_matchmaking_random_mystery_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank, quest_type.anomaly_research_level);
		end
	elseif quest_type == quest_types.anomaly_investigation then
		if timeout_fix_config.quest_types.anomaly_investigation then
			
			local enemy_id_pointer = ValueType.new(nullable_uint32_type_def);
			nullable_uint32_constructor_method:call(enemy_id_pointer, quest_type.enemy_id.value);
			enemy_id_pointer:set_field("_HasValue", quest_type.enemy_id.has_value);
			
			skip_next_hook = true;
			req_matchmaking_random_mystery_quest_method:call(session_manager, quest_type.min_level, quest_type.max_level, quest_type.party_limit,
				enemy_id_pointer, quest_type.reward_item, quest_type.is_special_random_mystery);
		end
	end
end

function this.on_req_matchmaking(quest_id)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	
	if quest_id == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking] No quest_id";
		return;
	end

	quest_type = quest_types.regular;
	quest_type.quest_id = quest_id;
end

function this.on_req_matchmaking_random(my_hunter_rank)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	
	if my_hunter_rank == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking] No my_hunter_rank";
		return;
	end
	
	quest_type = quest_types.random;
	quest_type.my_hunter_rank = my_hunter_rank;
end

function this.on_req_matchmaking_rampage(difficulty, quest_level_pointer, target_enemy_pointer)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	
	if difficulty == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_rampage] No difficulty";
		return;
	end

	if quest_level_pointer == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_rampage] No quest_level_pointer";
		return;
	end

	if target_enemy_pointer == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_rampage] No target_enemy_pointer";
		return;
	end
	
	quest_type = quest_types.rampage;
	quest_type.difficulty = difficulty;

	local quest_level_pointer_int = sdk.to_int64(quest_level_pointer);
	local target_enemy_pointer_int = sdk.to_int64(target_enemy_pointer);

	quest_type.quest_level.has_value = nullable_uint32_get_has_value_method:call(quest_level_pointer_int);
	quest_type.target_enemy.has_value = nullable_uint32_get_has_value_method:call(target_enemy_pointer_int);

	if quest_type.quest_level.has_value then
		quest_type.quest_level.value = nullable_uint32_get_value_or_default_method(quest_level_pointer);
	end

	if quest_type.target_enemy.has_value then
		quest_type.target_enemy.value = nullable_uint32_get_value_or_default_method(target_enemy_pointer);
	end
end

function this.on_req_matchmaking_random_master_rank(my_hunter_rank, my_master_rank)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	
	if my_hunter_rank == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_master_rank] No my_hunter_rank";
		return;
	end

	if my_master_rank == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_master_rank] No my_master_rank";
		return;
	end
	
	quest_type = quest_types.random_master_rank;
	quest_type.my_hunter_rank = my_hunter_rank;
	quest_type.my_master_rank = my_master_rank;
end

function this.on_req_matchmaking_random_anomaly(my_hunter_rank, my_master_rank, anomaly_research_level)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end

	if my_hunter_rank == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly] No my_hunter_rank";
		return;
	end

	if my_master_rank == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly] No my_master_rank";
		return;
	end

	if anomaly_research_level == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly] No anomaly_research_level";
		return;
	end
	
	quest_type = quest_types.random_anomaly;
	quest_type.my_hunter_rank = my_hunter_rank;
	quest_type.my_master_rank = my_master_rank;
	quest_type.anomaly_research_level = anomaly_research_level;
end

function this.on_req_matchmaking_random_anomaly_quest(min_level, max_level, party_limit, enemy_id_pointer, reward_item, is_special_random_mystery)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end

	if min_level == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly_quest] No min_level";
		return;
	end

	if max_level == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly_quest] No max_level";
		return;
	end

	if party_limit == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly_quest] No party_limit";
		return;
	end

	if enemy_id_pointer == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly_quest] No enemy_id_pointer";
		return;
	end

	if reward_item == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly_quest] No reward_item";
		return;
	end

	if is_special_random_mystery == nil then
		customization_menu.status = "[timeout_fix.on_req_matchmaking_random_anomaly_quest] No is_special_random_mystery";
		return;
	end

	quest_type = quest_types.anomaly_investigation;
	quest_type.min_level = min_level;
	quest_type.max_level = max_level;
	quest_type.party_limit = party_limit;
	quest_type.reward_item = reward_item;
	quest_type.is_special_random_mystery = is_special_random_mystery;

	local enemy_id_pointer_int = sdk.to_int64(enemy_id_pointer);

	quest_type.enemy_id.has_value = nullable_uint32_get_has_value_method:call(enemy_id_pointer);

	if quest_type.enemy_id.has_value then
		quest_type.enemy_id.value = nullable_uint32_get_value_or_default_method(enemy_id_pointer);
	end
end

function this.on_req_online()
	if not config.current_config.hide_online_warning.enabled then
		return;
	end

	return sdk.PreHookResult.SKIP_ORIGINAL;
end

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");
	customization_menu = require("Better_Matchmaking.customization_menu");

	sdk.hook(on_timeout_matchmaking_method,
	function(args) end,
	function(retval)

		this.on_post_timeout_matchmaking();
		return retval;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSession(
	--	System.UInt32 						questID
	--)
	sdk.hook(req_matchmaking_method, function(args)
		
		local quest_id = sdk.to_int64(args[3]) & 0xFFFFFFFF;

		this.on_req_matchmaking(quest_id);

	end, function(retval)
		return retval;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandom(
	--	System.UInt32 						myHunterRank
	--)
	sdk.hook(req_matchmaking_random_method, function(args)
		
		local my_hunter_rank = sdk.to_int64(args[3]) & 0xFFFFFFFF;

		this.on_req_matchmaking_random(my_hunter_rank);

	end, function(retval)
		return retval;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionHyakuryu(
	--	System.UInt32 						difficulty
	--	System.Nullable`1<System.UInt32>	questLevel
	--	System.Nullable`1<System.UInt32>	targetEnemy
	--)
	sdk.hook(req_matchmaking_hyakuryu_method, function(args)
		
		local difficulty = sdk.to_int64(args[3]) & 0xFFFFFFFF;
		local quest_level = args[4];
		local target_enemy = args[5];

		this.on_req_matchmaking_rampage(difficulty, quest_level, target_enemy);

	end, function(retval)
		return retval;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMasterRank(
	--	System.UInt32 						myHunterRank
	--	System.UInt32						myMasterRank
	--)
	sdk.hook(req_matchmaking_random_master_rank_method, function(args)
		
		local my_hunter_rank = sdk.to_int64(args[3]) & 0xFFFFFFFF;
		local my_master_rank = sdk.to_int64(args[4]) & 0xFFFFFFFF;

		this.on_req_matchmaking_random_master_rank(my_hunter_rank, my_master_rank);

	end, function(retval)
		return retval;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMystery(
	--	System.UInt32 						myHunterRank
	--	System.UInt32						myMasterRank
	--	System.UInt32						myMasterRank (it is actually anomaly research level)
	--)
	sdk.hook(req_matchmaking_random_mystery_method, function(args)
	
		local my_hunter_rank = sdk.to_int64(args[3]) & 0xFFFFFFFF;
		local my_master_rank = sdk.to_int64(args[4]) & 0xFFFFFFFF;
		local anomaly_research_level = sdk.to_int64(args[5]) & 0xFFFFFFFF;

		this.on_req_matchmaking_random_anomaly(my_hunter_rank, my_master_rank, anomaly_research_level);

	end, function(retval)
		return retval;
	end);

	--snow.SnowSessionManager.
	--reqMatchmakingAutoJoinSessionRandomMysteryQuest(
	--	System.UInt32 						lvMin
	--	System.UInt32						lvMax
	--	System.UInt32						limit
	--	System.Nullable`1<System.UInt32>	enemyId
	--	snow.data.ContentsIdSystem.ItemId	rewardItem
	--	System.Boolean						isSpecialRandomMystery
	--)
	sdk.hook(req_matchmaking_random_mystery_quest_method, function(args)
		
		local lv_min = sdk.to_int64(args[3]) & 0xFFFFFFFF;
		local lv_max = sdk.to_int64(args[4]) & 0xFFFFFFFF;
		local limit = sdk.to_int64(args[5]) & 0xFFFFFFFF;
		local enemy_id = args[6];
		local reward_item = sdk.to_int64(args[7]) & 0xFFFFFFFF;
		local is_special_random_mystery = (sdk.to_int64(args[8]) & 1) == 1;

		this.on_req_matchmaking_random_anomaly_quest( lv_min, lv_max, limit, enemy_id, reward_item, is_special_random_mystery);
		
	end, function(retval)
		return retval;
	end);
end

return this;


