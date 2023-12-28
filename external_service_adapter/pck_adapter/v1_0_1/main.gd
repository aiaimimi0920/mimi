extends PluginAPI
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	## Note that this plugin is only intended for developers to use and cannot be used normally in a regular runtime environment. 
	## Mainly used for exporting available plugin PCK packages. Please do not export too many plugins at the same time during runtime
	set_plugin_info(plugin_name,"pck_adapter","mimi",plugin_version,"Provide the function of packaging files into PCK format",
		"service",{})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	

func _ready()->void:
	service_client = load(get_absolute_path("modules/client.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	pass

func pck_package_file(path, only_big_version=false):
	var pck_path = await service_client.create_pck(path, only_big_version)
	return pck_path

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

