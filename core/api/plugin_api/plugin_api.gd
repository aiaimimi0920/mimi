extends Node 
## 此插件为godot层插件，可以调用godot相应的服务，可以调用适配器服务
class_name PluginAPI

var plugin_path:String = ""

var plugin_file:String = ""

var plugin_info:Dictionary = {
	"id":"",## unique id
	"name":"",## name
	"author":"",## author
	"version":"",## version
	"description":"",## Introduction to plugins
	"type":"",## Optional options are service and plugin
	## Dependent plugin version, format like this {"ipfs_adapter":["v1_0_0","v2_0_0"],"aws_adapter":["v1_0_0"]}
	## Meaning Dependent on v1_0_0 to v2_0_0 ipfs_adapter and minimum version v1_0_0 aws_adapter
	"dependency":{},
}

var default_plugin_config:Dictionary = {}
var plugin_config:Dictionary = {}
var plugin_data:Dictionary = {}
var plugin_cache:Dictionary = {}
var plugin_event_dic:Dictionary = {}
var plugin_context_dic:Dictionary = {}
var plugin_keyword_dic:Dictionary = {}
var plugin_keyword_arr:Array = []
var plugin_timer:Timer = null
var plugin_time_passed:int = 0
var plugin_config_loaded:bool = false
var plugin_data_loaded:bool = false
var plugin_cache_loaded:bool = false
var plugin_api_methods = {}
var plugin_api_methods_init = false

func _init()->void:
	_on_init()
	

func _ready()->void:
	plugin_timer = Timer.new()
	plugin_timer.one_shot = false
	plugin_timer.wait_time = 1
	plugin_timer.process_callback = Timer.TIMER_PROCESS_PHYSICS
	plugin_timer.connect("timeout",_plugin_timer_timeout)
	add_child(plugin_timer)
	plugin_timer.start()
	
	_on_load()
	
	
func _exit_tree()->void:
	_on_unload()
	if plugin_data_loaded:
		save_plugin_data()
	if plugin_cache_loaded:
		save_plugin_cache()


## 在插件中覆盖此虚函数，以便定义将在此插件的文件被读取时执行的操作
## 必须在此处使用set_plugin_info函数来设置插件信息，插件才能被正常加载
## Overwrite this virtual function in the plugin to define the operation that will be performed when the file in this plugin is read
## must use set_plugin_info function in here to set plugin information, so that plugins can be loaded normally
## example：set_plugin_info(plugin_name,"plugin_name","mimi",plugin_version,"xxx","service",{})
func _on_init()->void:
	init_plugin_api_methods()
	pass

func init_plugin_api_methods():
	plugin_api_methods_init = true
	plugin_api_methods = PluginManager.create_plugin_api_methods(get_script())


## Overlay this virtual function in the plugin to define the actions that the plugin will perform after it is loaded
func _on_load()->void:
	pass


### Overlay this virtual function in the plugin to define the actions the plugin will perform after all other plugins have been loaded
### Note: If this plugin strongly depends on a certain plugin, it is recommended to register the dependent plugin in the plugin information to ensure that it is loaded correctly before this plugin
func _on_ready()->void:
	pass


## Overwrite this virtual function in the plugin to define the actions that will be executed every second during the plugin's runtime
func _on_process()->void:
	pass


## Overwrite this virtual function in the plugin to define the operation to be performed after detecting runtime errors
func _on_error()->void:
	pass



## Overwrite this virtual function in the plugin to define the actions the plugin will perform when it is about to be unload
func _on_unload()->void:
	pass


func _plugin_timer_timeout()->void:
	plugin_time_passed += 1
	_on_process()


func set_plugin_info(p_id:String,p_name:String,p_author:String,p_version:int,p_description:String,type:String,p_dependency:Variant={})->void:
	plugin_info.id = p_id.to_lower()
	plugin_info.name = p_name
	plugin_info.author = p_author
	plugin_info.version = p_version
	plugin_info.type = type
	plugin_info.description = p_description
	plugin_info.dependency = p_dependency


func get_plugin_info()->Dictionary:
	return plugin_info


func get_plugin_filename()->String:
	return plugin_file


func get_plugin_filepath()->String:
	return plugin_path


static func get_plugin_path()->String:
	return PluginManager.plugin_path



func get_plugin_runtime()->int:
	return plugin_time_passed
	

static func get_global_runtime()->int:
	return GlobalManager.global_run_time


