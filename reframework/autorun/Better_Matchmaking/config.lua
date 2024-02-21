local this = {};
local version = "2.4";

local utils;

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

this.current_config = nil;
this.config_file_name = "Better Matchmaking/config.json";

this.default_config = {};

function this.init()
	this.default_config = {
		customization_menu = {
			position = {
				x = 480,
				y = 200
			},

			size = {
				width = 570,
				height = 480
			},

			pivot = {
				x = 0,
				y = 0
			}
		},

		timeout_fix = {
			enabled = true,

			quest_types = {
				regular = true,
				random = true,
				rampage = true,
				random_master_rank = true,
				random_anomaly = true,
				anomaly_investigation = true
			}
		},

		hide_online_warning = {
			enabled = true,
		},

		hide_network_errors = {
			enabled = true,
			when_to_hide = {
				on_quests = true,
				outside_quests = false
				
			}
		},

		region_lock_fix = {
			join_requests = {
				enabled = true,
				distance_filter = "Worldwide"
			},
			lobbies = {
				enabled = true,
				distance_filter = "Worldwide"
			}
		},

		language_filter_fix = {
			enabled = true,
			lobby_language_filter_bypass = {
				enabled = false
			}
		}
	};
end

function this.load()
	local loaded_config = json.load_file(this.config_file_name);
	if loaded_config ~= nil then
		log.info("[Better Matchmaking] config.json loaded successfully");
		this.current_config = utils.table.merge(this.default_config, loaded_config);
	else
		log.error("[Better Matchmaking] Failed to load config.json");
		this.current_config = utils.table.deep_copy(this.default_config);
	end
end

function this.save()
	-- save current config to disk, replacing any existing file
	local success = json.dump_file(this.config_file_name, this.current_config);
	if success then
		log.info("[Better Matchmaking] config.json saved successfully");
	else
		log.error("[Better Matchmaking] Failed to save config.json");
	end
end

function this.reset()
	this.current_config = utils.table.deep_copy(this.default_config);
	this.current_config.version = version;
end

function this.init_module()
	utils = require("Better_Matchmaking.utils");

	this.init();
	this.load();
	this.current_config.version = version;
end

return this;
