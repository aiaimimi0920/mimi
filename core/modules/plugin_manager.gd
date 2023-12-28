extends Node

var user_path:String = OS.get_user_data_dir()
var globalize_user_path:String = ProjectSettings.globalize_path(user_path)

var globalize_executable_root_path:String = OS.get_executable_path().get_base_dir()

var plugin_pck_name = "plugin.pck"
var plugin_main_name = "main.gd"

## Service plugin address, The plugin will adapt to external services to the Godot engine.
## Stored in user://, loaded in res://
## store format: 
## 1. user://external_service_plugin/plugin_name/version/external_service/main.exe
## 2. user://external_service_plugin/plugin_name/version/external_service_adapter/plugin.pck
## 
## when coding the file path is res://external_service_adapter/plugin_name
## When packing, it will automatically packing res://external_service_adapter/plugin_name to plugin.pck
## then send res://external_service/plugin_name and plugin.pck to Cloud storage provider
## When obtaining the plugin package, the external_ Service, external_ Service_ Adapters are placed in their respective folders
## then will use load_resource_pac load plugin.pck, you can use the plugin
var external_service_plugin_name:String = "external_service_plugin" 
var external_service_plugin_path:String = user_path.path_join(external_service_plugin_name)
var globalize_external_service_plugin_path:String = globalize_user_path.path_join(external_service_plugin_name)

## External service exe address, which is the package address of the external service, such as in Java format, Python format, etc., stored in user://
var external_service_name:String = "external_service"

## Obtain the working directory address of the external service package for the plugin
## user://external_service_plugin/plugin_name/version/external_service
func get_external_service_dir_path(cur_plugin_name,version)->String:
	return external_service_plugin_path.path_join(cur_plugin_name).path_join(get_version_str_by_num(version)).path_join(external_service_name)

## Obtain the absolute address of the working directory for the external service package of the plugin, 
## which is the actual working directory address when use the child process
func get_globalize_external_service_dir_path(cur_plugin_name,version)->String:
	return ProjectSettings.globalize_path(get_external_service_dir_path(cur_plugin_name,version))

## External service adapter address, which is the adapter address of the external service. The code is in gd format, stored in user://, and loaded in res://
var external_service_adapter_name:String = "external_service_adapter"

## Obtain the PCK file address of the external service adapter package for the plugin, user://external_service_plugin/plugin_name/version/external_service_adapter/plugin.pck
func get_external_service_adapter_pck_path(cur_plugin_name,version)->String:
	return external_service_plugin_path.path_join(cur_plugin_name).path_join(get_version_str_by_num(version)).path_join(external_service_adapter_name).path_join(plugin_pck_name)

## Obtain the absolute address of the PCK file for the external service adapter package of the plugin, 
## which is mainly passed to the file_list plugin to store data here
func get_globalize_external_service_adapter_pck_path(cur_plugin_name,version)->String:
	return ProjectSettings.globalize_path(get_external_service_adapter_pck_path(cur_plugin_name,version))

## Obtain the file directory of the external service adapter package for the plugin, res://external_service_adapter
var res_external_service_adapter_dir_path:String = "res://".path_join(external_service_adapter_name)

## Obtain the file address of the external service adapter package for the plugin, res://external_service_adapter/plugin_name/version
func get_res_external_service_adapter_path(cur_plugin_name,version)->String:
	return res_external_service_adapter_dir_path.path_join(cur_plugin_name).path_join(get_version_str_by_num(version))

func get_res_external_service_adapter_main_path(cur_plugin_name,version)->String:
	return get_res_external_service_adapter_path(cur_plugin_name,version).path_join(plugin_main_name)

## Obtain the file directory of the external service package for the plugin, res://external_service
var res_external_service_dir_path:String = "res://".path_join(external_service_name)


## Obtain the file address of the external service package for the plugin, res://external_service/plugin_name/version
func get_res_external_service_path(cur_plugin_name,version)->String:
	return res_external_service_dir_path.path_join(cur_plugin_name).path_join(get_version_str_by_num(version))

## Obtain the absolute address of the file for the external service package of the plugin, 
## which is mainly passed to the file_list plugin to store data here
func get_globalize_res_external_service_path(cur_plugin_name,version)->String:
	return ProjectSettings.globalize_path(get_res_external_service_path(cur_plugin_name,version))


## The script plugin address is mainly the code that calls the service, as a service may be used by multiple plugins simultaneously, so the service and plugin are processed separately
## The storage format is
## 1. user://plugin/plugin_name/plugin.pck
## when coding : res://plugin/plugin_name
## When packing, it will automatically packing res://plugin/plugin_name to plugin.pck
## then send plugin.pck to Cloud storage provider
## When obtaining the plugin package, the pck will storage in user://plugin/plugin_name/
## then will use load_resource_pac load plugin.pck, you can use the plugin
var plugin_name:String = "plugin"
var plugin_path:String = user_path.path_join(plugin_name)
var globalize_plugin_path:String = ProjectSettings.globalize_path(plugin_path)
## Obtain the PCK file address of the plugin package, user://plugin/plugin_name/version/plugin.pck
func get_plugin_pck_path(cur_plugin_name,version)->String:
	return plugin_path.path_join(cur_plugin_name).path_join(get_version_str_by_num(version)).path_join(plugin_pck_name)