func get_plugin_instance(plugin_id:String,version=-1)->PluginAPI:
	var ins:PluginAPI = await PluginManager.get_plugin_instance_by_script_name.bind(plugin_id, version, true).call()
	if ins == null:
		Logger.error("无法获取ID为%s的插件实例，可能是ID有误或插件未被加载；请检查依赖关系是否设置正确！" % [plugin_id])
	return ins


static func get_data_path()->String:
	return PluginManager.plugin_data_path
	

func get_data_filepath()->String:
	return PluginManager.plugin_data_path + plugin_info["id"] + ".rdb"
	

static func get_config_path()->String:
	return PluginManager.plugin_config_path
	

func get_config_filepath()->String:
	return PluginManager.plugin_config_path + plugin_info["id"] + ".json"
	

static func get_cache_path()->String:
	return PluginManager.plugin_cache_path
	
	
func get_cache_filepath()->String:
	return PluginManager.plugin_cache_path + plugin_info["id"] + ".rca"


## Used to check if the configuration file properties corresponding to the plugin have been loaded
func is_config_loaded()->bool:
	return plugin_config_loaded
	

## Used to check if the database file properties corresponding to the plugin have been loaded
func is_data_loaded()->bool:
	return plugin_data_loaded


## Used to check if the cache database file properties corresponding to the plugin have been loaded
func is_cache_loaded()->bool:
	return plugin_cache_loaded


static func get_last_errors()->PackedStringArray:
	return GlobalManager.last_errors


## The dictionary used to directly replace the loaded cache database is the specified dictionary, 
## which facilitates operations in the form of a dictionary. The cache database file needs to be initialized before this function can be used
## The last optional parameter is used to specify whether to immediately save changes to the cached database file while setting
func set_plugin_cache_metadata(dic:Dictionary,save_file:bool=true)->int:
	if !plugin_cache_loaded:
		Logger.error("Failed to set cache database properties. Please initialize the cache database before performing this operation")
		return ERR_DATABASE_CANT_WRITE
	plugin_cache = dic
	if save_file:
		save_plugin_cache()
	return OK


## The database file used to initialize the plugin and load it into memory for subsequent operations on its properties
## For the storage of configurations, it is recommended to use the plugin configuration function to specify default configurations and configuration instructions,
## and to be able to edit and change them using a regular editor
## When executing this function, it will check if the corresponding database file for this plugin already exists, 
## otherwise a new blank database file (. rdb format) will be created
func init_plugin_data()->int:
	if plugin_data_loaded:
		Logger.error("The plugin database has been loaded, therefore it cannot be initialized!")
		return ERR_ALREADY_IN_USE
	Logger.info("Loading plugin database")
	var data_path:String = PluginManager.get_plugin_data_path(plugin_info["id"])
	if FileAccess.file_exists(data_path):
		var file:FileAccess = FileAccess.open(data_path,FileAccess.READ)
		var _data = file.get_var(true) if file else null
		if _data is Dictionary:
			plugin_data = _data
			plugin_data_loaded = true
			Logger.info("Successfully loaded plugin database")
			return OK
		else:
			Logger.error("Plugin database read failed, please delete and regenerate! Path:"+data_path)
			return ERR_DATABASE_CANT_READ
	else:
		Logger.info("There are no existing database files, generating new database files")
		var file:FileAccess = FileAccess.open(data_path,FileAccess.WRITE)
		if !file:
			Logger.error("Database file creation failed, please check if the file permissions are configured correctly! Path:"+data_path)
			return FileAccess.get_open_error()
		else:
			file.store_var(plugin_data,true)
			plugin_data_loaded = true
			Logger.info("Database file creation successful, path: "+data_path)
			Logger.info("If any database file changes occur, please reload this plugin")
			return OK
			

## Used to save data in memory to a database file. The database file needs to be initialized before this function can be used
func save_plugin_data()->int:
	if !plugin_data_loaded:
		Logger.error("Database file save failed. Please initialize the database before performing this operation")
		return ERR_DATABASE_CANT_WRITE
	Logger.info("Saving plugin database")
	var data_path:String = PluginManager.get_plugin_data_path(plugin_info["id"])
	var file:FileAccess = FileAccess.open(data_path,FileAccess.WRITE)
	if !file:
		Logger.error("Database file save failed, please check if the file permissions are configured correctly! Path:"+data_path)
		return FileAccess.get_open_error()
	else:
		file.store_var(plugin_data,true)
		Logger.info("Database file saved successfully, path:"+data_path)
		return OK
		

