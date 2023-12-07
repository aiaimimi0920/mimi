extends "./stable_horde_httpclient.gd"

signal login_successful(user_details)

var user_details: Dictionary
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)
@export var api_key := '0000000000'

func login() -> void:
	if state != States.READY:
		push_warning("Login currently working. Cannot do more than 1 request at a time with the same Stable Horde Login.")
		return
	user_details.clear()
	state = States.WORKING
	var headers = [
		"Content-Type: application/json", "apikey: " + api_key,
		"Client-Agent: " + "Lucid Creations:" + plugin_node.get_plugin_info().version + ":db0#1625"
	]
	var error = request(plugin_node.service_config_manager.aihorde_url + "/api/v2/find_user", headers, HTTPClient.METHOD_GET)
	if error != OK:
		var error_msg := "Something went wrong when initiating the stable horde request"
		push_error(error_msg)
		emit_signal("request_failed",error_msg)


# Function to overwrite to process valid return from the horde
func process_request(json_ret) -> void:
	if typeof(json_ret) != TYPE_DICTIONARY:
		var error_msg : String = "Unexpected user format received"
		push_error("Unexpected user format received" + ': ' +  json_ret)
		state = States.READY
		emit_signal("request_failed",error_msg)
		return
	user_details = json_ret
	emit_signal("login_successful", user_details)
	state = States.READY

func has_logged_in() -> bool:
	return(not user_details.is_empty())

func get_username() -> String:
	if not has_logged_in():
		return('Not Logged In')
	return(user_details.username)

func get_kudos() -> int:
	if not has_logged_in():
		return(0)
	return(user_details.kudos)

func get_workers() -> Array:
	if not has_logged_in():
		return([])
	return(user_details.worker_ids)

func get_worker_count() -> int:
	if not has_logged_in():
		return(0)
	return(user_details.worker_count)
