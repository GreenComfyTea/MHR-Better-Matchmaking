local misc_fixes = {};
local table_helpers;
local config;

local session_manager_type_def = sdk.find_type_definition("snow.SnowSessionManager");
local req_online_warning_method = session_manager_type_def:get_method("reqOnlineWarning");

local gui_manager_type_def = sdk.find_type_definition("snow.gui.GuiManager");
local set_open_network_error_window_selection_method = gui_manager_type_def:get_method("setOpenNetworkErrorWindowSelection");

local quest_manager_type_definition = sdk.find_type_definition("snow.QuestManager");
local on_changed_game_status = quest_manager_type_definition:get_method("onChangedGameStatus");

local quest_status_index = 0;

function misc_fixes.on_changed_game_status(new_quest_status)
	quest_status_index = new_quest_status;
end

function misc_fixes.on_req_online_warning()
	if not config.current_config.hide_online_warning.enabled then
		return;
	end

	return sdk.PreHookResult.SKIP_ORIGINAL;
end

function misc_fixes.on_set_open_network_error_window_selection(gui_manager)
	local cached_config = config.current_config.hide_network_errors;
	if not cached_config.enabled then
		return;
	end

	if quest_status_index == 2 then
		if cached_config.when_to_hide.on_quests then
			return sdk.PreHookResult.SKIP_ORIGINAL;
		end
	else
		if cached_config.when_to_hide.outside_quests then
			return sdk.PreHookResult.SKIP_ORIGINAL;
		end
	end
end

function misc_fixes.init_module()
	config = require("Better_Matchmaking.config");
	table_helpers = require("Better_Matchmaking.table_helpers");

	sdk.hook(req_online_warning_method, function(args) 
		return misc_fixes.on_req_online_warning();
	end, function(retval)
		return retval;
	end);

	sdk.hook(on_changed_game_status, function(args)
		misc_fixes.on_changed_game_status(sdk.to_int64(args[3]));
	end, function(retval) return retval; end);

	sdk.hook(set_open_network_error_window_selection_method, function(args)
		return misc_fixes.on_set_open_network_error_window_selection(sdk.to_managed_object(args[2]));
	end, function(retval)
		return retval;
	end);
end

return misc_fixes;
