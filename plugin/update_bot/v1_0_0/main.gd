extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"update_bot","mimi",plugin_version,"update plugin content","plugin",{"file_list":["v1_0_0"]})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	
var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	add_child(service_config_manager,true)
	service_config_manager.init_config()

func _config_loaded()->void:
	pass


func _ready()->void:
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	pass


func get_target_plugin_info(cur_plugin_name:String="",min_version:int=0,max_version:int=1000000000):
	var target_plugin_info = await Platform.get_plugin_info(cur_plugin_name,min_version,max_version)
	return target_plugin_info
	#if cur_plugin_name == "free_ai_adapter":
		#return ["aws", {"region":"ap-southeast-1","bucket":"vmeplugin","service":"s3","sub_path":"free_ai_adapter/"},1000000]
	#return ["ipfs",{"ipfs_id":cur_plugin_ename}, 1000000]
	
## @API
## @brief: Download the specified plugin from the cloud storage provider
## @param: [cur_plugin_name] - download plugin name
## @param: [min_version] - Minimum version number of the plugin
## @param: [max_version] - Maximum version number of the plugin
func download_load_plugin_pck(cur_plugin_name:String="",min_version:int=0,max_version:int=1000000000):
	var can_use_version = PluginManager.get_plugin_can_use_version(cur_plugin_name)
	var can_use_version_keys = can_use_version.keys()
	can_use_version_keys.sort()
	can_use_version_keys.reverse()
	var use_version = null
	for i in range(len(can_use_version_keys)):
		if can_use_version_keys[i]>max_version:
			continue
		if can_use_version_keys[i]<min_version:
			continue
		use_version = can_use_version_keys[i]
		break
	if not use_version:
		var target_plugin_info = await get_target_plugin_info(cur_plugin_name,min_version,max_version)
		var download_method = target_plugin_info["store_info"]["platform"]
		download_method = download_method.to_lower()
		var version = target_plugin_info["content_version"]
		
		use_version = version
		var path
		var file_list = await PluginManager.get_plugin_instance_by_script_name("file_list")
		if download_method == "ipfs":
			path = await file_list.fs_download("",target_plugin_info["store_info"]["ipfs_id"],"",0)
		elif download_method == "aws":
			path = await file_list.fs_download(target_plugin_info["store_info"]["sub_path"],"","",2,target_plugin_info["store_info"]["region"],
					target_plugin_info["store_info"]["bucket"],"","",target_plugin_info["store_info"]["service"])

		elif download_method == "cloudflare":
			path = await file_list.fs_download(target_plugin_info["store_info"]["sub_path"],"","",1,target_plugin_info["store_info"]["region"],
					target_plugin_info["store_info"]["bucket"],target_plugin_info["store_info"]["read_access_key"],
					target_plugin_info["store_info"]["read_secret_access_key"],target_plugin_info["store_info"]["service"],
					target_plugin_info["store_info"]["account_id"])
					
		path = path.trim_suffix("/")
		path = path.trim_suffix(cur_plugin_name)

		if DirAccess.dir_exists_absolute(path):
			if FileAccess.file_exists(path.path_join(cur_plugin_name).path_join(PluginManager.plugin_pck_name)):
				## It is highly likely that it is a plugin type
				var plugin_pck_path = PluginManager.get_plugin_pck_path(cur_plugin_name,version)
				DirAccess.remove_absolute(plugin_pck_path.get_base_dir())
				DirAccess.make_dir_recursive_absolute(plugin_pck_path.get_base_dir())
				FileManager.copy_directory_recursively(path.path_join(cur_plugin_name),plugin_pck_path.get_base_dir())
				if not Engine.is_editor_hint():
					var load_result = ProjectSettings.load_resource_pack(plugin_pck_path)
				## Unable to uninstall temporarily: https://github.com/godotengine/godot/pull/61286
				
			else:
				## It is highly likely that it is a service type
				var plugin_path = PluginManager.external_service_plugin_path.path_join(cur_plugin_name).path_join(PluginManager.get_version_str_by_num(version))
				DirAccess.remove_absolute(plugin_path)
				DirAccess.make_dir_recursive_absolute(plugin_path)
				FileManager.copy_directory_recursively(path.path_join(cur_plugin_name),plugin_path)
				if not Engine.is_editor_hint():
					var load_result = ProjectSettings.load_resource_pack(PluginManager.get_external_service_adapter_pck_path(cur_plugin_name,version))

		## Delete source file
		FileManager.remove_directory_recursively(path)
	else:
		var target_info = can_use_version[use_version]

		if target_info[0]=="res":
			pass
		elif target_info[0]=="user":
			## Need to load plugin properties from user://
			if target_info[1] == "external_service_plugin":
				if not Engine.is_editor_hint():
					var load_result = ProjectSettings.load_resource_pack(PluginManager.get_external_service_adapter_pck_path(cur_plugin_name,use_version))
			elif target_info[1] == "plugin":
				if not Engine.is_editor_hint():
					var load_result = ProjectSettings.load_resource_pack(PluginManager.get_plugin_pck_path(cur_plugin_name,use_version))
	
	var dependency = PluginManager.get_plugin_dir_info(PluginManager.get_plugin_dir_by_plugin_name(cur_plugin_name, use_version)).get("dependency",{})
	for _dep in dependency:
		var dep_version = dependency[_dep]
		var dep_min_version = 0
		var dep_max_version = 1000000000
		if len(dep_version)==1:
			dep_min_version = PluginManager.get_version_by_str(dep_version[0])
		elif len(dep_version)==2:
			dep_min_version = PluginManager.get_version_by_str(dep_version[0])
			dep_max_version = PluginManager.get_version_by_str(dep_version[1])
		await download_load_plugin_pck(_dep, dep_min_version, dep_max_version)
		pass
	pass
	var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":"The plugin %s has been loaded into the file system"%[cur_plugin_name],"is_bot":true},null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
	return use_version

