extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var sub_protocol = preload("./sub_protocol.gd")

func _ready():
	register_all_protocol()

func register_all_protocol():
	## 注册所有的服务端调用协议
	var service_protocol_handle = plugin_node.service_protocol_handle
	service_protocol_handle.register_protocol_format_with_object(sub_protocol, self)
	
	## 可以通过其他方式注册单个协议
	#local_server_protocol_handle.register_c_s_protocol_format(main_protocol_name, sub_protocol_id, sub_protocol.get(c_s_name), Callable(self, c_s_name))
	#local_server_protocol_handle.register_s_c_protocol_format(main_protocol_name, sub_protocol_id, sub_protocol.get(c_s_name), Callable(self, c_s_name))


func search_music(songName, singer):
	var data = {}
	data["songName"] = songName
	data["singer"] = singer
	data["saveDir"] = GlobalManager.globalize_file_path
	data["proxiesHttp"] = plugin_node.service_config_manager.proxy_address_port
	data["proxiesHttps"] = plugin_node.service_config_manager.proxy_address_port

	var result = await C_S_SEARCH_MUSIC(-1, data)
	# var audio = Marshalls.base64_to_raw(result["content"])
	return result


func download_music(songName, singer, downloadUrl):
	var data = {}
	data["songName"] = songName
	data["singer"] = singer
	data["downloadUrl"] = downloadUrl
	data["saveDir"] = GlobalManager.globalize_file_path
	data["proxiesHttp"] = plugin_node.service_config_manager.proxy_address_port
	data["proxiesHttps"] = plugin_node.service_config_manager.proxy_address_port
	var result = await C_S_DOWNLOAD_MUSIC(-1, data)
	return result



## 方法名与子协议同名
func C_S_SEARCH_MUSIC(server_syncId, content):
	## C_S_TEST为当前调用的方法的字符串，暂时没有找到可以直接获得当前方法名字的方法
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_SEARCH_MUSIC"))

## 方法名与子协议同名
func C_S_DOWNLOAD_MUSIC(server_syncId, content):
	## C_S_TEST为当前调用的方法的字符串，暂时没有找到可以直接获得当前方法名字的方法
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_DOWNLOAD_MUSIC"))
	

## 方法名与子协议同名
func S_C_SEARCH_MUSIC(server_syncId, content):
	pass

## 方法名与子协议同名
func S_C_DOWNLOAD_MUSIC(server_syncId, content):
	pass

