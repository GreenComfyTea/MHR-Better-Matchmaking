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

local session_steam_type_def = sdk.find_type_definition("via.network.SessionSteam");
local set_lobby_distance_filter_method = session_steam_type_def:get_method("setLobbyDistanceFilter");
local set_is_invisible_method = session_steam_type_def:get_method("setIsInvisible");
local set_p2p_version_method = session_steam_type_def:get_method("set_P2pVersion");

function this.set_distance_filter(session_steam, region_lock_fix_config)
	if not region_lock_fix_config.enabled then
		set_lobby_distance_filter_method:call(session_steam, 1);
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
end

function this.on_set_is_invisible(session_steam)
	if session_steam == nil then
		customization_menu.status = "[misc_fixes.on_set_is_invisible] No session_steam";
		return;
	end

	this.set_distance_filter(session_steam, config.current_config.region_lock_fix.join_requests)
end

function this.on_set_p2p_version(session_steam)
	if session_steam == nil then
		customization_menu.status = "[misc_fixes.on_set_p2p_version] No session_steam";
		return;
	end

	this.set_distance_filter(session_steam, config.current_config.region_lock_fix.lobbies)
end


function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");
	customization_menu = require("Better_Matchmaking.customization_menu");

	sdk.hook(set_is_invisible_method, function(args)
		this.on_set_is_invisible(sdk.to_managed_object(args[1]));
	end, function(retval)
		return retval;
	end);

	sdk.hook(set_p2p_version_method, function(args)
		this.on_set_p2p_version(sdk.to_managed_object(args[1]));
	end, function(retval)
		return retval;
	end);


	local session_manager_type_def = sdk.find_type_definition("snow.SnowSessionManager");
	local is_lobby_search_result_condition_check_method = session_manager_type_def:get_method("isLobbySearchResultConditionCheck(via.network.session.SearchResult, System.Int32, System.Int32, System.Boolean)");

	sdk.hook(is_lobby_search_result_condition_check_method, function(args)
		local search_result = sdk.to_managed_object(args[2]);

		local info = search_result:get_SessionInfo();
		local unique_id = search_result:get_UniqueId();
		local name = search_result:get_Name();

		local service_type = info:get_ServiceType();
		local member_num = info:get_MemberNum();
		local member_max = info:get_MemberMax();
		local rtt = info:get_Rtt();
		local presence = info:get_ByPresence();
		local invitation = info:get_ByInvitation();
		local private = info:get_Private();
		local close = info:get_Close();
		local option = info:get_Option();
		
		local search_key = info:get_SearchKey();

		local key_count = search_key:getU32KeyCount();

		local keys = {}
		
		-- search_key:setU32Key(6, 965861247);

		for i = 0, key_count - 1 do
			local key = search_key:getU32Key(i);
			keys[i + 1] = key;
		end

		log.debug(string.format("\nunique_id: %s", tostring(unique_id)));
		log.debug(string.format("name: %s\n", tostring(name)));

		log.debug(string.format("service_type: %s", tostring(service_type)));
		log.debug(string.format("member_num: %s", tostring(member_num)));
		log.debug(string.format("member_max: %s", tostring(member_max)));
		log.debug(string.format("rtt: %s", tostring(rtt)));
		log.debug(string.format("presence: %s", tostring(presence)));
		log.debug(string.format("invitation: %s", tostring(invitation)));
		log.debug(string.format("private: %s", tostring(private)));
		log.debug(string.format("close: %s", tostring(close)));
		log.debug(string.format("option: %s\n", tostring(option)));

		log.debug(string.format("key_count: %s", tostring(key_count)));
		log.debug(string.format("keys: %s\n", utils.table.tostring(keys)));
	end, function(retval)
		log.debug(tostring((sdk.to_int64(retval) & 1) == 1));
		log.debug("");
		return retval;
	end);
end

return this;
