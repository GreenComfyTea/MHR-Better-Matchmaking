local customization_menu = {};

local table_helpers;
local config;


customization_menu.is_opened = false;
customization_menu.status = "OK";

customization_menu.window_position = Vector2f.new(480, 200);
customization_menu.window_pivot = Vector2f.new(0, 0);
customization_menu.window_size = Vector2f.new(500, 480);
customization_menu.window_flags = 0x10120;

customization_menu.color_picker_flags = 327680;
customization_menu.decimal_input_flags = 33;

customization_menu.region_lock_filters = { "Close", "Default", "Far", "Worldwide" };

function customization_menu.init()
end

function customization_menu.draw()
	imgui.set_next_window_pos(customization_menu.window_position, 1 << 3, customization_menu.window_pivot);
	imgui.set_next_window_size(customization_menu.window_size, 1 << 3);

	customization_menu.is_opened = imgui.begin_window(
		"Better Matchmaking" .. " " .. config.current_config.version, customization_menu.is_opened, customization_menu.window_flags);

	if not customization_menu.is_opened then
		imgui.end_window();
		return;
	end

	local status_string = tostring(customization_menu.status);
	imgui.text("Status: " .. status_string);

	local config_changed = false;
	local changed = false;
	local index = false;

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

			imgui.tree_pop();
		end

		imgui.tree_pop();
	end

	if imgui.tree_node("Region Lock Fix") then
		changed, config.current_config.region_lock_fix.enabled = imgui.checkbox(
			"Enabled", config.current_config.region_lock_fix.enabled);
		config_changed = config_changed or changed;

		changed, index = imgui.combo(
			"Distance Filter", 
			table_helpers.find_index(customization_menu.region_lock_filters, config.current_config.region_lock_fix.distance_filter), 
			customization_menu.region_lock_filters);
		config_changed = config_changed or changed;

		if changed then
			config.current_config.region_lock_fix.distance_filter = customization_menu.region_lock_filters[index];
		end


		if imgui.tree_node("Explanation") then
			--k_ELobbyDistanceFilterClose	0	Only lobbies in the same immediate region will be returned.
			--k_ELobbyDistanceFilterDefault	1	Only lobbies in the same region or nearby regions will be returned.
			--k_ELobbyDistanceFilterFar	2	For games that don't have many latency requirements, will return lobbies about half-way around the globe.
			--k_ELobbyDistanceFilterWorldwide	3	No filtering, will match lobbies as far as India to NY (not recommended, expect multiple seconds of latency between the clients).

			imgui.text("Close - Only lobbies in the same immediate region will be returned.");
			imgui.text("Default - Only lobbies in the same region or nearby regions will be returned.");
			imgui.text("Far - Will return lobbies about half-way around the globe.");
			imgui.text("Worldwide - No filtering, will match lobbies as far as India to NY");
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

function customization_menu.init_module()
	table_helpers = require("Better_Matchmaking.table_helpers");
	config = require("Better_Matchmaking.config");

	customization_menu.init();
end

return customization_menu;
