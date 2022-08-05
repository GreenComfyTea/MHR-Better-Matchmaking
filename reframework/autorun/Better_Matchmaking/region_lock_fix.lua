local region_lock_fix = {};
local table_helpers;
local config;

local session_steam_type_def = sdk.find_type_definition("via.network.SessionSteam");
local set_lobby_distance_filter_method = session_steam_type_def:get_method("setLobbyDistanceFilter");
local set_is_invisible_method = session_steam_type_def:get_method("setIsInvisible");

local last_session_steam_object = nil;

function region_lock_fix.on_set_is_invisible(session_steam)
	local region_lock_fix_config = config.current_config.region_lock_fix;
	if not region_lock_fix_config.enabled then
		if session_steam ~= last_session_steam_object then
			set_lobby_distance_filter_method:call(session_steam, 1);
		end

		last_session_steam_object = session_steam;
		return;
	end

	if region_lock_fix_config.distance_filter == "Worldwide" then
		set_lobby_distance_filter_method:call(session_steam, 3);
	elseif region_lock_fix_config.distance_filter == "Far" then
		set_lobby_distance_filter_method:call(session_steam, 2);
	elseif region_lock_fix_config.distance_filter == "Close" then
		set_lobby_distance_filter_method:call(session_steam, 0);
	else -- "Default"
		set_lobby_distance_filter_method:call(session_steam, 1);
	end

	last_session_steam_object = session_steam;
end

function region_lock_fix.init_module()
	config = require("Better_Matchmaking.config");
	table_helpers = require("Better_Matchmaking.table_helpers");

	sdk.hook(set_is_invisible_method, function(args)
		region_lock_fix.on_set_is_invisible(sdk.to_managed_object(args[1]));
	end, function(retval)
		return retval;
	end);
end

return region_lock_fix;
