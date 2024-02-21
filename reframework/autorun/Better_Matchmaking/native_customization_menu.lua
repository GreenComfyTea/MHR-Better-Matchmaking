---@diagnostic disable: need-check-nil, undefined-field
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

local mod_menu_api_package_name = "ModOptionsMenu.ModMenuApi";
local mod_menu = nil;

local native_UI = nil;

this.show_quest_types = false;
this.show_when_to_hide_options = false;
this.region_lock_filter_descriptions = {
	"Close - Only quest sessions in the same immediate region\nwill be returned.",
	"Default - Only quest sessions in the same region or nearby\nregions will be returned.",
	"Far - Will return quest sessions about half-way around the\nglobe.",
	"Worldwide - No filtering, will match quest sessions as far\nas India to NY (not recommended, expect multiple\nseconds of latency between the clients)."
};

--no idea how this works but google to the rescue
--can use this to check if the api is available and do an alternative to avoid complaints from users
function this.is_module_available(name)
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

function this.draw()
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
		this.show_quest_types = not this.show_quest_types;
		
		mod_menu.Repaint();
	end

	if this.show_quest_types then
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

	local join_requests_region_lock_fix = config.current_config.region_lock_fix.join_requests;

	changed, join_requests_region_lock_fix.enabled = mod_menu.CheckBox(
		"Enabled", join_requests_region_lock_fix.enabled, "Enable/Disable Region Lock Fix for Join Requests.");
	config_changed = config_changed or changed;

	changed, index = mod_menu.Options(
		"Distance Filter",
		utils.table.find_index(customization_menu.region_lock_filters, join_requests_region_lock_fix.distance_filter),
		customization_menu.region_lock_filters,
		this.region_lock_filter_descriptions,
		"Change Distance Filter."
	);
	config_changed = config_changed or changed;

	if changed then
		join_requests_region_lock_fix.distance_filter = customization_menu.region_lock_filters[index];
	end





	mod_menu.Header("Region Lock Fix (Lobbies)");

	local lobbies_region_lock_fix = config.current_config.region_lock_fix.lobbies;

	changed, lobbies_region_lock_fix.enabled = mod_menu.CheckBox(
		"Enabled", lobbies_region_lock_fix.enabled, "Enable/Disable Region Lock Fix for Lobbies.");
	config_changed = config_changed or changed;

	changed, index = mod_menu.Options(
		"Distance Filter",
		utils.table.find_index(customization_menu.region_lock_filters, lobbies_region_lock_fix.distance_filter),
		customization_menu.region_lock_filters,
		this.region_lock_filter_descriptions,
		"Change Distance Filter."
	);
	config_changed = config_changed or changed;

	if changed then
		lobbies_region_lock_fix.distance_filter = customization_menu.region_lock_filters[index];
	end





	mod_menu.Header("Language Filter Fix");

	changed, config.current_config.language_filter_fix.enabled = mod_menu.CheckBox("Enabled",
		config.current_config.language_filter_fix.enabled,
		"Enable/Disable Language Filter Fix for Lobbies.");
	config_changed = config_changed or changed;

	changed, config.current_config.language_filter_fix.lobby_language_filter_bypass.enabled = mod_menu.CheckBox( "Bypass Lobby Language Filter",
		config.current_config.language_filter_fix.lobby_language_filter_bypass.enabled,
		"Enable/Disable Lobby Language Filter Bypass. <COL RED> Use only when absolutely necessary!</RED>");
	config_changed = config_changed or changed;





	mod_menu.Header("Hide Network Errors");

	changed, config.current_config.hide_network_errors.enabled = mod_menu.CheckBox(
		"Enabled", config.current_config.hide_network_errors.enabled, "Enable/Disable hiding Network Error messages.");
	config_changed = config_changed or changed;


	if mod_menu.Button("<COL YEL>When to hide Options</COL>", "", false, "Show/Hide Options to hide Network Errors on and outside quests.") then
		this.show_when_to_hide_options = not this.show_when_to_hide_options;

		mod_menu.Repaint();
	end

	if this.show_when_to_hide_options then
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

function this.on_reset_all_settings()
	config.current_config = utils.table.deep_copy(config.default_config);
end

function this.init_module()
	utils = require("Better_Matchmaking.utils");
	config = require("Better_Matchmaking.config");
	customization_menu = require("Better_Matchmaking.customization_menu");

	if this.is_module_available(mod_menu_api_package_name) then
		mod_menu = require(mod_menu_api_package_name);
	end

	if mod_menu == nil then
		log.info("[Better Matchmaking] No mod_menu_api API package found. You may need to download it or something.");
		return;
	end

	native_UI = mod_menu.OnMenu(
		"Better Matchmaking",
		"Disables Timeout when searching for \"Join Request\".\nDisables Region Lock and Online Warning.",
		this.draw
	);

	native_UI.OnResetAllSettings = this.on_reset_all_settings;
end

return this;
