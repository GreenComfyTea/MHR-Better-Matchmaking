local table_helpers = require("Better_Matchmaking.table_helpers");
local config = require("Better_Matchmaking.config");

local customization_menu = require("Better_Matchmaking.customization_menu");
local native_customization_menu = require("Better_Matchmaking.native_customization_menu");

local timeout_fix = require("Better_Matchmaking.timeout_fix");
local region_lock_fix = require("Better_Matchmaking.region_lock_fix");
local misc_fixes = require("Better_Matchmaking.misc_fixes");

table_helpers.init_module();
config.init_module();

customization_menu.init_module();
native_customization_menu.init_module();

timeout_fix.init_module();
region_lock_fix.init_module();
misc_fixes.init_module();

log.info("[Better Matchmaking] loaded");

re.on_draw_ui(function()
	if imgui.button("Better Matchmaking " .. config.current_config.version) then
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