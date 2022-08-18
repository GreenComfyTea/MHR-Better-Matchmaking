local native_customization_menu = {};

local table_helpers;
local config;
local customization_menu;

local mod_menu_api_package_name = "ModOptionsMenu.ModMenuApi";
local mod_menu = nil;

local native_UI = nil;

native_customization_menu.show_quest_types = false;
native_customization_menu.show_when_to_hide_options = false;
native_customization_menu.region_lock_filter_descriptions = {
	"Close - Only lobbies in the same immediate region\nwill be returned.",
	"Default - Only lobbies in the same region or nearby\nregions will be returned.",
	"Far - Will return lobbies about half-way around the\nglobe.",
	"Worldwide - No filtering, will match lobbies as far\nas India to NY (not recommended, expect multiple\nseconds of latency between the clients)."
};

--no idea how this works but google to the rescue
--can use this to check if the api is available and do an alternative to avoid complaints from users
function native_customization_menu.is_module_available(name)
	if package.loaded[name] then
		return true;
	else
		for _, searcher in ipairs(package.searchers or package.loaders) do
			local loader = searcher(name);

			if type(loader) == 'function' then
				package.preload[name] = loader;
				return true;
			end
		end

		return false;
	end
end

function native_customization_menu.draw()
	local changed = false;
	local config_changed = false;
	local index = 1; 

	mod_menu.Label("Created by: <COL RED>GreenComfyTea</COL>", "",
		"Donate: <COL RED>https://streamelements.com/greencomfytea/tip</COL>\nBuy me a tea: <COL RED>https://ko-fi.com/greencomfytea</COL>\nSometimes I stream: <COL RED>twitch.tv/greencomfytea</COL>");
		mod_menu.Label("Version: <COL RED>" .. config.current_config.version .. "</COL>", "",
		"Donate: <COL RED>https://streamelements.com/greencomfytea/tip</COL>\nBuy me a tea: <COL RED>https://ko-fi.com/greencomfytea</COL>\nSometimes I stream: <COL RED>twitch.tv/greencomfytea</COL>");





	mod_menu.Header("Timeout Fix");

	changed, config.current_config.timeout_fix.enabled = mod_menu.CheckBox("Enabled", config.current_config.timeout_fix.enabled, "Enable/Disable Timeout Fix.");
	config_changed = config_changed or changed;

	if mod_menu.Button("<COL YEL>Quest Types</COL>", "", false, "Show/Hide Options to enable Timeout Fix for Specific Quest Types.") then
		native_customization_menu.show_quest_types = not native_customization_menu.show_quest_types;
		
		mod_menu.Repaint();
	end

	if native_customization_menu.show_quest_types then
		mod_menu.IncreaseIndent();
		mod_menu.IncreaseIndent();

		changed, config.current_config.timeout_fix.quest_types.regular = mod_menu.CheckBox(
			"Regular", config.current_config.timeout_fix.quest_types.regular, "Enable/Disable Timeout Fix for Regular Quests.");
		config_changed = config_changed or changed;

		changed, config.current_config.timeout_fix.quest_types.rampage = mod_menu.CheckBox(
			"Rampage", config.current_config.timeout_fix.quest_types.rampage, "Enable/Disable Timeout Fix for Rampage Quests.");
		config_changed = config_changed or changed;

		changed, config.current_config.timeout_fix.quest_types.random = mod_menu.CheckBox(
			"Random", config.current_config.timeout_fix.quest_types.random, "Enable/Disable Timeout Fix for Random LR/HR Quests.");
		config_changed = config_changed or changed;

		changed, config.current_config.timeout_fix.quest_types.random_master_rank = mod_menu.CheckBox(
			"Random MR", config.current_config.timeout_fix.quest_types.random_master_rank, "Enable/Disable Timeout Fix for Random MR Quests.");
		config_changed = config_changed or changed;

		changed, config.current_config.timeout_fix.quest_types.random_anomaly  = mod_menu.CheckBox(
			"Random Anomaly", config.current_config.timeout_fix.quest_types.random_anomaly, "Enable/Disable Timeout Fix for Random Anomaly Quests.");
		config_changed = config_changed or changed;

		changed, config.current_config.timeout_fix.quest_types.anomaly_investigation  = mod_menu.CheckBox(
			"Anomaly Investigation", config.current_config.timeout_fix.quest_types.anomaly_investigation, "Enable/Disable Timeout Fix for Random Anomaly Quests.");
		config_changed = config_changed or changed;

		mod_menu.DecreaseIndent();
		mod_menu.DecreaseIndent();
	end





	mod_menu.Header("Region Lock Fix (Join Requests)");

	changed, config.current_config.region_lock_fix.enabled = mod_menu.CheckBox(
		"Enabled", config.current_config.region_lock_fix.enabled, "Enable/Disable Region Lock Fix for Join Requests.");
	config_changed = config_changed or changed;

	changed, index = mod_menu.Options(
		"Distance Filter",
		table_helpers.find_index(customization_menu.region_lock_filters, config.current_config.region_lock_fix.distance_filter),
		customization_menu.region_lock_filters,
		native_customization_menu.region_lock_filter_descriptions,
		"Change Distance Filter."
	);
	config_changed = config_changed or changed;

	if changed then
		config.current_config.region_lock_fix.distance_filter = customization_menu.region_lock_filters[index];
	end





	mod_menu.Header("Hide Network Errors");

	changed, config.current_config.hide_network_errors.enabled = mod_menu.CheckBox(
		"Enabled", config.current_config.hide_network_errors.enabled, "Enable/Disable hiding Network Error messages.");
	config_changed = config_changed or changed;


	if mod_menu.Button("<COL YEL>When to hide Options</COL>", "", false, "Show/Hide Options to hide Network Errors on and outside quests.") then
		native_customization_menu.show_when_to_hide_options = not native_customization_menu.show_when_to_hide_options;

		mod_menu.Repaint();
	end

	if native_customization_menu.show_when_to_hide_options then
		mod_menu.IncreaseIndent();
		mod_menu.IncreaseIndent();

		changed, config.current_config.hide_network_errors.when_to_hide.on_quests = mod_menu.CheckBox(
			"On Quests", config.current_config.hide_network_errors.when_to_hide.on_quests, "Enable/Disable hiding Network Error messages on quests.");
		config_changed = config_changed or changed;

		changed, config.current_config.hide_network_errors.when_to_hide.outside_quests = mod_menu.CheckBox(
			"Outside Quests", config.current_config.hide_network_errors.when_to_hide.outside_quests, "Enable/Disable hiding Network Error messages outside quests.");
		config_changed = config_changed or changed;

		mod_menu.DecreaseIndent();
		mod_menu.DecreaseIndent();
	end





	mod_menu.Header("Misc");
	
	changed, config.current_config.hide_online_warning.enabled = mod_menu.CheckBox(
		"Hide Online Warning", config.current_config.hide_online_warning.enabled, "Hide/Show Online Warning message.");
	config_changed = config_changed or changed;

	if config_changed then
		config.save();
	end
end

function native_customization_menu.on_reset_all_settings()
	config.current_config = table_helpers.deep_copy(config.default_config);
end

function native_customization_menu.init_module()
	table_helpers = require("Better_Matchmaking.table_helpers");
	config = require("Better_Matchmaking.config");
	customization_menu = require("Better_Matchmaking.customization_menu");

	if native_customization_menu.is_module_available(mod_menu_api_package_name) then
		mod_menu = require(mod_menu_api_package_name);
	end

	if mod_menu == nil then
		log.info("[Better Matchmaking] No mod_menu_api API package found. You may need to download it or something.");
		return;
	end

	native_UI = mod_menu.OnMenu(
		"Better Matchmaking",
		"Disables Timeout when searching for \"Join Request\".\nDisables Region Lock and Online Warning.",
		native_customization_menu.draw
	);

	native_UI.OnResetAllSettings = native_customization_menu.on_reset_all_settings;

end

return native_customization_menu;
