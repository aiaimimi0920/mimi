extends BaseConfigManager
class_name BasePluginConfigManager

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)
var config_path = PluginManager.get_plugin_config_path(plugin_name)

signal config_loaded

func _init():
	DIR_SAVE_FILE_DEFAULT = config_path
	DIR_SETTINGS_DEFAULT = plugin_node.get_absolute_path("modules/settings")
	super()

func init_config()->void:
	_apply_settings()
	emit_signal("config_loaded")

var service_address:
	get:
		return get_value("General","ServiceAddress","127.0.0.1")
	set(val):
		set_value("General","ServiceAddress", val)

var service_port:
	get:
		return int(get_value("General","ServicePort",8080))
	set(val):
		set_value("General","ServicePort", val)

var proxy_host:
	get:
		return get_value("General","ProxyHost","")
	set(val):
		set_value("General","ProxyHost", val)

var proxy_port:
	get:
		return int(get_value("General","ProxyPort", 0))
	set(val):
		set_value("General","ProxyPort", val)
		
var data_format:
	get:
		var cur_data = get_value("General","DataFormat",1)
		if cur_data == 0:
			return "json"
		return "protobuf"
	set(val):
		var cur_val = val
		if cur_val is String:
			if cur_val.to_lower() == "json":
				cur_val = 0
			elif cur_val.to_lower() == "protobuf":
				cur_val = 1
		elif cur_val is int:
			if cur_val == 0:
				cur_val = 0
			elif cur_val >= 1:
				cur_val = 1
		else:
			cur_val = 1
		set_value("General","DataFormat", cur_val)

var request_timeout:
	get:
		return get_value("General","RequestTimeout",20.0)
	set(val):
		set_value("General","RequestTimeout", val)


var service_address_port:
	get:
		var ws_text:String = "ws://{service_address}:{service_port}"
		return ws_text.format({"service_address":service_address,"service_port":service_port})


var proxy_address_port:
	get:
		if proxy_host!="":
			return "%s"%(proxy_host)+":"+"%s"%(proxy_port)
		return ""


func apply_all():
	pass
