extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var sub_protocol = preload("./sub_protocol.gd")

func _ready():
	register_all_protocol()

func register_all_protocol():
	## Register all server protocols
	var service_protocol_handle = plugin_node.service_protocol_handle
	service_protocol_handle.register_protocol_format_with_object(sub_protocol, self)
	
	## Individual protocols can be registered through other means
	#local_server_protocol_handle.register_c_s_protocol_format(main_protocol_name, sub_protocol_id, sub_protocol.get(c_s_name), Callable(self, c_s_name))
	#local_server_protocol_handle.register_s_c_protocol_format(main_protocol_name, sub_protocol_id, sub_protocol.get(c_s_name), Callable(self, c_s_name))


func add_documents(documents=[], metadatas=[],ids=[],type="dynamic",persistent=false,space="main",uris=null):
	var data = {}
	data["documents"] = documents
	var cur_metadatas = []
	var json:JSON = JSON.new()
	for cur_data in metadatas:
		cur_metadatas.append(json.stringify(cur_data))
	data["metadatas"] = cur_metadatas
	data["ids"] = ids
	data["type"] = type
	data["persistent"] = persistent
	data["space"] = space
	data["uris"] = uris
	var result = await C_S_ADD_DOCUMENTS(-1, data)
	return result

## The method name has the same name as the sub protocol
func C_S_ADD_DOCUMENTS(server_syncId, content):
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_ADD_DOCUMENTS"),30)
	

## The method name has the same name as the sub protocol
func S_C_ADD_DOCUMENTS(server_syncId, content):
	pass


func delete_documents(ids=null, where=null,where_document=null,type="dynamic",persistent=false,space="main",uris=null):
	var data = {}
	data["ids"] = ids
	var json:JSON = JSON.new()
	data["where"] = json.stringify(where)
	data["where_document"] = json.stringify(where_document)
	data["type"] = type
	data["persistent"] = persistent
	data["space"] = space
	data["uris"] = uris
	var result = await C_S_DELETE_DOCUMENTS(-1, data)
	return result

## The method name has the same name as the sub protocol
func C_S_DELETE_DOCUMENTS(server_syncId, content):
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_DELETE_DOCUMENTS"),30)
	

## The method name has the same name as the sub protocol
func S_C_DELETE_DOCUMENTS(server_syncId, content):
	pass
	

func get_documents(ids=null, where=null,where_document=null,include=[],type="dynamic",persistent=false,space="main",uris=null):
	var data = {}
	data["ids"] = ids
	var json:JSON = JSON.new()
	data["where"] = json.stringify(where)
	data["where_document"] = json.stringify(where_document)
	data["include"] = include
	data["type"] = type
	data["persistent"] = persistent
	data["space"] = space
	data["uris"] = uris
	var result = await C_S_GET_DOCUMENTS(-1, data)
	return result

## The method name has the same name as the sub protocol
func C_S_GET_DOCUMENTS(server_syncId, content):
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_GET_DOCUMENTS"),30)
	

## The method name has the same name as the sub protocol
func S_C_GET_DOCUMENTS(server_syncId, content):
	pass

func query_documents(query_embeddings=null,query_texts=null,query_images=null,
		query_uris=null,n_results=10,where=null,where_document=null,include=null,
		type="dynamic",persistent=false,space="main",uris=null):
	var data = {}
	data["query_embeddings"] = query_embeddings
	var json:JSON = JSON.new()
	data["query_texts"] = query_texts
	data["query_images"] = query_images
	data["query_uris"] = query_uris
	data["n_results"] = n_results
	data["where"] = json.stringify(where)
	data["where_document"] = json.stringify(where_document)
	data["include"] = include

	data["type"] = type
	data["persistent"] = persistent
	data["space"] = space
	data["uris"] = uris
	var result = await C_S_QUERY_DOCUMENTS(-1, data)
	return result

## The method name has the same name as the sub protocol
func C_S_QUERY_DOCUMENTS(server_syncId, content):
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_QUERY_DOCUMENTS"),30)
	

## The method name has the same name as the sub protocol
func S_C_QUERY_DOCUMENTS(server_syncId, content):
	pass


func load_files(file_paths=[], type="dynamic", persistent=false, space="main"):
	var data = {}
	data["file_paths"] = file_paths
	data["type"] = type
	data["persistent"] = persistent
	data["space"] = space
	var result = await C_S_LOAD_FILES(-1, data)
	return result

## The method name has the same name as the sub protocol
func C_S_LOAD_FILES(server_syncId, content):
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_LOAD_FILES"),30)
	

## The method name has the same name as the sub protocol
func S_C_LOAD_FILES(server_syncId, content):
	pass


func unload_files(file_paths=[], type="dynamic", persistent=false, space="main"):
	var data = {}
	data["file_paths"] = file_paths
	data["type"] = type
	data["persistent"] = persistent
	data["space"] = space
	var result = await C_S_UNLOAD_FILES(-1, data)
	return result

## The method name has the same name as the sub protocol
func C_S_UNLOAD_FILES(server_syncId, content):
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_UNLOAD_FILES"),30)
	

## The method name has the same name as the sub protocol
func S_C_UNLOAD_FILES(server_syncId, content):
	pass

