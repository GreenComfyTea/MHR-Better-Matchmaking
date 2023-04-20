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

this.is_opened = false;
this.status = "OK";

this.window_position = Vector2f.new(480, 200);
this.window_pivot = Vector2f.new(0, 0);
this.window_size = Vector2f.new(535, 480);
this.window_flags = 0x10120;

this.color_picker_flags = 327680;
this.decimal_input_flags = 33;

this.region_lock_filters = { "Close", "Default", "Far", "Worldwide" };

function this.init()
end

function this.draw()
	imgui.set_next_window_pos(this.window_position, 1 << 3, this.window_pivot);
	imgui.set_next_window_size(this.window_size, 1 << 3);

	this.is_opened = imgui.begin_window(
		"Better Matchmaking v" .. config.current_config.version, this.is_opened, this.window_flags);

	if not this.is_opened then
		imgui.end_window();
		return;
	end

	local status_string = tostring(this.status);
	imgui.text("Status: " .. status_string);

	local config_changed = false;
	local changed = false;
	local index = 1;

	if imgui.tree_node("Timeout Fix") then
		changed, config.current_config.timeout_fix.enabled = imgui.checkbox(
			"Enabled", config.current_config.timeout_fix.enabled);
		config_changed = config_changed or changed;

		if imgui.tree_node("Quest Types") then
			changed, config.current_config.timeout_fix.quest_types.regular = imgui.checkbox(
				"Regular", config.current_config.timeout_fix.quest_types.regular);
			config_changed = config_changed or changed;

			changed, config.current_config.timeout_fix.quest_types.rampage = imgui.checkbox(
				"Rampage", config.current_config.timeout_fix.quest_types.rampage);
			config_changed = config_changed or changed;

			changed, config.current_config.timeout_fix.quest_types.random = imgui.checkbox(
				"Random", config.current_config.timeout_fix.quest_types.random);
			config_changed = config_changed or changed;

			changed, config.current_config.timeout_fix.quest_types.random_master_rank = imgui.checkbox(
				"Random MR", config.current_config.timeout_fix.quest_types.random_master_rank);
			config_changed = config_changed or changed;

			changed, config.current_config.timeout_fix.quest_types.random_anomaly = imgui.checkbox(
				"Random Anomaly", config.current_config.timeout_fix.quest_types.random_anomaly);
			config_changed = config_changed or changed;

			changed, config.current_config.timeout_fix.quest_types.anomaly_investigation = imgui.checkbox(
				"Anomaly Investigation", config.current_config.timeout_fix.quest_types.anomaly_investigation);
			config_changed = config_changed or changed;

			imgui.tree_pop();
		end

		imgui.tree_pop();
	end

	if imgui.tree_node("Region Lock Fix (Join Requests)") then
		changed, config.current_config.region_lock_fix.enabled = imgui.checkbox(
			"Enabled", config.current_config.region_lock_fix.enabled);
		config_changed = config_changed or changed;

		changed, index = imgui.combo(
			"Distance Filter", 
			utils.table.find_index(this.region_lock_filters, config.current_config.region_lock_fix.distance_filter), 
			this.region_lock_filters);
		config_changed = config_changed or changed;

		if changed then
			config.current_config.region_lock_fix.distance_filter = this.region_lock_filters[index];
		end


		if imgui.tree_node("Explanation") then
			--k_ELobbyDistanceFilterClose	0	Only lobbies in the same immediate region will be returned.
			--k_ELobbyDistanceFilterDefault	1	Only lobbies in the same region or nearby regions will be returned.
			--k_ELobbyDistanceFilterFar	2	For games that don't have many latency requirements, will return lobbies about half-way around the globe.
			--k_ELobbyDistanceFilterWorldwide	3	No filtering, will match lobbies as far as India to NY (not recommended, expect multiple seconds of latency between the clients).

			imgui.text("Close - Only quest sessions in the same immediate region will be returned.");
			imgui.text("Default - Only quest sessions in the same region or nearby regions will be returned.");
			imgui.text("Far - Will return quest sessions about half-way around the globe.");
			imgui.text("Worldwide - No filtering, will match quest sessions as far as India to NY");
			imgui.text("(not recommended, expect multiple seconds of latency between the clients).");

			imgui.tree_pop();
		end

		imgui.tree_pop();
	end

	if imgui.tree_node("Hide Network Errors") then
		changed, config.current_config.hide_network_errors.enabled = imgui.checkbox(
			"Enabled", config.current_config.hide_network_errors.enabled);
		config_changed = config_changed or changed;

		if imgui.tree_node("When to hide") then
			changed, config.current_config.hide_network_errors.when_to_hide.on_quests = imgui.checkbox(
				"On Quests", config.current_config.hide_network_errors.when_to_hide.on_quests);
			config_changed = config_changed or changed;

			changed, config.current_config.hide_network_errors.when_to_hide.outside_quests = imgui.checkbox(
				"Outside Quests", config.current_config.hide_network_errors.when_to_hide.outside_quests);
			config_changed = config_changed or changed;

			imgui.tree_pop();
		end

		imgui.tree_pop();
	end

	if imgui.tree_node("Misc") then
		changed, config.current_config.hide_online_warning.enabled = imgui.checkbox(
			"Hide Online Warning", config.current_config.hide_online_warning.enabled);
		config_changed = config_changed or changed;

		imgui.tree_pop();
	end

	imgui.end_window();

	if config_changed then
		config.save();
	end
end

function this.init_module()
	utils = require("Better_Matchmaking.utils");
	config = require("Better_Matchmaking.config");

	this.init();
end

return this;
