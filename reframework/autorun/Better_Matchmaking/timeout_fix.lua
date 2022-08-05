local timeout_fix = {};
local table_helpers;
local config;

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
		my_master_rank = 0
	}
};
local quest_type = quest_types.invalid;

local session_manager_type_def = sdk.find_type_definition("snow.SnowSessionManager");
local on_timeout_matchmaking_method = session_manager_type_def:get_method("funcOnTimeoutMatchmaking");

local req_matchmaking_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSession");
local req_matchmaking_random_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandom");
local req_matchmaking_hyakuryu_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionHyakuryu");
local req_matchmaking_random_master_rank_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMasterRank");
local req_matchmaking_random_mystery_method = session_manager_type_def:get_method("reqMatchmakingAutoJoinSessionRandomMystery");

local nullable_uint32_type_def = sdk.find_type_definition("System.Nullable`1<System.UInt32>");
local nullable_uint32_get_value_method = nullable_uint32_type_def:get_method("get_Value");
local nullable_uint32_constructor_method = nullable_uint32_type_def:get_method(".ctor(System.UInt32)");

local function on_post_timeout_matchmaking()
	local timeout_fix_config = config.current_config.timeout_fix;

	if not timeout_fix_config.enabled then
		return;
	end

	if session_manager == nil then
		session_manager = sdk.get_managed_singleton("snow.SnowSessionManager");

		if session_manager == nil then
			log.info("[Better Matchmaking] No session manager");
			return;
		end
	end

	if quest_type == quest_types.regular then
		if timeout_fix_config.quest_types.regular then
			req_matchmaking_method:call(session_manager, quest_type.quest_id);
		end

	elseif quest_type == quest_types.random then
		if timeout_fix_config.quest_types.random then
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

			req_matchmaking_hyakuryu_method:call(session_manager, quest_type.difficulty, quest_level_pointer, target_enemy_pointer);
		end

	elseif quest_type == quest_types.random_master_rank then
		if timeout_fix_config.quest_types.random_master_rank then
			req_matchmaking_random_master_rank_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank);
		end

	elseif quest_type == quest_types.random_anomaly then
		if timeout_fix_config.quest_types.random_anomaly then
			req_matchmaking_random_mystery_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank);
		end
	end
end

local function on_req_matchmaking(quest_id)
	quest_type = quest_types.regular;
	quest_type.quest_id = quest_id;
end

local function on_req_matchmaking_random(my_hunter_rank)
	quest_type = quest_types.random;
	quest_type.my_hunter_rank = my_hunter_rank;
end

local function on_req_matchmaking_rampage(difficulty, quest_level_pointer, target_enemy_pointer)
	quest_type = quest_types.rampage;
	quest_type.difficulty = difficulty;

	local quest_level_pointer_int = sdk.to_int64(quest_level_pointer);
	local target_enemy_pointer_int = sdk.to_int64(target_enemy_pointer);

	quest_type.quest_level.has_value = quest_level_pointer_int > 0;
	quest_type.target_enemy.has_value = target_enemy_pointer_int > 0;

	if quest_type.quest_level.has_value then
		quest_type.quest_level.value = nullable_uint32_get_value_method(quest_level_pointer);
	end

	if quest_type.target_enemy.has_value then
		quest_type.target_enemy.value = nullable_uint32_get_value_method(target_enemy_pointer);
	end
end

local function on_req_matchmaking_random_master_rank(my_hunter_rank, my_master_rank)
	quest_type = quest_types.random_master_rank;
	quest_type.my_hunter_rank = my_hunter_rank;
	quest_type.my_master_rank = my_master_rank;
end

local function on_req_matchmaking_random_anomaly(my_hunter_rank, my_master_rank)
	quest_type = quest_types.random_anomaly;
	quest_type.my_hunter_rank = my_hunter_rank;
	quest_type.my_master_rank = my_master_rank;
end

local function on_req_online()
	if not config.current_config.hide_online_warning.enabled then
		return;
	end

	return sdk.PreHookResult.SKIP_ORIGINAL;
end

function timeout_fix.init_module()
	config = require("Better_Matchmaking.config");
	table_helpers = require("Better_Matchmaking.table_helpers");

	sdk.hook(on_timeout_matchmaking_method, function(args) end,
		function(retval)
			on_post_timeout_matchmaking();
			return retval;
		end);

	sdk.hook(req_matchmaking_method, function(args)
		on_req_matchmaking(sdk.to_int64(args[3]) & 0xFFFFFFFF);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_random_method, function(args)
		on_req_matchmaking_random(sdk.to_int64(args[3]) & 0xFFFFFFFF);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_hyakuryu_method, function(args)
		on_req_matchmaking_rampage(sdk.to_int64(args[3]), args[4], args[5]);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_random_master_rank_method, function(args)
		on_req_matchmaking_random_master_rank(sdk.to_int64(args[3]) & 0xFFFFFFFF,
			sdk.to_int64(args[4]) & 0xFFFFFFFF);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_random_mystery_method, function(args)
		on_req_matchmaking_random_anomaly(sdk.to_int64(args[3]) & 0xFFFFFFFF,
			sdk.to_int64(args[4]) & 0xFFFFFFFF);
	end, function(retval)
		return retval;
	end);
end

return timeout_fix;