## Used to retrieve the properties corresponding to the specified key from a loaded database. The database file needs to be initialized before this function can be used
func get_plugin_data(key)->Variant:
	if !plugin_data_loaded:
		Logger.error("Database property acquisition failed. Please initialize the database before performing this operation!")
		return null
	if plugin_data.has(key):
		return plugin_data[key]
	else:
		Logger.error("Database property acquisition failed, the key attempted to obtain does not exist in the plugin database!")
		return null
		

## Used to check the existence of a specified key from a loaded database. The database file needs to be initialized before this function can be used	
func has_plugin_data(key)->bool:
	if !plugin_data_loaded:
		Logger.error("Database property acquisition failed. Please initialize the database before performing this operation!")
		return false
	return plugin_data.has(key)
		

## Used to set the corresponding properties of a specified key in a loaded database. The database file needs to be initialized before this function can be used
## The last optional parameter is used to specify whether to immediately save changes to the database file while setting
func set_plugin_data(key,value,save_file:bool=true)->int:
	if !plugin_data_loaded:
		Logger.error("Database property setting failed. Please initialize the database before performing this operation!")
		return ERR_DATABASE_CANT_WRITE
	plugin_data[key]=value
	if save_file:
		save_plugin_data()
	return OK


## Used to delete a specified key and its corresponding properties from a loaded database. The database file needs to be initialized before this function can be used
## The last optional parameter is used to specify whether to immediately save changes to the database file while deleting
func remove_plugin_data(key,save_file:bool=true)->int:
	if !plugin_data_loaded:
		Logger.error("Database attribute deletion failed. Please initialize the database before performing this operation!")
		return ERR_DATABASE_CANT_WRITE
	if plugin_data.has(key):
		plugin_data.erase(key)
		if save_file:
			save_plugin_data()
		return OK
	else:
		Logger.error("Database attribute deletion failed, attempting to delete key that does not exist in the plugin database!")
		return ERR_DATABASE_CANT_WRITE
		

## Used to clear all properties in a loaded database. The database file needs to be initialized before this function can be used
## The last optional parameter is used to specify whether to immediately save changes to the database file while clearing
func clear_plugin_data(save_file:bool=true)->int:
	if !plugin_data_loaded:
		Logger.error("Database property clearing failed. Please initialize the database before performing this operation!")
		return ERR_DATABASE_CANT_WRITE
	plugin_data.clear()
	if save_file:
		save_plugin_data()
	return OK


func init_plugin_cache()->int:
	if plugin_cache_loaded:
		Logger.error("The plugin cache database has been loaded, so it cannot be initialized!")
		return ERR_ALREADY_IN_USE
	Logger.info("Loading plugin cache database")
	var data_path:String = PluginManager.get_plugin_cache_path(plugin_info["id"])
	if FileAccess.file_exists(data_path):
		var file:FileAccess = FileAccess.open(data_path,FileAccess.READ)
		var _data = file.get_var(true) if file else null
		if _data is Dictionary:
			plugin_cache = _data
			plugin_cache_loaded = true
			Logger.info("Successfully loaded plugin cache database")
			return OK
		else:
			Logger.error("Plugin cache database read failed, please delete and regenerate! Path:"+data_path)
			return ERR_DATABASE_CANT_READ
	else:
		Logger.info("There are no existing cache database files, generating new cache database files")
		var file:FileAccess = FileAccess.open(data_path,FileAccess.WRITE)
		if !file:
			Logger.error("Cache database file creation failed, please check if the file permissions are configured correctly! Path:"+data_path)
			return FileAccess.get_open_error()
		else:
			file.store_var(plugin_cache,true)
			plugin_cache_loaded = true
			Logger.info("Cache database file creation successful, path: "+data_path)
			Logger.info("If any cache database file changes occur, please reload this plugin")
			return OK
			

## Used to save cached data in memory to a database file, which needs to be initialized before using this function
func save_plugin_cache()->int:
	if !plugin_cache_loaded:
		Logger.error("Cache database file save failed. Please initialize the cache database before performing this operation")
		return ERR_DATABASE_CANT_WRITE
	Logger.info("Saving plugin cache database")
	var data_path:String = PluginManager.get_plugin_cache_path(plugin_info["id"])
	var file:FileAccess = FileAccess.open(data_path,FileAccess.WRITE)
	if !file:
		Logger.error("Cache database file save failed, please check if the file permissions are configured correctly! Path:"+data_path)
		return FileAccess.get_open_error()
	else:
		file.store_var(plugin_cache,true)
		Logger.info("Cache database file saved successfully, path:"+data_path)
		return OK
		

