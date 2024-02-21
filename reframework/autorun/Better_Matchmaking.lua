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

local utils = require("Better_Matchmaking.utils");
local config = require("Better_Matchmaking.config");

local customization_menu = require("Better_Matchmaking.customization_menu");
local native_customization_menu = require("Better_Matchmaking.native_customization_menu");

local timeout_fix = require("Better_Matchmaking.timeout_fix");
local region_lock_fix = require("Better_Matchmaking.region_lock_fix");
local language_filter_fix = require("Better_Matchmaking.language_filter_fix");
local misc_fixes = require("Better_Matchmaking.misc_fixes");

utils.init_module();
config.init_module();

customization_menu.init_module();
native_customization_menu.init_module();

timeout_fix.init_module();
region_lock_fix.init_module();
language_filter_fix.init_module();
misc_fixes.init_module();

log.info("[Better Matchmaking] Loaded.");

re.on_draw_ui(function()
	if imgui.button("Better Matchmaking v" .. config.current_config.version) then
		customization_menu.is_opened = not customization_menu.is_opened;
	end
end);

re.on_frame(function()
	if not reframework:is_drawing_ui() then
		customization_menu.is_opened = false;
	end

	if customization_menu.is_opened then
		pcall(customization_menu.draw);
	end
end);