local config = {};
local table_helpers;

config.current_config = nil;
config.config_file_name = "Better Matchmaking/config.json";

config.default_config = {};

function config.init()
	config.default_config = {
		timeout_fix = {
			enabled = true,

			quest_types = {
				regular = true,
				random = true,
				rampage = false,
				random_master_rank = true,
				random_anomaly = true
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
			enabled = true,
			distance_filter = "Far"
		}
	};
end

function config.load()
	local loaded_config = json.load_file(config.config_file_name);
	if loaded_config ~= nil then
		log.info("[Better Matchmaking] config.json loaded successfully");
		config.current_config = table_helpers.merge(config.default_config, loaded_config);
	else
		log.error("[Better Matchmaking] Failed to load config.json");
		config.current_config = table_helpers.deep_copy(config.default_config);
	end
end

function config.save()
	-- save current config to disk, replacing any existing file
	local success = json.dump_file(config.config_file_name, config.current_config);
	if success then
		log.info("[Better Matchmaking] config.json saved successfully");
	else
		log.error("[Better Matchmaking] Failed to save config.json");
	end
end

function config.init_module()
	table_helpers = require("Better_Matchmaking.table_helpers");

	config.init();
	config.load();
	config.current_config.version = "v2.2";
end

return config;
