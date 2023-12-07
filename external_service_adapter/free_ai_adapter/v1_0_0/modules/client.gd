extends Node

signal client_connected

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


var _client:WebSocketClient = WebSocketClient.new()
var current_session:String = ""
var processing_command:Dictionary = {}

func _ready()->void:
	_client.connection_closed.connect(_closed)
	_client.connected_to_server.connect(_connected)
	_client.message_received.connect(_on_data)


func connect_to_service(ws_url:String)->void:
	if plugin_node.service_loader.is_running():
		var err:int = _client.connect_to_url(ws_url)
		if err:
			await get_tree().create_timer(10).timeout
			connect_to_service(ws_url)
		else:
			await get_tree().create_timer(5).timeout
			if _client.get_socket().get_ready_state() == WebSocketPeer.STATE_CONNECTING:
				_client.close()
	else:
		if OS.has_feature("editor") and plugin_node.service_loader.test_mode == plugin_node.service_loader.TEST_MODE.TEST_SCRIPT:
			await get_tree().create_timer(10).timeout
		else:
			await plugin_node.service_loader.service_ready

		connect_to_service(ws_url)


func disconnect_to_service()->void:
	if is_service_connected():
		_client.close()


func _closed(_was_clean:bool=false)->void:	
	if plugin_node.service_loader.is_running():
		await get_tree().create_timer(10).timeout
	else:
		if OS.has_feature("editor") and plugin_node.service_loader.test_mode == plugin_node.service_loader.TEST_MODE.TEST_SCRIPT:
			await get_tree().create_timer(10).timeout
		else:
			await plugin_node.service_loader.service_ready

	connect_to_service(plugin_node.get_ws_url())


func _connected(_proto:String="")->void:
	Logger.info("Successfully linked backend {plugin_name}".format({"plugin_name":plugin_name}))
	emit_signal("client_connected")
	pass


func _on_data(message)->void:
	var data_array:Array = plugin_node.service_protocol_handle.parse_data(Marshalls.base64_to_raw(message))
	var data = data_array[0]
	var callable = data_array[1]
	if data.has("syncId"):
		var syncId:int = int(data["syncId"])
		if syncId != -1 and processing_command.has(syncId):
			_parse_command_result(data)
	
	printt("The client received a message:",data)

	if callable:
		callable.call(data.get("server_syncId",-1), data["content"])
		

func _physics_process(_delta:float)->void:
	_client.poll()


func send_service_request(server_syncId, content:Dictionary, caller:Callable,timeout:float)->Dictionary:
	if !is_service_connected():
		return {}
	var syncId:int = randi()
	while syncId==-1 or processing_command.has(syncId):
		syncId = randi()

	var service_protocol_handle = plugin_node.service_protocol_handle
	var data_array = service_protocol_handle.stringify(syncId, server_syncId, content, caller)
	var data = data_array[0]
	var data_dict = data_array[1]
	printt("The client sends a message:",data_dict)
	
	var cmd:RequestInstance = RequestInstance.new()
	cmd.syncId = syncId
	cmd.request = data_dict
	processing_command[syncId] = cmd
	_client.send(Marshalls.raw_to_base64(data))
	if timeout > 0.0:
		_tick_command_timeout(cmd, timeout)
	await cmd.request_finished
	processing_command.erase(syncId)
	return cmd.get_result()


func is_service_connected()->bool:
	return _client.get_socket().get_ready_state() == WebSocketPeer.STATE_OPEN


func _parse_command_result(result:Dictionary)->void:
	var syncId:int = int(result["syncId"])
	if syncId != -1 and processing_command.has(syncId):
		var cmd:RequestInstance = processing_command[syncId]
		cmd.result = result["content"]
		cmd.emit_signal("request_finished")


func _tick_command_timeout(cmd_ins:RequestInstance,_timeout:float)->void:
	await get_tree().create_timer(_timeout).timeout
	if is_instance_valid(cmd_ins) && cmd_ins.result == {}:
		cmd_ins.emit_signal("request_finished")
		
		
class RequestInstance:
	extends RefCounted
	
	signal request_finished
	var request:Dictionary = {}
	var result:Dictionary = {}
	var syncId:int = -1

	func get_result()->Dictionary:
		return result
