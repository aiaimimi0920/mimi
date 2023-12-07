extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


func get_func(url):
	var result = await  HttpRequestManager.send_http_get_request(url)
	pass


func post_func(url, data):
	var result = await  HttpRequestManager.send_http_post_request(url,data)
	pass

func put_func(url, data):
	var result = await  HttpRequestManager.send_http_put_request(url,data)
	pass