## Obtain the absolute address of the PCK file for the external service adapter package of the plugin, 
## which is mainly passed to the file_list plugin to store data here
func get_globalize_plugin_pck_path(cur_plugin_name,version)->String:
	return ProjectSettings.globalize_path(get_plugin_pck_path(cur_plugin_name,version))

## Obtain the file directory of the plugin, res://plugin
var res_plugin_dir_path:String = "res://".path_join(plugin_name)

## Obtain the file address of the plugin, res://plugin/plugin_name
func get_res_plugin_path(cur_plugin_name)->String:
	return res_plugin_dir_path.path_join(cur_plugin_name)

func get_res_plugin_main_path(cur_plugin_name,version)->String:
	return get_res_plugin_path(cur_plugin_name).path_join(get_version_str_by_num(version)).path_join(plugin_main_name)

var plugin_config_name:String = "plugin_config"
var plugin_config_path:String = user_path.path_join(plugin_config_name)
var globalize_plugin_config_path:String = ProjectSettings.globalize_path(plugin_config_path)
func get_plugin_config_path(cur_plugin_name)->String:
	return plugin_config_path.path_join(cur_plugin_name)+".cfg"

var plugin_data_name:String = "plugin_data"
var plugin_data_path:String = user_path.path_join(plugin_data_name)
var globalize_plugin_data_path:String = ProjectSettings.globalize_path(plugin_data_path)
func get_plugin_data_path(cur_plugin_name)->String:
	return plugin_data_path.path_join(cur_plugin_name)+".rdb"

var plugin_file_name:String = "plugin_file"
var plugin_file_path:String = user_path.path_join(plugin_file_name)
var globalize_plugin_file_path:String = ProjectSettings.globalize_path(plugin_file_path)
func get_plugin_file_dir_path(cur_plugin_name)->String:
	return plugin_file_path.path_join(cur_plugin_name)

func get_globalize_plugin_file_dir_path(cur_plugin_name)->String:
	return globalize_plugin_file_path.path_join(cur_plugin_name)

var plugin_cache_name:String = "plugin_cache"
var plugin_cache_path:String = user_path.path_join(plugin_cache_name)
var globalize_plugin_cache_path:String = ProjectSettings.globalize_path(plugin_cache_path)
func get_plugin_cache_path(cur_plugin_name)->String:
	return plugin_cache_path.path_join(cur_plugin_name)+".rca"


var plugin_log_name:String = "plugin_log"
var plugin_log_path:String = user_path.path_join(plugin_log_name)
var globalize_plugin_log_path:String = ProjectSettings.globalize_path(plugin_log_path)
func get_plugin_log_path(cur_plugin_name)->String:
	return plugin_log_path.path_join(cur_plugin_name)+".log"

