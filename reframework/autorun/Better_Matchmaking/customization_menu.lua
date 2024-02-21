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
this.window_size = Vector2f.new(570, 480);
this.window_flags = 0x10120;

this.color_picker_flags = 327680;
this.decimal_input_flags = 33;

this.region_lock_filters = { "Close", "Default", "Far", "Worldwide" };

function this.init()
end

function this.draw()
	if not this.is_opened then
		return;
	end

	local window_position = Vector2f.new(config.current_config.customization_menu.position.x, config.current_config.customization_menu.position.y);
	local window_pivot = Vector2f.new(config.current_config.customization_menu.pivot.x, config.current_config.customization_menu.pivot.y);
	local window_size = Vector2f.new(config.current_config.customization_menu.size.width, config.current_config.customization_menu.size.height);

	imgui.set_next_window_pos(window_position, 1 << 3, window_pivot);
	imgui.set_next_window_size(window_size, 1 << 3);

	this.is_opened = imgui.begin_window("Better Matchmaking v" .. config.current_config.version, this.is_opened, this.window_flags);

	if not this.is_opened then
		imgui.end_window();
		config.save_current();
		return;
	end

	local config_changed = false;
	local changed = false;
	local index = 1;

	local new_window_position = imgui.get_window_pos();
	if window_position.x ~= new_window_position.x or window_position.y ~= new_window_position.y then
		config_changed = config_changed or true;

		config.current_config.customization_menu.position.x = new_window_position.x;
		config.current_config.customization_menu.position.y = new_window_position.y;
	end

	local new_window_size = imgui.get_window_size();
	if window_size.x ~= new_window_size.x or window_size.y ~= new_window_size.y then
		config_changed = config_changed or true;

		config.current_config.customization_menu.size.width = new_window_size.x;
		config.current_config.customization_menu.size.height = new_window_size.y;
	end

	local new_window_size = imgui.get_window_size();
	config_changed = config_changed or new_window_size.x ~= window_size.x or new_window_size.y ~= window_size.y;

	if imgui.button("Reset Config") then
		config.reset();
		config_changed = true;
	end

	imgui.same_line();

	local status_string = tostring(this.status);
	imgui.text("Status: " .. status_string);

	

	if imgui.tree_node("Timeout Fix") then
		local timeout_fix_config = config.current_config.timeout_fix;

		changed, timeout_fix_config.enabled = imgui.checkbox(
			"Enabled", timeout_fix_config.enabled);
		config_changed = config_changed or changed;

		if imgui.tree_node("Quest Types") then
			changed, timeout_fix_config.quest_types.regular = imgui.checkbox(
				"Regular", timeout_fix_config.quest_types.regular);
			config_changed = config_changed or changed;

			changed, timeout_fix_config.quest_types.rampage = imgui.checkbox(
				"Rampage", timeout_fix_config.quest_types.rampage);
			config_changed = config_changed or changed;

			changed, timeout_fix_config.quest_types.random = imgui.checkbox(
				"Random", timeout_fix_config.quest_types.random);
			config_changed = config_changed or changed;

			changed, timeout_fix_config.quest_types.random_master_rank = imgui.checkbox(
				"Random MR", timeout_fix_config.quest_types.random_master_rank);
			config_changed = config_changed or changed;

			changed, timeout_fix_config.quest_types.random_anomaly = imgui.checkbox(
				"Random Anomaly", timeout_fix_config.quest_types.random_anomaly);
			config_changed = config_changed or changed;

			changed, timeout_fix_config.quest_types.anomaly_investigation = imgui.checkbox(
				"Anomaly Investigation", timeout_fix_config.quest_types.anomaly_investigation);
			config_changed = config_changed or changed;

			imgui.tree_pop();
		end

		imgui.tree_pop();
	end

	if imgui.tree_node("Region Lock Fix") then

		if imgui.tree_node("Join Requests") then
			local region_lock_fix_config = config.current_config.region_lock_fix.join_requests;
	
			changed, region_lock_fix_config.enabled = imgui.checkbox(
				"Enabled", region_lock_fix_config.enabled);
			config_changed = config_changed or changed;
	
			changed, index = imgui.combo(
				"Distance Filter", 
				utils.table.find_index(this.region_lock_filters, region_lock_fix_config.distance_filter),
				this.region_lock_filters);
			config_changed = config_changed or changed;
	
			if changed then
				region_lock_fix_config.distance_filter = this.region_lock_filters[index];
			end
	
			imgui.tree_pop();
		end
	
		if imgui.tree_node("Lobbies") then
			local region_lock_fix_config = config.current_config.region_lock_fix.lobbies;
	
			changed, region_lock_fix_config.enabled = imgui.checkbox(
				"Enabled", region_lock_fix_config.enabled);
			config_changed = config_changed or changed;
	
			changed, index = imgui.combo(
				"Distance Filter", 
				utils.table.find_index(this.region_lock_filters, region_lock_fix_config.distance_filter),
				this.region_lock_filters);
			config_changed = config_changed or changed;
	
			if changed then
				region_lock_fix_config.distance_filter = this.region_lock_filters[index];
			end
	
			imgui.tree_pop();
		end

		if imgui.tree_node("Explanation") then
			--k_ELobbyDistanceFilterClose	0	Only lobbies in the same immediate region will be returned.
			--k_ELobbyDistanceFilterDefault	1	Only lobbies in the same region or nearby regions will be returned.
			--k_ELobbyDistanceFilterFar	2	For games that don't have many latency requirements, will return lobbies about half-way around the globe.
			--k_ELobbyDistanceFilterWorldwide	3	No filtering, will match lobbies as far as India to NY (not recommended, expect multiple seconds of latency between the clients).

			imgui.text("Close - Only sessions in the same immediate region will be returned.");
			imgui.text("Default - Only sessions in the same region or nearby regions will be returned.");
			imgui.text("Far - Will return sessions about half-way around the globe.");
			imgui.text("Worldwide - No filtering, will match sessions as far as India to NY");
			imgui.text("(not recommended, expect multiple seconds of latency between the clients).");

			imgui.tree_pop();
		end

		imgui.tree_pop();
	end

	if imgui.tree_node("Language Filter Fix") then
		local language_filter_fix = config.current_config.language_filter_fix;

		changed, language_filter_fix.enabled = imgui.checkbox(
			"Enabled", language_filter_fix.enabled);
		config_changed = config_changed or changed;

		if imgui.tree_node("Lobby Language Filter Bypass") then
			changed, language_filter_fix.lobby_language_filter_bypass.enabled = imgui.checkbox(
				"Enabled", language_filter_fix.lobby_language_filter_bypass.enabled);
			config_changed = config_changed or changed;
				
			imgui.text_colored("I encourage you to respect the host's decision to play only with people of the same", 0xFF4040FF);
			imgui.text_colored("language and use the bypass only when absolutely necessary.", 0xFF4040FF);

			imgui.tree_pop();
		end

		if imgui.tree_node("Explanation") then
			imgui.text("\"Language\" option for lobbies doesn't behave as you would expect in this game.");
			imgui.text("\"Any Language\" is treated as a separate language entry, basically.");
			
			imgui.new_line();
			imgui.text("Vanilla:");
			imgui.new_line();

			-- Any Language Search

			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Match", 0xFF80FF80);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Success", 0xFF80FF80);

			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Don't Match", 0xFF4040FF);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Success", 0xFF80FF80);

			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Match", 0xFF80FF80);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Failure", 0xFF4040FF);

			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Don't Match", 0xFF4040FF);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Failure", 0xFF80FF80);

			imgui.new_line();

			-- Same Language Search

			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Match", 0xFF80FF80);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Failure", 0xFF4040FF);

			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Don't Match", 0xFF4040FF);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Failure", 0xFF80FF80);

			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Match", 0xFF80FF80);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Success", 0xFF80FF80);

			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Don't Match", 0xFF4040FF);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Failure", 0xFF80FF80);

			-- With Language Filter Fix

			imgui.new_line();
			imgui.text("With Language Filter Fix:");
			imgui.new_line();

			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Match", 0xFF80FF80);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Success", 0xFF80FF80);

			-- With Language Filter Fix and Lobby Language Filter Bypass

			imgui.new_line();
			imgui.text("With Language Filter Fix and Lobby Language Filter Bypass:");
			imgui.new_line();

			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Don't Match", 0xFF4040FF);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Success", 0xFF80FFFF);

			-- Can't be fixed

			imgui.new_line();
			imgui.text("Can't be fixed because the game doesn't send the info about the actual language");
			imgui.text("for \"Any Language\" lobbies:");
			imgui.new_line();

			imgui.text_colored("\"Same Language\"", 0xFFFF80C0);
			imgui.same_line();
			imgui.text("Search  +");
			imgui.same_line();
			imgui.text_colored("\"Any Language\"", 0xFFFFC080);
			imgui.same_line();
			imgui.text("Lobby  +");
			imgui.same_line();
			imgui.text_colored("Languages Match", 0xFF80FF80);
			imgui.text("=");
			imgui.same_line();
			imgui.text_colored("Failure", 0xFF4040FF);
			
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
