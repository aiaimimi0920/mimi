extends PluginAPI
## This plugin is modified using Godot plugin code: the plugin code is combined with some actual project code
## https://github.com/Haidra-Org/AI-Horde-Godot-Addon/tree/4.0   
## https://github.com/Haidra-Org/Lucid-Creations

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"stable_horde_adapter","mimi",plugin_version,"Provide AI painting services","service",{})
	
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	
func _ready()->void:
	service_client = load(get_absolute_path("./stable_horde_client/stable_horde_client.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	pass


func generate(replacement_prompt := '', replacement_params := {}):
	service_client.generate(replacement_prompt, replacement_params)
	return await service_client.images_generated

var service_client
var service_config_manager


func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	service_client.name = "Client"
	add_child(service_config_manager,true)
	add_child(service_client,true)
	service_config_manager.init_config()

func _config_loaded()->void:
	pass


