local this = {};

local utils;
local config;

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

local last_session_steam_object = nil;

function this.on_set_is_invisible(session_steam)
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

function this.init_module()
	config = require("Better_Matchmaking.config");
	utils = require("Better_Matchmaking.utils");

	sdk.hook(set_is_invisible_method, function(args)
		this.on_set_is_invisible(sdk.to_managed_object(args[1]));
	end, function(retval)
		return retval;
	end);
end

return this;
