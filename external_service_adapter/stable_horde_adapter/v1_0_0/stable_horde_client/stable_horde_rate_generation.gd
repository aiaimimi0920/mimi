extends "./stable_horde_httpclient.gd"
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)
signal generation_rated(awarded_kudos)


func submit_rating(request_id: String, ratings_payload: Dictionary) -> void:
	if state != States.READY:
		print_debug("Rating is already being processed")
		return
	state = States.WORKING
	var body = JSON.new().stringify(ratings_payload)
	var url = plugin_node.service_config_manager.aihorde_url + "/api/v2/generate/rate/" + request_id
	var headers = [
		"Content-Type: application/json", 
		"Client-Agent: " + "Lucid Creations:" + plugin_node.get_plugin_info().version + ":(discord)db0#1625"
	]
#	print_debug(url)
#	print_debug(body)
#	print_debug(headers)
	var error = request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		var error_msg := "Something went wrong when initiating the stable horde request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)

# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) != TYPE_DICTIONARY:
		var error_msg : String = "Unexpected model format received"
		push_error("Unexpected model format received" + ': ' +  json_ret)
		emit_signal("request_failed",error_msg)
		state = States.READY
		return
	var awarded_kudos = json_ret["reward"]
	emit_signal("generation_rated", awarded_kudos)
	state = States.READY
