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
	#GuiManager.console_print_warning("正在尝试连接到Mirai框架中，请稍候... | 连接地址: "+ws_url)
	if plugin_node.service_loader.is_running():
		var err:int = _client.connect_to_url(ws_url)
		if err:
			#GuiManager.console_print_error("无法连接到Mirai框架，请检查配置是否有误")
			#GuiManager.console_print_warning("将于10秒后尝试重新连接...")
			await get_tree().create_timer(10).timeout
			connect_to_service(ws_url)
		else:
			await get_tree().create_timer(5).timeout
			if _client.get_socket().get_ready_state() == WebSocketPeer.STATE_CONNECTING:
				_client.close()
	else:
		#GuiManager.console_print_warning("Mirai进程未在运行中，将在其启动后自动进行连接...")
		#GuiManager.mirai_console_print_warning("Mirai进程未在运行中，将在其启动后自动与RainyBot进行连接...")
		if OS.has_feature("editor") and plugin_node.service_loader.test_mode == plugin_node.service_loader.TEST_MODE.TEST_SCRIPT:
			await get_tree().create_timer(10).timeout
		else:
			await plugin_node.service_loader.service_ready
		connect_to_service(ws_url)


func disconnect_to_service()->void:
	if is_service_connected():
		_client.close()


func _closed(_was_clean:bool=false)->void:
		#get_tree().call_group("Plugin","_on_disconnect") # 应该不用调用
	#GuiManager.console_print_warning("到Mirai框架的连接已被关闭，若非人为请检查配置是否有误")
	#GuiManager.mirai_console_print_warning("到RainyBot的连接已被关闭，若非人为请检查配置是否有误")
	#GuiManager.console_print_warning("若Mirai进程被意外关闭或运行异常，请使用命令 mirai restart 来重新启动")
	#GuiManager.mirai_console_print_warning("若Mirai进程被意外关闭或运行异常，请使用命令 restart 来重新启动")
	
	if plugin_node.service_loader.is_running():
		#GuiManager.console_print_warning("将于10秒后尝试重新连接...")
		#GuiManager.mirai_console_print_warning("将于10秒后尝试重新与RainyBot建立连接...")
		await get_tree().create_timer(10).timeout
	else:
		#GuiManager.console_print_warning("Mirai进程未在运行中，将在其启动后自动进行重连...")
		#GuiManager.mirai_console_print_warning("Mirai进程未在运行中，将在其启动后自动与RainyBot进行重连...")
		if OS.has_feature("editor") and plugin_node.service_loader.test_mode == plugin_node.service_loader.TEST_MODE.TEST_SCRIPT:
			await get_tree().create_timer(10).timeout
		else:
			await plugin_node.service_loader.service_ready
	connect_to_service(plugin_node.get_ws_url())


func _connected(_proto:String="")->void:
	#GuiManager.console_print_success("成功与Mirai框架进行通信，正在等待响应...")
	#GuiManager.mirai_console_print_success("成功与RainyBot进行通信，正在等待响应...")
	Logger.info("链接后台{plugin_name}成功".format({"plugin_name":plugin_name}))
	emit_signal("client_connected")


func _on_data(message)->void:
	
	var data_array:Array = plugin_node.service_protocol_handle.parse_data(Marshalls.base64_to_raw(message))
	var data = data_array[0]
	var callable = data_array[1]
	if data.has("syncId"):
		var syncId:int = int(data["syncId"])
		if syncId != -1 and processing_command.has(syncId):
			_parse_command_result(data)
	
	
	printt("client收到消息",data)

	## 在子协议中根据需要做信号通知
	if callable:
		callable.call(data.get("server_syncId",-1), data["content"])
		

func _physics_process(_delta:float)->void:
	_client.poll()


func send_service_request(server_syncId, content:Dictionary, caller:Callable,timeout:float)->Dictionary:
	if !is_service_connected():
		#GuiManager.console_print_error("未连接到Mirai框架，指令请求发送失败: "+str(command)+" "+str(sub_command)+" "+str(content))
		return {}
	var syncId:int = randi()
	while syncId==-1 or processing_command.has(syncId):
		syncId = randi()

	var service_protocol_handle = plugin_node.service_protocol_handle
	var data_array = service_protocol_handle.stringify(syncId, server_syncId, content, caller)
	var data = data_array[0]
	var data_dict = data_array[1]
	printt("client发出消息",data_dict)
	
	#GuiManager.console_print_warning("正在发送指令请求到Mirai框架："+ str(request))
	var cmd:RequestInstance = RequestInstance.new()
	cmd.syncId = syncId
	cmd.request = data_dict
	processing_command[syncId] = cmd
	_client.send(Marshalls.raw_to_base64(data))
	if timeout > 0.0:
		#GuiManager.console_print_warning("本次请求的超时时间为: %s秒"% timeout)
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
		#GuiManager.console_print_success("获取到Mirai框架的回应: "+str(result))
		cmd.emit_signal("request_finished")


func _tick_command_timeout(cmd_ins:RequestInstance,_timeout:float)->void:
	await get_tree().create_timer(_timeout).timeout
	if is_instance_valid(cmd_ins) && cmd_ins.result == {}:
		#GuiManager.console_print_error("指令请求超时，无法获取到返回结果: "+str(cmd_ins.request))
		cmd_ins.emit_signal("request_finished")
		
		
class RequestInstance:
	extends RefCounted
	
	signal request_finished
	var request:Dictionary = {}
	var result:Dictionary = {}
	var syncId:int = -1

	func get_result()->Dictionary:
		return result