var default_plugin_info:Dictionary = {
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

var loaded_scripts:Dictionary = {}
var plugin_load_status:Dictionary = {}
var plugin_event_dic:Dictionary = {}
var plugin_directories_dic:Dictionary = {}
var plugin_directories_arr:Array = []

signal plugin_list_changed()

var init_path:Array = [
	plugin_config_path,
	plugin_data_path,
	plugin_cache_path,
	plugin_log_path,
	plugin_file_path,
]

func _init_dir()->void:
	for p in init_path:
		if !DirAccess.dir_exists_absolute(p):
			DirAccess.make_dir_absolute(p)


var init_plugin_path:Array = [
	#get_plugin_config_path,
	get_plugin_data_path,
	get_plugin_cache_path,
	get_plugin_log_path,
	get_plugin_file_dir_path,
]
func _init_plugin_dir(cur_plugin_name:String)->void:
	for p in init_plugin_path:
		var cur_path = p.call(cur_plugin_name)
		if cur_path.get_extension() == "":
			if !DirAccess.dir_exists_absolute(cur_path):
				DirAccess.make_dir_absolute(cur_path)
		else:	
			if !DirAccess.dir_exists_absolute(cur_path.get_base_dir()):
				DirAccess.make_dir_absolute(cur_path.get_base_dir())
		FileAccess.open(cur_path, FileAccess.WRITE)



func load_plugin_script(dir:String)->GDScript:
	var result_path = dir
	if dir.get_extension() == "":
		result_path = dir.path_join(plugin_main_name)

	if FileAccess.file_exists(result_path):
		var _script:GDScript
		if !loaded_scripts.has(result_path):
			_script = load(result_path)
			loaded_scripts[result_path]=_script
		else:
			_script = loaded_scripts[result_path]
		return _script
	else:
		return	


func load_plugin_by_name_version(cur_plugin_name,cur_plugin_version=-1,files_dic:Dictionary={},source:String=""):
	if cur_plugin_version == -1:
		## Obtain the maximum version of the plugin
		var cur_plugin_base_dir = get_plugin_base_dir_by_plugin_name(cur_plugin_name)
		if cur_plugin_base_dir == "":
			## There is no local version, download one now
			var download_version = await get_plugin("update_bot").download_load_plugin_pck(cur_plugin_name)
			return await load_plugin_by_name_version(cur_plugin_name,cur_plugin_version,files_dic,source)
		var cur_plugin_version_base_dir = PluginManager.get_big_version_folder(cur_plugin_base_dir,true)
		cur_plugin_version = get_version_by_str(cur_plugin_version_base_dir.get_file())

	var file_dir = get_plugin_dir_by_plugin_name(cur_plugin_name,cur_plugin_version)
	if file_dir == "":
		## There is no local version, download one now
		printt("download plugin ",cur_plugin_name)
		var download_version = await get_plugin("update_bot").download_load_plugin_pck(cur_plugin_name, cur_plugin_version, cur_plugin_version)
		printt("download plugin finish", cur_plugin_name, download_version)
		return await load_plugin_by_name_version(cur_plugin_name, download_version, files_dic, source)
	return await load_plugin(file_dir,files_dic,source)


func load_plugin(file:String,files_dic:Dictionary={},source:String="")->int:
	Logger.info("Attempting to load plugin file: " + file)
	if not file.is_absolute_path():
		## If using the plugin name for loading, concatenate the appropriate plugin name and version number
		return await load_plugin_by_name_version(file,-1,files_dic,source)
	var _f_dic:Dictionary
	if !files_dic.is_empty():
		_f_dic = files_dic
	else:
		_f_dic = get_plugin_directories_dic()
	for _id in _f_dic:
		for version in _f_dic[_id]:
			var _f = _f_dic[_id][version]
			if _f.dir == file:
				var _info:Dictionary = _f.info
				var _dependency:Dictionary = _info.get("dependency",{})
				var _inst_dic:Dictionary = get_plugin_instance_dic()
				if _inst_dic.has(_info.id.to_lower()+"_"+str(get_version_by_str(_info.version)).to_lower()):
					Logger.info("Unable to load plugin file: " + file)
					Logger.info("A plugin with the same ID has already been loaded:"+str(_id))
					return ERR_ALREADY_EXISTS
				for _dep in _dependency:
					var dep_version = _dependency[_dep]
					var min_version:int = 0
					var max_version:int = 1000000000
					if len(dep_version)==1:
						min_version = get_version_by_str(dep_version[0])
					elif len(dep_version)==2:
						min_version = get_version_by_str(dep_version[0])
						max_version = get_version_by_str(dep_version[1])

					var inst_dic_keys = _inst_dic.keys()
					var have_plugin = false
					for inst_dic_key in inst_dic_keys:
						if inst_dic_key.begins_with(_dep.to_lower()):
							var cur_version = inst_dic_key.trim_prefix(_dep.to_lower()+"_")
							cur_version = int(cur_version)
							if cur_version<=max_version and cur_version>=min_version:
								have_plugin = true
								break
					if have_plugin:
						continue
					if _id.to_lower() == _dep.to_lower():
						Logger.info("Unable to load plugin file: " + file)
						Logger.info("This plugin sets itself as the required dependency plugin!")
						return ERR_CYCLIC_LINK
					if source.to_lower() == _dep.to_lower():
						Logger.info("Unable to load plugin file: " + file)
						Logger.info("This plugin has a circular dependency with the following plugins: "+str(source))
						return ERR_CYCLIC_LINK
					
					if _f_dic.has(_dep.to_lower()):
						var version_array = _f_dic[_dep.to_lower()].keys()
						version_array.sort()
						version_array.reverse()
						var find_dep_version = false
						for cur_version in version_array:
							if cur_version<=max_version and cur_version>=min_version:
								var dep_dir = _f_dic[_dep.to_lower()][cur_version].dir
								if (!plugin_load_status.has(dep_dir)) || (plugin_load_status[dep_dir] != false):
									Logger.info("Attempting to load the required dependent plugins for this plugin:" + _dep)
									await load_plugin(dep_dir,_f_dic,_id)
									await get_tree().process_frame
									if (!plugin_load_status.has(dep_dir)) || (plugin_load_status[dep_dir] == false):
										Logger.info("Unable to load plugin file: " + file)
										Logger.error("The dependent plugin required for this plugin failed to load: "+_dep)
										continue
									## Indicates successful loading
									find_dep_version = true
									break
						
						if find_dep_version:
							continue

					## Other situations indicate that there are no local dependency plugins that meet the version requirements
					## try download
					var update_bot_plugin = await get_plugin_instance_by_script_name("update_bot")
					var download_version = await update_bot_plugin.download_load_plugin_pck(_dep,min_version,max_version)
					_f_dic.merge(get_plugin_directories_dic(),true)

					await load_plugin(get_plugin_dir_by_plugin_name(_id,download_version),_f_dic,_id)
					await get_tree().process_frame

					
				var plugin_res:GDScript = load_plugin_script(file)
				_init_plugin_dir(_id)
				var plugin_ins:PluginAPI = plugin_res.new()
				var _plugin_info:Dictionary = plugin_ins.get_plugin_info()

				plugin_ins.name = _plugin_info["id"].to_lower()+"_"+str(get_version_by_str(_info.version)).to_lower()
				plugin_ins.plugin_path = file
				plugin_ins.plugin_file = file.path_join(plugin_main_name)
				plugin_ins.add_to_group("PluginAPI")
				add_child(plugin_ins,true)
				plugin_load_status[file] = true
				plugin_list_changed.emit()
				Logger.info("Successfully loaded plugin: " +get_beautify_plugin_info(_plugin_info))
				return OK
	return ERR_BUG

func clear_plugin_directories_dic():
	plugin_directories_dic.clear()
	plugin_directories_arr.clear()
	plugin_load_status.clear()
	plugin_list_changed.emit()



func get_plugin_directories_dic()->Dictionary:
	Logger.info("Start scanning plugin directory")
	var plugin_directories = _list_directories_in_directory(res_plugin_dir_path)
	var external_service_adapter_directories = _list_directories_in_directory(res_external_service_adapter_dir_path)
	# plugin_load_status.clear()
	# plugin_directories_dic.clear()
	plugin_directories_arr.clear()
	if plugin_directories.size() == 0 and external_service_adapter_directories.size()==0:
		## 删除所有的插件
		plugin_load_status.clear()
		plugin_directories_dic.clear()
		plugin_list_changed.emit()
		Logger.info("No plugins found in the plugin directory")
		return {}
	
	var all_directories = {}
	all_directories.merge(plugin_directories)
	all_directories.merge(external_service_adapter_directories)
	
	for _dir in all_directories:
		var _id:String = ""
		for version in all_directories[_dir]:
			var dir_key_path = _dir.path_join(get_version_str_by_num(version))
			## Properties that have already been loaded will no longer be loaded, 
			## meaning that specific information such as info will not be updated. 
			## If loading is required, please clear all properties before loading
			if dir_key_path in plugin_load_status:
				continue
			var _plugin_info:Dictionary = get_plugin_dir_info(dir_key_path)
			## plugin_load_status[dir_key_path] == false indicates that the plugin is damaged and cannot be loaded
			if _plugin_info.is_empty():
				plugin_load_status[dir_key_path] = false
				continue
			_id = _plugin_info.id.to_lower()
			## If the plugin file corresponding to a certain ID has already been loaded, the latest plugin marked cannot be loaded
			if plugin_directories_dic.has(_id) and plugin_directories_dic[_id].has(version) and plugin_directories_dic[_id][version]["dir"]!=dir_key_path:
				plugin_load_status[dir_key_path] = false
				Logger.error("Unable to read plugin file: %s(%s)"%[_dir,version])
				Logger.error("A plugin file with ID "+str (_id)+" already exists:"+str(plugin_directories_dic[_id][version].dir))
				continue
			if _id not in plugin_directories_dic:
				plugin_directories_dic[_id] = {}
				
			plugin_directories_dic[_id][version] = {"dir":dir_key_path,"info":_plugin_info}
		
		if _id!="":
			var version_list = plugin_directories_dic[_id].keys()
			version_list.sort()
			var _plugin_info:Dictionary = plugin_directories_dic[_id][version_list.back()].info
			## Only plugins of type plugin are displayed in the list, and the highest version is used. Basic service plugins are not displayed
			if _plugin_info.type == "plugin":
				plugin_directories_arr.append({
					"id":_plugin_info.id,
					"version":_plugin_info.version,
					"name":_plugin_info.name,
					"description":_plugin_info.description,
					})
	plugin_list_changed.emit()
	Logger.info("Plugin directory scan completed!")
	return plugin_directories_dic


func _list_directories_in_directory(path:String):
	if !DirAccess.dir_exists_absolute(path):
		DirAccess.make_dir_recursive_absolute(path)
		Logger.info("The plugin directory does not exist, a new plugin directory has been created!")
	var dir:DirAccess = DirAccess.open(path)
	var info_map = {}
	if dir:
		var dir_list:PackedStringArray = dir.get_directories()
		for i in range(dir_list.size()):
			var version_list = dir.get_directories_at(path.path_join(dir_list[i]))
			var cur_version_list = []
			for version in version_list:
				cur_version_list.append(get_version_by_str(version))
			info_map[path.path_join(dir_list[i])] = cur_version_list
	return info_map

func get_plugin_dir_info(dir:String)->Dictionary:
	var plugin_res:GDScript = load_plugin_script(dir)
	for child in get_children():
		if child.get_script() == plugin_res:
			return child.get_plugin_info()
	
	if !is_instance_valid(plugin_res) || not (plugin_res.reload() in [OK,ERR_ALREADY_IN_USE]):
		Logger.error("Unable to read plugin file: " + dir)
		Logger.error("This file does not exist, is not a plugin file, or is damaged")
		Logger.error("If the file is confirmed to be correct, please check if there are any errors in the plugin script!")
		return {}
	
	var plugin_ins:PluginAPI = plugin_res.new()
	if is_instance_valid(plugin_ins):
		var _plugin_info:Dictionary = plugin_ins.get_plugin_info()
		plugin_ins.queue_free()
		if _plugin_info.has_all(default_plugin_info.keys()):
			var err_arr:Array = []
			for key in _plugin_info:
				if (typeof(_plugin_info[key])==TYPE_STRING) and (_plugin_info[key] == ""):
					err_arr.append(key)
			if !err_arr.is_empty():
				Logger.error("Unable to read plugin file: " + dir)
				Logger.error("The following plugin information in this file cannot be empty: "+str(err_arr))
				return {}
			return _plugin_info
		else:
			Logger.error("Unable to read plugin file: " + dir)
			Logger.error("The plugin information in this file is missing")
			return {}
	else:
		Logger.error("Unable to read plugin file: " + dir)
		Logger.error("This file does not exist, is not a plugin file, or is damaged")
		Logger.error("If the file is confirmed to be correct, please check if there are any errors in the plugin script!")
		return {}
	
func get_plugin_instance_dic()->Dictionary:
	var _plugin_dic:Dictionary = {}
	for child in get_children():
		_plugin_dic[str(child.name).to_lower()]=child
	return _plugin_dic

func get_plugin(cur_plugin_name,version=-1)->PluginAPI:
	var _plugin_dic = get_plugin_instance_dic()
	if version == -1:
		## 获得最大版本的插件
		var _plugin_dic_keys = _plugin_dic.keys()
		var node_version_map = {}
		for cur_key in _plugin_dic_keys:
			if cur_key.begins_with(cur_plugin_name.to_lower()):
				var cur_version = cur_key.trim_prefix(cur_plugin_name.to_lower()+"_")
				cur_version = int(cur_version)
				node_version_map[cur_version] = _plugin_dic[cur_key]
		
		if len(node_version_map) == 0:
			return null
		var cur_keys = node_version_map.keys()
		cur_keys.sort()
		return node_version_map[cur_keys.back()]
	return _plugin_dic.get(cur_plugin_name.to_lower()+"_"+str(get_version_by_str(version)).to_lower(),null)

func get_beautify_plugin_info(_info:Dictionary)->String:
	var _str:String = "{name} | ID:{id} | author:{author} | version:{version} | description:{description} | dependency:{dependency} | plugin_type:{type}".format(_info)
	return _str


#var init_plugins_name = ["pck_adapter","ipfs_adapter","aws_adapter","update_bot"]
var init_plugins_name = ["pck_adapter", "downloader_list","file_list", "aria2_adapter","godot_http_adapter",
		"ipfs_adapter","aws_adapter","cloudflare_adapter","local_file_adapter","update_bot"]
#var init_plugins_name = []


func load_init_plugins()->int:
	clear_plugin_directories_dic()
	var _directories_dic:Dictionary = get_plugin_directories_dic()
	var err_count:int = 0
	for _id in _directories_dic:
		if _id not in init_plugins_name:
			continue
		## If this variable is true, it indicates successful loading, while if it is false, 
		## it indicates failed loading. However, as long as this variable is present, it indicates that it has already been loaded.
		var have_plugin = false
		for key in _directories_dic[_id]:
			if plugin_load_status.has(_directories_dic[_id][key].dir):
				have_plugin = true
				break
			if get_plugin_instance_dic().has(_id.to_lower()+"_"+str(get_version_by_str(key)).to_lower()):
				have_plugin = true
				break
		if have_plugin == false:
			var version_list = _directories_dic[_id].keys()
			version_list.sort()
			await get_tree().process_frame
			if await load_plugin(_directories_dic[_id][version_list.back()].dir,_directories_dic) != OK:
				err_count += 1

	get_tree().call_group("PluginAPI","_on_ready")
	return err_count


func load_plugins()->int:
	var err_count:int = 0
	return err_count


func reload_plugins()->int:
	var err_count:int = 0
	err_count += await unload_plugins()
	err_count += await load_init_plugins()
	return err_count


func unload_plugin(plugin:PluginAPI)->int:
	var _plugin_info:Dictionary = plugin.get_plugin_info()
	var _file:String = plugin.get_plugin_filename()
	var _dep_arr:Array = []
	for child in get_children():
		if  child.get_plugin_info().get("dependency",{}).has(_plugin_info.id):
			_dep_arr.append(child.get_plugin_info().id)
	if _dep_arr.size() != 0:
		Logger.error("The plugin cannot be uninstalled because it is dependent on the following plugins: " + str(_dep_arr))
		Logger.error("Please uninstall all dependent plugins first, and then try again!")
		return ERR_LOCKED
	plugin.queue_free()
	await plugin.tree_exited
	plugin.set_script(null)
	plugin_load_status.erase(_file)
	plugin_list_changed.emit()
	Logger.info("Successfully uninstalled plugin: " + get_beautify_plugin_info(_plugin_info))
	return OK


func unload_plugins()->int:
	var err_count:int = 0
	plugin_load_status.clear()
	var _childs:Array = get_children()
	_childs.reverse()
	for _child in _childs:
		if await unload_plugin(_child) != OK:
			err_count += 1
	return err_count
		

func reload_plugin(plugin:PluginAPI)->int:
	var _plugin_info:Dictionary = plugin.get_plugin_info()
	var file:String = plugin.get_plugin_filename()
	var _dep_arr:Array = []
	for child in get_children():
		if  child.get_plugin_info().get("dependency",{}).has(_plugin_info.id):
			_dep_arr.append(child.get_plugin_info().id)
	if _dep_arr.size() != 0:
		Logger.error("The plugin cannot be overloaded because it is dependent on the following plugins: " + str(_dep_arr))
		Logger.error("Please uninstall all dependent plugins first, and then try again!")
		return ERR_LOCKED
	await unload_plugin(plugin)
	return await load_plugin(file)
	
func get_plugin_with_filename(f_name:String,version=-1)->PluginAPI:
	var arr:Array = get_children()
	var cur_map_node = {}
	for child in arr:
		var plug:PluginAPI = child
		var plug_name:String = plug.name
		
		if version == -1:
			if plug_name.to_lower().begins_with(f_name.to_lower()+"_"):
				var name_version = plug_name.to_lower()
				name_version = name_version.trim_prefix(f_name.to_lower()+"_")
				cur_map_node[int(name_version)] = plug
			pass
		else:
			if plug_name.to_lower() == (f_name.to_lower()+"_"+str(get_version_by_str(version)).to_lower()):
				return plug
				
	if version == -1 and not cur_map_node.is_empty():
		var cur_keys = cur_map_node.keys()
		cur_keys.sort()
		return cur_map_node[cur_keys.back()]
	return null
	

var loadding_plugin_map={}

## Obtain the name of the plugin from any of its subscripts
func get_plugin_instance_by_script_name(plugin_script_name,load_version=-1,auto_load=true):
	var result = get_plugin_name(plugin_script_name)
	var plugin_script_file_name = result[0]
	if load_version == -1:
		load_version = result[1]
	var instance = get_plugin_with_filename(plugin_script_file_name,load_version)
	if instance == null and auto_load:
		var signal_name = plugin_script_name+"_"+str(load_version)+"_is_init"
		if loadding_plugin_map.get(plugin_script_name) == load_version:
			await Signal(self, signal_name) 
		else:
			loadding_plugin_map[plugin_script_name] = load_version
			if has_signal(signal_name):
				pass
			else:
				add_user_signal(signal_name)
			await load_plugin_by_name_version(plugin_script_name,load_version)
			loadding_plugin_map.erase(plugin_script_name)
			emit_signal(signal_name)
			
		instance = get_plugin_with_filename(plugin_script_file_name,load_version)
	if instance:
		await instance.is_ready()
	return instance

func get_plugin_name(plugin_script_name):
	var cur_plugin_script_name =  plugin_script_name
	var version = ""
	if cur_plugin_script_name is Script:
		var cur_file = cur_plugin_script_name.resource_path
		var dir_file = cur_file.get_basename()
		var dir_dir_file = cur_file.get_basename().get_basename()
		var dir_dir_dir_file = cur_file.get_basename().get_basename().get_basename()
		
		var cur_name = cur_file
		while dir_dir_dir_file.get_file() not in [external_service_adapter_name,external_service_name,plugin_name,""]:
			dir_file = dir_dir_file
			dir_dir_file = dir_dir_dir_file
			dir_dir_dir_file = dir_dir_dir_file.get_base_dir()
		return [dir_dir_file.get_file(),get_version_by_str(dir_file.get_file())]
	return [cur_plugin_script_name,-1]
	

func _ready()->void:
	_init_dir()
	_init_create_plugin_api_methods_re()
	add_to_group("console_command_plugins")
	add_to_group("console_command_plugin")


var brief_regex = RegEx.new()
var param_regex = RegEx.new()
var type_regex = RegEx.new()
var name_regex = RegEx.new()
var real_name_regex = RegEx.new()
var chat_cmd_regex = RegEx.new()
var chat_cmd_minor_regex = RegEx.new()

func _init_create_plugin_api_methods_re():
	brief_regex.compile("@brief: (?<brief>[^@]*)")
	param_regex.compile("@param: (?<param>[^@]*)")
	type_regex.compile("^{(?<type>.+)}")
	name_regex.compile("^\\[(?<name>.+)\\]")
	real_name_regex.compile("(?<real_name>.*)=(?<default_value>.*)")
	chat_cmd_regex.compile("```(json)*(?<chat_cmd>{[\\s\\S]*})```")
	chat_cmd_minor_regex.compile("(json)*(?<chat_cmd>{[\\s\\S]*})")
	

func create_plugin_api_methods(cur_script):
	var all_data
	var api_data
	if OS.has_feature("editor"):
		all_data = cur_script.get_script_documentation_list()
		api_data = {}
		if all_data == null or all_data.size()<=0:
			return api_data
		for method in all_data[0].methods:
			## Only methods starting with @API will be recorded
			method.description = method.description.strip_edges()
			if not method.description.begins_with("@API"):
				continue
			method.description = method.description.trim_prefix("@API")
			method.description = method.description.strip_edges()
			var cur_data = {}
			
			var brief_result = brief_regex.search(method.description)
			if brief_result:
				cur_data["description"] = brief_result.get_string("brief").strip_edges()
			
			var _plugin_result = PluginManager.get_plugin_name(cur_script)
			cur_data["plugin_name"] = _plugin_result[0]
			cur_data["plugin_version"] = _plugin_result[1]
			
			cur_data["name"] = method.name
			cur_data["required"] = []
			cur_data["parameters"] = {}
			for param_result in param_regex.search_all(method.description):
				var cur_param = param_result.get_string("param").strip_edges()
				var type_result = type_regex.search(cur_param)
				var cur_param_type = null
				if type_result:
					cur_param_type = type_result.get_string("type")
					cur_param = cur_param.trim_prefix("{%s}"%cur_param_type).strip_edges()
					cur_param_type = cur_param_type.strip_edges()

				var name_result = name_regex.search(cur_param)
				var cur_param_name = "None"
				var default_value = null
				var real_name_result = false
				if name_result:
					cur_param_name = name_result.get_string("name")
					cur_param = cur_param.trim_prefix("[%s]"%cur_param_name).strip_edges()
					cur_param_name = cur_param_name.strip_edges()
					real_name_result = real_name_regex.search(cur_param_name)
					if real_name_result:
						cur_param_name  = real_name_result.get_string("real_name")
						cur_param_name = cur_param_name.strip_edges()
						default_value = real_name_result.get_string("default_value")
						default_value = default_value.strip_edges()
						
				cur_param = cur_param.trim_prefix("-")
				cur_param = cur_param.strip_edges()
				
				if "parameters" not in cur_data:
					cur_data["parameters"] = {}
				
				cur_data["parameters"][cur_param_name] = {}
				if cur_param_type!=null:
					cur_data["parameters"][cur_param_name]["type"] = cur_param_type
				cur_data["parameters"][cur_param_name]["description"] = cur_param
				
				if default_value!=null:
					cur_data["parameters"][cur_param_name]["default_value"] = default_value
				

			for i in range(len(method.arguments)):
				var argument = method.arguments[i]
				if argument.name in cur_data["parameters"]:
					cur_data["parameters"][argument.name]["index"] = i
					if not cur_data["parameters"][argument.name].has("type"):
						cur_data["parameters"][argument.name]["type"] = argument.type

					if not cur_data["parameters"][argument.name].has("default_value"):
						cur_data["parameters"][argument.name]["default_value"] = argument.default_value
			
			for cur_param_name in cur_data["parameters"]:
				if cur_data["parameters"][cur_param_name].get("default_value",null) == null:
					cur_data["required"].append(cur_param_name)
			
			api_data[method.name] = cur_data
	else:
		all_data = cur_script.get_script_method_list()
		api_data = {}
		if all_data == null or all_data.size()<=0:
			return api_data
		for method in all_data:
			var cur_data = {}
			cur_data["description"] = ""
			
			var _plugin_result = PluginManager.get_plugin_name(cur_script)
			cur_data["plugin_name"] = _plugin_result[0]
			cur_data["plugin_version"] = _plugin_result[1]
			
			cur_data["name"] = method.name
			cur_data["required"] = []
			cur_data["parameters"] = {}
		
			for i in range(len(method.args)):
				var argument = method.args[i]
				cur_data["parameters"][argument.name] = {}
				cur_data["parameters"][argument.name]["index"] = i
				cur_data["parameters"][argument.name]["type"] = type_string(argument.type)
				
			for i in range(len(method.default_args)):
				var match_index = len(method.args) - len(method.default_args) + i
				for arg in cur_data["parameters"]:
					if cur_data["parameters"][arg]["index"] == match_index:
						cur_data["parameters"][arg]["default_value"] = method.default_args[i]
						
			for cur_param_name in cur_data["parameters"]:
				if cur_data["parameters"][cur_param_name].get("default_value",null) == null:
					cur_data["required"].append(cur_param_name)
			api_data[method.name] = cur_data
	return api_data


func call_from_dict(plugin_name, call_name, call_dict, cur_message, cur_result=true):
	var cur_plugin = get_plugin(plugin_name)
	if cur_plugin:
		cur_plugin.call_from_dict(call_name, call_dict, cur_message, cur_result)
	pass


func get_version_by_str(cur_str):
	if typeof(cur_str) == TYPE_INT:
		return cur_str
	cur_str = cur_str.to_lower().trim_prefix("v")
	var version_array = cur_str.split("_")
	version_array.reverse()
	var cur_id = 0 
	var multiple = 1
	for key in version_array:
		cur_id+=multiple* int(key)
		multiple = multiple*1000
	return int(cur_id)


func get_version_str_by_num(cur_num):
	if typeof(cur_num) == TYPE_STRING:
		return cur_num
	cur_num = int(cur_num)
	var third = cur_num%1000
	var second = (cur_num/1000)%1000
	var first = (cur_num/1000000)%1000
	return "v%s_%s_%s"%[first,second,third]


func get_big_version_folder(folder, only_big_version=false):
	if only_big_version:
		var dir = DirAccess.open(folder)
		var directories = dir.get_directories()
		var big_version_path = ""
		var big_version = -1
		for cur_dir_name in directories:
			var cur_version = PluginManager.get_version_by_str(cur_dir_name)
			if cur_version>big_version:
				big_version_path = folder.path_join(cur_dir_name)
				big_version = cur_version
		return big_version_path
	return folder

## Return folder address without version number
func get_plugin_base_dir_by_plugin_name(cur_plugin_name:String)->String:
	var cur_external_service_adapter_plugin_path = res_external_service_adapter_dir_path.path_join(cur_plugin_name)
	var cur_plugin_path = get_res_plugin_path(cur_plugin_name)
	var result_path = ""
	if DirAccess.dir_exists_absolute(cur_plugin_path):
		result_path = cur_plugin_path
	elif DirAccess.dir_exists_absolute(cur_external_service_adapter_plugin_path):
		result_path = cur_external_service_adapter_plugin_path
	return result_path

## Return folder address with version number
func get_plugin_dir_by_plugin_name(cur_plugin_name:String,version):
	return get_plugin_script_by_plugin_name(cur_plugin_name,version).get_base_dir()

func get_plugin_script_by_plugin_name(cur_plugin_name:String, version):
	var cur_external_service_adapter_plugin_main_path = get_res_external_service_adapter_main_path(cur_plugin_name,version)
	var cur_plugin_main_path = get_res_plugin_main_path(cur_plugin_name,version)
	var result_path = ""
	if FileAccess.file_exists(cur_plugin_main_path):
		result_path = cur_plugin_main_path
	elif FileAccess.file_exists(cur_external_service_adapter_plugin_main_path):
		result_path = cur_external_service_adapter_plugin_main_path
	return result_path

func get_plugin_can_use_version(cur_plugin_name:String):
	var all_use_version = {}
	var dir_path = get_plugin_base_dir_by_plugin_name(cur_plugin_name)
	if dir_path != "":
		var dir = DirAccess.open(dir_path)
		if dir:
			var directories = dir.get_directories()
			for cur_dir_name in directories:
				var cur_version = PluginManager.get_version_by_str(cur_dir_name)
				all_use_version[cur_version]=["res",""]

	var user_dir_path = external_service_plugin_path.path_join(cur_plugin_name)
	var user_dir = DirAccess.open(user_dir_path)
	if user_dir:
		var user_directories = user_dir.get_directories()
		for cur_dir_name in user_directories:
			var cur_version = PluginManager.get_version_by_str(cur_dir_name)
			all_use_version[cur_version]=["user","external_service_plugin"]
	
	var plugin_dir_path = plugin_path.path_join(cur_plugin_name)
	var plugin_dir = DirAccess.open(plugin_dir_path)
	if plugin_dir:
		var plugin_directories = plugin_dir.get_directories()
		for cur_dir_name in plugin_directories:
			var cur_version = PluginManager.get_version_by_str(cur_dir_name)
			all_use_version[cur_version]=["user","plugin"]
	
	return all_use_version

func get_json_from_chat_cmd(chat_cmd:String):
	## Match JSON instructions between `````` first
	var chat_cmd_result = chat_cmd_regex.search(chat_cmd)
	if chat_cmd_result:
		pass
	else:
		chat_cmd_result = chat_cmd_minor_regex.search(chat_cmd)
	if chat_cmd_result == null:
		return {}
	var chat_cmd_str  = chat_cmd_result.get_string("chat_cmd")
	var chat_cmd_data = JSON.parse_string(chat_cmd_str)
	return chat_cmd_data

func try_parse_chat_cmd(chat_cmd:String):
	var chat_cmd_data = get_json_from_chat_cmd(chat_cmd)
	if chat_cmd_data:
		if chat_cmd_data.get("type","").to_lower() == "func":
			var cur_plugin_name = chat_cmd_data.get("plugin name",chat_cmd_data.get("plugin_name",""))
			var cur_plugin_version = chat_cmd_data.get("plugin version",chat_cmd_data.get("plugin_version","0"))
			cur_plugin_version = int(cur_plugin_version)
			var cur_func_name = chat_cmd_data.get("func name",chat_cmd_data.get("func_name",""))
			var cur_call_data = chat_cmd_data.get("parameters",{})
			var cur_node = await PluginManager.get_plugin_instance_by_script_name(cur_plugin_name,cur_plugin_version)
			
			for key in cur_call_data:
				if typeof(cur_call_data[key]) == TYPE_STRING:
					if cur_call_data[key].begins_with("\"") and cur_call_data[key].ends_with("\""):
						cur_call_data[key] = cur_call_data[key].trim_prefix("\"") 
						cur_call_data[key] = cur_call_data[key].trim_suffix("\"")

			cur_node.call_from_dict(cur_func_name, cur_call_data)
