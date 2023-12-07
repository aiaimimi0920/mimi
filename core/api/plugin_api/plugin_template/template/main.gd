extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"Plugin name","mimi",plugin_version,
		"plugin description","plugin",{})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)


var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	add_child(service_config_manager,true)
	service_config_manager.init_config()

func _config_loaded()->void:
	pass

func _ready()->void:
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()

