extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"free_ai_adapter","mimi",plugin_version,"Free AI conversation service","service",{})
	
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	

func _ready()->void:
	service_client = load(get_absolute_path("modules/client.gd")).new()
	service_loader = load(get_absolute_path("modules/loader.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	service_protocol_handle = load(get_absolute_path("modules/protocol_handle.gd")).new()
	chat_script = load(get_absolute_path("api/chat/chat.gd"))
	init_all_node()
	start()
	pass


var chat_script

var chat_node

	
func init_all_node():
	chat_node = chat_script.new()
	add_child(chat_node)

func init_completions(http=null, https=null,use_http=true):
	return await chat_node.init_completions(http, https,use_http)

func create_chat_completion(stream=false, messages=[],use_http=true):
	return await chat_node.create_chat_completion(stream, messages,use_http)


func _on_unload()->void:
	service_client.disconnect_to_service()
	service_loader.kill_service()
	pass


var service_client
var service_loader
var service_config_manager
var service_protocol_handle


func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	service_client.name = "Client"
	service_loader.name = "Loader"
	add_child(service_config_manager,true)
	add_child(service_client,true)
	add_child(service_loader,true)
	service_config_manager.init_config()



func _config_loaded()->void:
	if await service_loader.load_service() == OK:
		Logger.info("Waiting for {plugin_name} backend to complete initialization steps, please wait".format({"plugin_name":plugin_name}))
		
		if OS.has_feature("editor") and service_loader.test_mode == service_loader.TEST_MODE.TEST_SCRIPT:
			await get_tree().create_timer(10).timeout
		else:
			await service_loader.service_ready

		service_client.connect_to_service(get_ws_url())

func get_ws_url()->String:
	return service_config_manager.service_address_port

func get_ai_url()->String:
	return service_config_manager.service_ai_address_port

func get_ai_host()->String:
	return service_config_manager.service_ai_address_host

func get_ai_port()->int:
	return service_config_manager.service_ai_port


func is_service_connected()->bool:
	return service_client.is_service_connected()
	
func is_ready()->bool:
	if is_service_connected():
		return true
	await service_client.client_connected
	return true

func send_service_request(server_syncId, content:Dictionary, caller:Callable,_timeout:float=-INF)->Dictionary:
	if _timeout <= -INF and service_config_manager.request_timeout > 0.0:
		_timeout=service_config_manager.request_timeout
	return await service_client.send_service_request(server_syncId, content, caller, _timeout)
