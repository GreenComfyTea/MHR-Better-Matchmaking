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
	},
	--snow.SnowSessionManager.reqMatchmakingAutoJoinSessionRandomMysteryQuest(System.UInt32, System.UInt32, System.UInt32, System.Nullable`1<System.UInt32>)
	anomaly_investigation = {
		min_level = 1,
		max_level = 1,
		party_limit = 4,
		enemy_id = {
			value = 0,
			has_value = false
		}
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

function timeout_fix.get_search_time()
	return os.clock() - t0;
end

function timeout_fix.on_post_timeout_matchmaking()
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
			req_matchmaking_random_mystery_method:call(session_manager, quest_type.my_hunter_rank, quest_type.my_master_rank);
		end
	elseif quest_type == quest_types.anomaly_investigation then
		if timeout_fix_config.quest_types.anomaly_investigation then
			
			local enemy_id_pointer = ValueType.new(nullable_uint32_type_def);
			nullable_uint32_constructor_method:call(enemy_id_pointer, quest_type.enemy_id.value);
			enemy_id_pointer:set_field("_HasValue", quest_type.enemy_id.has_value);
			
			skip_next_hook = true;
			req_matchmaking_random_mystery_quest_method:call(session_manager, quest_type.min_level, quest_type.max_level, quest_type.party_limit, enemy_id_pointer);
		end
	end
end

function timeout_fix.on_req_matchmaking(quest_id)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end

	quest_type = quest_types.regular;
	quest_type.quest_id = quest_id;
end

function timeout_fix.on_req_matchmaking_random(my_hunter_rank)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	
	quest_type = quest_types.random;
	quest_type.my_hunter_rank = my_hunter_rank;
end

function timeout_fix.on_req_matchmaking_rampage(difficulty, quest_level_pointer, target_enemy_pointer)
	if skip_next_hook then
		skip_next_hook = false;
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

function timeout_fix.on_req_matchmaking_random_master_rank(my_hunter_rank, my_master_rank)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	
	quest_type = quest_types.random_master_rank;
	quest_type.my_hunter_rank = my_hunter_rank;
	quest_type.my_master_rank = my_master_rank;
end

function timeout_fix.on_req_matchmaking_random_anomaly(my_hunter_rank, my_master_rank)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end
	
	quest_type = quest_types.random_anomaly;
	quest_type.my_hunter_rank = my_hunter_rank;
	quest_type.my_master_rank = my_master_rank;
end

function timeout_fix.on_req_matchmaking_random_anomaly_quest(min_level, max_level, party_limit, enemy_id_pointer)
	if skip_next_hook then
		skip_next_hook = false;
		return;
	end

	quest_type = quest_types.anomaly_investigation;
	quest_type.min_level = min_level;
	quest_type.max_level = max_level;
	quest_type.party_limit = party_limit;

	local enemy_id_pointer_int = sdk.to_int64(enemy_id_pointer);

	quest_type.enemy_id.has_value = nullable_uint32_get_has_value_method:call(enemy_id_pointer);

	if quest_type.enemy_id.has_value then
		quest_type.enemy_id.value = nullable_uint32_get_value_or_default_method(enemy_id_pointer);
	end
end

function timeout_fix.on_req_online()
	if not config.current_config.hide_online_warning.enabled then
		return;
	end

	return sdk.PreHookResult.SKIP_ORIGINAL;
end

local network_util_type_def = sdk.find_type_definition("snow.network.Util");
local get_re_and_lib_version_method = network_util_type_def:get_method("getReAndLibVersion");
local tostring_error_method = network_util_type_def:get_method("toString_Error(via.network.Error)");

local make_error_code_method = session_manager_type_def:get_method("makeErrorCode(via.network.Error)");

function timeout_fix.init_module()
	config = require("Better_Matchmaking.config");
	table_helpers = require("Better_Matchmaking.table_helpers");

	--sdk.hook(make_error_code_method, function(args)
	--	local error_code = sdk.to_managed_object(args[3]);
	--	xy = "valid: " .. tostring(error_code:call("get_Valid"));
	--	xy = xy .. "\nnative user id: " .. tostring(error_code:call("get_NativeUserId"));
	--	xy = xy .. "\nlevel: " .. tostring(error_code:call("get_Level"));
	--	xy = xy .. "\nservice: " .. tostring(error_code:call("get_Service"));
	--	xy = xy .. "\nmethod: " .. tostring(error_code:call("get_Method"));
	--	xy = xy .. "\ncause: " .. tostring(error_code:call("get_Cause"));
	--	xy = xy .. "\nno: " .. tostring(error_code:call("get_No"));
	--	xy = xy .. "\nsub: " .. tostring(error_code:call("get_Sub"));
	--	xy = xy .. "\nnative: " .. tostring(error_code:call("get_Native"));
	--
	--end,
	--function(retval)
	--	xy = xy .. "\n" .. tostring(sdk.to_managed_object(retval):call("ToString"));
	--	return retval;
	--end);

	sdk.hook(on_timeout_matchmaking_method, function(args) end,
	function(retval)
		timeout_fix.on_post_timeout_matchmaking();
		return retval;
	end);

	sdk.hook(req_matchmaking_method, function(args)
		timeout_fix.on_req_matchmaking(
			sdk.to_int64(args[3]) & 0xFFFFFFFF);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_random_method, function(args)
		timeout_fix.on_req_matchmaking_random(
			sdk.to_int64(args[3]) & 0xFFFFFFFF);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_hyakuryu_method, function(args)
		timeout_fix.on_req_matchmaking_rampage(
			sdk.to_int64(args[3]),
			args[4],
			args[5]);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_random_master_rank_method, function(args)
		timeout_fix.on_req_matchmaking_random_master_rank(
			sdk.to_int64(args[3]) & 0xFFFFFFFF,
			sdk.to_int64(args[4]) & 0xFFFFFFFF);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_random_mystery_method, function(args)
		timeout_fix.on_req_matchmaking_random_anomaly(
			sdk.to_int64(args[3]) & 0xFFFFFFFF,
			sdk.to_int64(args[4]) & 0xFFFFFFFF);
	end, function(retval)
		return retval;
	end);

	sdk.hook(req_matchmaking_random_mystery_quest_method, function(args)
		timeout_fix.on_req_matchmaking_random_anomaly_quest(
			sdk.to_int64(args[3]) & 0xFFFFFFFF,
			sdk.to_int64(args[4]) & 0xFFFFFFFF,
			sdk.to_int64(args[5]) & 0xFFFFFFFF,
			args[6]);
	end, function(retval)
		return retval;
	end);
end

return timeout_fix;


