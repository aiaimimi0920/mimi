extends PluginAPI #默认继承插件类，请勿随意改动

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"free_vector_adapter","mimi", plugin_version,
		"Free vector services","service",{})
	
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	

func _ready()->void:
	service_client = load(get_absolute_path("modules/client.gd")).new()
	service_loader = load(get_absolute_path("modules/loader.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	service_protocol_handle = load(get_absolute_path("modules/protocol_handle.gd")).new()
	
	chroma_script = load(get_absolute_path("api/chroma/chroma.gd"))
	init_all_node()
	start()


var chroma_script

var chroma_node

	
func init_all_node():
	chroma_node = chroma_script.new()
	add_child(chroma_node)

func add_documents(documents=[], metadatas=[],ids=[],type="dynamic",persistent=false,space="main",uris=null):
	return await chroma_node.add_documents(documents, metadatas,ids,type,persistent,space,uris)

func delete_documents(ids=null, where=null,where_document=null,type="dynamic",persistent=false,space="main",uris=null):
	return await chroma_node.delete_documents(ids, where,where_document,type,persistent,space,uris)

func get_documents(ids=null, where=null,where_document=null,include=[],type="dynamic",persistent=false,space="main",uris=null):
	return await chroma_node.get_documents(ids, where,where_document,include,type,persistent,space,uris)

func query_documents(query_embeddings=null,query_texts=null,query_images=null,
	query_uris=null,n_results=10,where=null,where_document=null,include=null,
	type="dynamic",persistent=false,space="main",uris=null):
	return await chroma_node.query_documents(query_embeddings,query_texts,query_images,
		query_uris,n_results,where,where_document,include,type,persistent,space,uris)


func load_files(file_paths=[],type="dynamic",persistent=false,space="main"):
	return await chroma_node.load_files(file_paths,type,persistent,space)

func unload_files(file_paths=[],type="dynamic",persistent=false,space="main"):
	return await chroma_node.unload_files(file_paths,type,persistent,space)

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

func is_service_connected()->bool:
	return service_client.is_service_connected()


func send_service_request(server_syncId, content:Dictionary, caller:Callable,_timeout:float=-INF)->Dictionary:
	if _timeout <= -INF and service_config_manager.request_timeout > 0.0:
		_timeout=service_config_manager.request_timeout
	return await service_client.send_service_request(server_syncId, content, caller, _timeout)

func is_ready()->bool:
	if is_service_connected():
		return true
	await service_client.client_connected
	return true