## Used to retrieve the properties corresponding to the specified key from the loaded cache database. The cache database file needs to be initialized before this function can be used
func get_plugin_cache(key)->Variant:
	if !plugin_cache_loaded:
		Logger.error("Failed to obtain cache database properties. Please initialize the cache database before performing this operation!")
		return null
	if plugin_cache.has(key):
		return plugin_cache[key]
	else:
		Logger.error("Failed to obtain cache database properties. The key attempted to obtain does not exist in the plugin cache database!")
		return null
		

## Used to check the existence of a specified key from a loaded cache database. The cache database file needs to be initialized before this function can be used
func has_plugin_cache(key)->bool:
	if !plugin_cache_loaded:
		Logger.error("Failed to retrieve cache database properties. Please initialize the database before performing this operation!")
		return false
	return plugin_cache.has(key)
		

## Used to set the corresponding properties of the specified key in the loaded cache database. The cache database file needs to be initialized before this function can be used
## The last optional parameter is used to specify whether to immediately save changes to the cached database file while setting
func set_plugin_cache(key,value,save_file:bool=true)->int:
	if !plugin_cache_loaded:
		Logger.error("Failed to set cache database properties. Please initialize the cache database before performing this operation!")
		return ERR_DATABASE_CANT_WRITE
	plugin_cache[key]=value
	if save_file:
		save_plugin_cache()
	return OK


## Used to delete a specified key and its corresponding properties from a loaded cache database. The cache database file needs to be initialized before this function can be used
## The last optional parameter is used to specify whether to immediately save changes to the cached database file while deleting
func remove_plugin_cache(key,save_file:bool=true)->int:
	if !plugin_cache_loaded:
		Logger.error("Failed to delete cache database properties. Please initialize the cache database before performing this operation!")
		return ERR_DATABASE_CANT_WRITE
	if plugin_cache.has(key):
		plugin_cache.erase(key)
		if save_file:
			save_plugin_cache()
		return OK
	else:
		Logger.error("Failed to delete cache database properties. The key attempting to delete does not exist in the plugin cache database!")
		return ERR_DATABASE_CANT_WRITE
		

## Used to clear all properties in the loaded cache database. The cache database file needs to be initialized before this function can be used
## The last optional parameter is used to specify whether to immediately save changes to the cached database file while clearing
func clear_plugin_cache(save_file:bool=true)->int:
	if !plugin_cache_loaded:
		Logger.error("Failed to clear cache database properties. Please initialize the cache database before performing this operation!")
		return ERR_DATABASE_CANT_WRITE
	plugin_cache.clear()
	if save_file:
		save_plugin_cache()
	return OK


## After calling this function, the plugin will attempt to uninstall itself
## If this plugin is dependented on other plugins, uninstallation may fail
func unload_plugin()->void:
	PluginManager.unload_plugin(self)


func load_scene(path:String,for_capture:bool=false)->Node:
	Logger.info("Attempting to load scene file:% s"% path)
	var _scene:PackedScene = await GlobalManager.load_threaded(path)
	if is_instance_valid(_scene) and _scene.can_instantiate():
		var _ins:Node = _scene.instantiate()
		if for_capture:
			var _v_port:SubViewport = SubViewport.new()
			_v_port.render_target_update_mode = SubViewport.UPDATE_DISABLED
			add_child(_v_port)
			_v_port.add_child(_ins)
			_ins.connect("tree_exited",_v_port.queue_free)
			Logger.info("Successfully loaded the scene file and prepared for image acquisition of its properties: %s"% path)
		else:
			add_child(_ins)
			Logger.info("Successfully loaded the scene file and added it as a child of the plugin for future use: %s"% path)
		return _ins
	else:
		Logger.error("Unable to load scene file% s. Please check if the path and file are correct, or try re importing resources in the plugin menu!"% path)
		return null


