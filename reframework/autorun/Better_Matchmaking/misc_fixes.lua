local misc_fixes = {};
local table_helpers;
local config;

local gui_manager_type_def = sdk.find_type_definition("snow.gui.GuiManager");
local set_open_network_error_window_selection_method = gui_manager_type_def:get_method("setOpenNetworkErrorWindowSelection");

function misc_fixes.on_set_open_network_error_window_selection(gui_manager)
	
end

function misc_fixes.init_module()
	config = require("Better_Matchmaking.config");
	table_helpers = require("Better_Matchmaking.table_helpers");

	sdk.hook(set_open_network_error_window_selection_method, function(args)
		misc_fixes.on_set_open_network_error_window_selection(sdk.to_managed_object(args[2]));
	end, function(retval)
		return retval;
	end);
end

return misc_fixes;