func get_scene_image(scene:Node,size:Vector2i,stretch_size:Vector2i=Vector2i.ZERO,transparent:bool=false)->Image:
	if !is_instance_valid(scene):
		Logger.error("The specified scene is invalid, therefore an image cannot be generated based on its attributes!")
		return null
	await get_tree().process_frame
	var _v_port:SubViewport = scene.get_parent()
	if !is_instance_valid(_v_port) or !(_v_port is SubViewport):
		Logger.error("Unable to generate image based on the specified scene, please ensure that this scene is generated through load_ The scene() function was loaded, and for was enabled in the function during for_capture parameter!")
		return null
	if (size.x < 0 or size.y < 0) or (stretch_size.x < 0 or stretch_size.y < 0):
		Logger.error("Unable to generate an image based on the specified scene because the size passed in or stretched cannot be less than (0,0)!")
		return null
	_v_port.transparent_bg = transparent
	_v_port.size = Vector2i.ZERO
	_v_port.size = size
	_v_port.render_target_update_mode = SubViewport.UPDATE_ONCE
	await get_tree().process_frame
	var img:Image = _v_port.get_texture().get_image()
	if is_instance_valid(img):
		if stretch_size != Vector2i.ZERO:
			img.resize(stretch_size.x,stretch_size.y,Image.INTERPOLATE_LANCZOS)
			Logger.info("Successfully generated image based on attributes in the specified scene! Size:%s, stretch size:%s, background transparency state:%s"% [_v_port.size,stretch_size,"enable" if _v_port.transparent_bg else "disable"])
		else:
			Logger.info("Successfully generated image based on attributes in the specified scene! Size:% s, background transparency status:% s"% [_v_port.size,"enable" if _v_port.transparent_bg else "disable"])
		return img
	else:
		if stretch_size != Vector2i.ZERO:
			Logger.error("Unable to generate an image based on the attributes in the specified scene. Please check if the parameters passed in are correct! (Size:%s, stretch size:% s, background transparency state:%s)"% [_v_port.size,stretch_size,"enable" if _v_port.transparent_bg else "disable"])
		else:
			Logger.error("Unable to generate an image based on the attributes in the specified scene. Please check if the parameters passed in are correct! (Size:%s, background transparency status:%s)"% [_v_port.size,"enable" if _v_port.transparent_bg else "disable"])
		return null
	

func get_absolute_path(file):
	return get_script().resource_path.get_base_dir().path_join(file)

func call_from_dict(call_name, call_dict, cur_message=null, cur_result=true):
	printt("call_from_dict",call_name,call_dict)
	
	if plugin_api_methods_init == false:
		init_plugin_api_methods()
		pass
	if not call_name in plugin_api_methods:
		return 
	var cur_arguments = {}
	var all_param = plugin_api_methods[call_name].get("parameters",{})
	var cur_call_dict = {}
	for key in call_dict:
		cur_call_dict[key.to_lower()] = call_dict[key]
	
	## If it is a message, it will be converted to the form of a dictionary. 
	## Of course, you can directly obtain the original message in the corresponding plugin for custom processing
	var call_data_dict
	if cur_message is ConversationMessageAPI:
		call_data_dict = cur_message.to_dict()
	else:
		call_data_dict = cur_message
	
	if call_data_dict:
		for key in call_data_dict:
			cur_call_dict[key.to_lower()] = call_data_dict[key]
	
	var max_index = 0
	for param_name in all_param:
		var cur_param_data
		if param_name.to_lower() in cur_call_dict:
			cur_param_data = cur_call_dict[param_name.to_lower()]
		else:
			cur_param_data = all_param[param_name]["default_value"]
		
		
		match all_param[param_name]["type"].to_lower():
			"int":
				cur_param_data = type_convert(cur_param_data, TYPE_INT)
			"float":
				cur_param_data = type_convert(cur_param_data, TYPE_FLOAT)
			"string":
				cur_param_data = cur_param_data
			"bool":
				cur_param_data = type_convert(cur_param_data.to_lower(), TYPE_BOOL)
			_:
				cur_param_data = str_to_var(cur_param_data)
		cur_arguments[all_param[param_name]["index"]] = cur_param_data
		max_index = max(max_index, all_param[param_name]["index"]+1)
	
	var result_arguments = []
	for i in range(max_index):
		result_arguments.append(cur_arguments[i])
	
	printt("want_call",call_name, result_arguments)
	callv(call_name, result_arguments)
	printt("call_finish")


func is_service_connected()->bool:
	return true

func is_ready()->bool:
	if is_service_connected():
		return true
	return true

func get_ui_instance():
	return null
