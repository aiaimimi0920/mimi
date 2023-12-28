extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)
signal init_tree_ui

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"file_list","mimi",plugin_version,"Provides file storage and download services through various different storage providers.","plugin",
		{})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)


var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	add_child(service_config_manager,true)
	service_config_manager.init_config()
	_init_root_node()

func _config_loaded()->void:
	pass

func _ready()->void:
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()

var file_adapter_name_list = []
var file_adapter_name_map = {}

func sort_file_adapter(a, b):
	if file_adapter_name_map[a] < file_adapter_name_map[b]:
		return true
	if file_adapter_name_map[a] == file_adapter_name_map[b]:
		if a<b:
			return true
		return false
	return false



func trigger_file_adapter(adapter_plugin_name, target_index):
	file_adapter_name_map[adapter_plugin_name] = target_index
	file_adapter_name_list=file_adapter_name_map.keys()
	file_adapter_name_list.sort_custom(sort_file_adapter)
	# file_info_reverse_map[adapter_plugin_name] = {}
	emit_signal("add_file_adapter", adapter_plugin_name)

func auto_save_file_node_map():
	pass


func get_fs_list_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_list_need_args()
	return result
	

## TODO:List all files and file directories under a certain path
func fs_list(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_list(adapter_need_data)
	return result


func get_fs_get_info_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_get_info_need_args()
	return result

## TODO:Get information about a certain file/directory
func fs_get_info(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_get_info(adapter_need_data)
	return result


func get_fs_dirs_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_dirs_need_args()
	return result

## TODO:Get all directories under a certain path
func fs_dirs(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_dirs(adapter_need_data)
	return result


func get_fs_search_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_search_need_args()
	return result

## TODO:Search for files or folders
func fs_search(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_search(adapter_need_data)
	return result


func get_fs_mkdir_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_mkdir_need_args()
	return result

## TODO:Search for files or folders
func fs_mkdir(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_mkdir(adapter_need_data)
	return result


func get_fs_rename_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_rename_need_args()
	return result

## TODO:Search for files or folders
func fs_rename(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_rename(adapter_need_data)
	return result

func get_fs_batch_rename_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_batch_rename_need_args()
	return result

## TODO:Search for files or folders
func fs_batch_rename(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_batch_rename(adapter_need_data)
	return result

func get_fs_regex_rename_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_regex_rename_need_args()
	return result

## TODO:Search for files or folders
func fs_regex_rename(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_regex_rename(adapter_need_data)
	return result


func get_fs_upload_form_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_upload_form_need_args()
	return result
	

func fs_upload_form(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_upload_form(adapter_need_data)
	return result

func get_fs_upload_put_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_upload_put_need_args()
	return result
	

func fs_upload_put(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_upload_put(adapter_need_data)
	return result

func get_fs_move_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_move_need_args()
	return result
	

func fs_move(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_move(adapter_need_data)
	return result

func get_fs_copy_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_copy_need_args()
	return result
	

func fs_copy(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_copy(adapter_need_data)
	return result


func get_fs_remove_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_remove_need_args()
	return result
	

func fs_remove(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_remove(adapter_need_data)
	return result
	

func get_fs_remove_empty_directory_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_remove_empty_directory_need_args()
	return result
	

func fs_remove_empty_directory(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_remove_empty_directory(adapter_need_data)
	return result
		

func get_fs_recursive_move_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_recursive_move_need_args()
	return result
	

func fs_recursive_move(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_recursive_move(adapter_need_data)
	return result


func get_fs_download_need_args(file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.get_fs_download_need_args()
	return result

func fs_download(adapter_need_data, file_plugin_name):
	var file_adapter = await PluginManager.get_plugin_instance_by_script_name(file_plugin_name)
	var result = await file_adapter.fs_download(adapter_need_data)
	return result
	
	
var file_sync_info_map={}
func add_file_sync_info(adapter_need_data, adapter_name, mapping_path, include, exclude, from_uid, from_path, is_used = true, sync=true):
	if from_path!="" and from_uid=="":
		var cur_adapter_need_data = adapter_need_data.duplicate(true)
		if cur_adapter_need_data["save_dir"]!="":
			cur_adapter_need_data["save_dir"] = ""
		from_uid = add_file_sync_info(cur_adapter_need_data, adapter_name, "", "", "","","",false,false)

	var cur_uid=""
	if from_path!="":
		cur_uid += mapping_path.md5_text()
		cur_uid += include.md5_text()
		cur_uid += exclude.md5_text()
		cur_uid += from_uid.md5_text()
		cur_uid += from_path.md5_text()
		cur_uid = cur_uid.md5_text()
	else:
		for key in adapter_need_data:
			cur_uid += (key+adapter_need_data[key]).md5_text()
		cur_uid+=adapter_name.md5_text()
		
		cur_uid+=mapping_path.md5_text()
		cur_uid+=include.md5_text()
		cur_uid+=exclude.md5_text()
		cur_uid+=from_uid.md5_text()
		cur_uid+=from_path.md5_text()
		cur_uid = cur_uid.md5_text()
	
	if cur_uid not in file_sync_info_map:
		var cur_file_sync_info = FileSyncInfo.new()
		cur_file_sync_info.uid = cur_uid
		if from_path!="":
			cur_file_sync_info.adapter_name = ""
			cur_file_sync_info.adapter_need_data = {"save_dir":adapter_need_data["save_dir"]}
		else:
			cur_file_sync_info.adapter_name = adapter_name
			cur_file_sync_info.adapter_need_data = adapter_need_data
		cur_file_sync_info.mapping_path = mapping_path.simplify_path()
		cur_file_sync_info.include = include
		cur_file_sync_info.exclude = exclude
		cur_file_sync_info.from_uid = from_uid
		cur_file_sync_info.from_path = from_path.simplify_path()
		cur_file_sync_info.is_used = is_used
		file_sync_info_map[cur_uid] = cur_file_sync_info
	
	if sync:
		sync_path(cur_uid, "")
	return cur_uid
	
	
func sync_path(cur_file_sync_info_uid, sub_path):
	var all_files = []
	var all_dirs = []
	if cur_file_sync_info_uid not in file_sync_info_map:
		return false
		
	var cur_file_sync_info = file_sync_info_map[cur_file_sync_info_uid]
	if cur_file_sync_info.is_used == false:
		return false
	
	var filter_info = null
	var cur_adapter_need_data_path
	if cur_file_sync_info.from_uid!="":
		## sub_node
		var base_file_sync_info = file_sync_info_map[cur_file_sync_info.from_uid]
		filter_info = base_file_sync_info
		var cur_adapter_need_data = base_file_sync_info.adapter_need_data.duplicate(true)
		cur_adapter_need_data_path = cur_adapter_need_data["path"]
		if cur_file_sync_info.from_path !="":
			cur_adapter_need_data_path = cur_adapter_need_data_path.path_join(cur_file_sync_info.from_path)
		if sub_path!="":
			cur_adapter_need_data_path = cur_adapter_need_data_path.path_join(sub_path)
		cur_adapter_need_data["path"] = cur_adapter_need_data_path.simplify_path()
		var ret = await fs_list(cur_adapter_need_data, base_file_sync_info.adapter_name)
		all_files = ret[0]
		all_dirs = ret[1]
	else:
		filter_info = cur_file_sync_info
		var cur_adapter_need_data = cur_file_sync_info.adapter_need_data.duplicate(true)
		cur_adapter_need_data_path = cur_adapter_need_data["path"]
		if sub_path!="":
			cur_adapter_need_data_path = cur_adapter_need_data_path.path_join(sub_path)
		cur_adapter_need_data["path"] = cur_adapter_need_data_path.simplify_path()
		var ret = await fs_list(cur_adapter_need_data, cur_file_sync_info.adapter_name)
		all_files = ret[0]
		all_dirs = ret[1]
	
	if len(all_files)==0:
		all_files.append(cur_adapter_need_data_path)
	

	var cur_adapter_need_data_path_array = cur_adapter_need_data_path.rsplit("/",false,1)
	if cur_adapter_need_data_path_array.size()>=2:
		var cur_all_files = []
		var cur_all_dirs = []
		for key in all_files:
			cur_all_files.append(key.trim_prefix(cur_adapter_need_data_path_array[0]))
		for key in all_dirs:
			cur_all_dirs.append(key.trim_prefix(cur_adapter_need_data_path_array[0]))
		all_files = cur_all_files
		all_dirs = cur_all_dirs
	else:
		pass
	
	var ret = filter_files_dirs(all_files, all_dirs, filter_info.include, filter_info.exclude)
	all_files = ret[0]
	all_dirs = ret[1]
	
	for cur_file_path in all_files:
		#cur_file_path = cur_file_path.simplify_path().trim_prefix()
		var target_file_path = cur_file_path
		if cur_file_sync_info.mapping_path=="":
			pass
		else:
			var cur_target_file_path_array = target_file_path.split("/",false,1)
			if cur_target_file_path_array.size()>=2:
				target_file_path = cur_file_sync_info.mapping_path.path_join(cur_target_file_path_array[1])
			else:
				target_file_path = cur_file_sync_info.mapping_path

		create_file_node(cur_file_sync_info_uid, cur_file_path, target_file_path)
	emit_signal("init_tree_ui")
	return true
	

func download_path(cur_file_sync_info_uid, sub_path, force_download=false):
	var save_dir = ""
	if cur_file_sync_info_uid not in file_sync_info_map:
		return false
		
	var cur_file_sync_info = file_sync_info_map[cur_file_sync_info_uid]
	if cur_file_sync_info.is_used == false:
		return false
	
	var filter_info = null
	var cur_adapter_need_data_path
	if cur_file_sync_info.from_uid!="":
		## sub_node
		var base_file_sync_info = file_sync_info_map[cur_file_sync_info.from_uid]
		filter_info = base_file_sync_info
		var cur_adapter_need_data = base_file_sync_info.adapter_need_data.duplicate(true)
		cur_adapter_need_data_path = cur_adapter_need_data["path"]
		if cur_file_sync_info.from_path !="":
			cur_adapter_need_data_path = cur_adapter_need_data_path.path_join(cur_file_sync_info.from_path)
		if sub_path!="":
			cur_adapter_need_data_path = cur_adapter_need_data_path.path_join(sub_path)
		cur_adapter_need_data["path"] = cur_adapter_need_data_path.simplify_path()
		
		var cur_save_dir = cur_file_sync_info.adapter_need_data["save_dir"]
		if cur_save_dir == "":
			cur_save_dir = cur_adapter_need_data["save_dir"]
			if cur_save_dir == "":
				cur_save_dir = GlobalManager.globalize_file_path.path_join(cur_file_sync_info.uid)
			
		cur_adapter_need_data["save_dir"] = cur_save_dir
		
		var target_path = cur_save_dir.path_join(cur_adapter_need_data["path"])
		if DirAccess.dir_exists_absolute(target_path) or FileAccess.file_exists(target_path):
			if force_download:
				if DirAccess.dir_exists_absolute(target_path):
					FileManager.remove_directory_recursively(target_path)
				if FileAccess.file_exists(target_path):
					FileManager.remove_file(target_path)
			else:
				return true

		var ret = await fs_download(cur_adapter_need_data, base_file_sync_info.adapter_name)
		save_dir = ret
	else:
		filter_info = cur_file_sync_info
		var cur_adapter_need_data = cur_file_sync_info.adapter_need_data.duplicate(true)
		cur_adapter_need_data_path = cur_adapter_need_data["path"]
		if sub_path!="":
			cur_adapter_need_data_path = sub_path

		cur_adapter_need_data["path"] = cur_adapter_need_data_path.simplify_path()
		
		var cur_save_dir = cur_file_sync_info.adapter_need_data["save_dir"]
		if cur_save_dir == "":
			cur_save_dir = cur_adapter_need_data["save_dir"]
			if cur_save_dir == "":
				cur_save_dir = GlobalManager.globalize_file_path.path_join(cur_file_sync_info.uid)
			
		cur_adapter_need_data["save_dir"] = cur_save_dir
		
		var target_path = cur_save_dir.path_join(cur_adapter_need_data["path"])
		if DirAccess.dir_exists_absolute(target_path) or FileAccess.file_exists(target_path):
			if force_download:
				if DirAccess.dir_exists_absolute(target_path):
					FileManager.remove_directory_recursively(target_path)
				if FileAccess.file_exists(target_path):
					FileManager.remove_file(target_path)
			else:
				return true
		
		var ret = await fs_download(cur_adapter_need_data, cur_file_sync_info.adapter_name)
		save_dir = ret
		
	emit_signal("init_tree_ui")
	return true

func filter_files_dirs(all_files, all_dirs, include="",exclude=""):
	var include_array = include.split(",")
	var exclude_array = exclude.split(",")
	var include_filter_map = {}
	var exclude_filter_map = {}
	for key in include_array:
		if key!="":
			include_filter_map[key] = true
	
	for key in exclude_array:
		if key!="":
			exclude_filter_map[key] = true
	
	var new_all_files = all_files.duplicate(true)
	var new_all_dirs = all_dirs.duplicate(true)

	var ret_all_files = []
	var ret_all_dirs = []
	
	if len(include_filter_map.keys())<=0:
		pass
	else:
		for one_include_filter in include_filter_map.keys():
			var result_cur_result_regex = ""
			var j = 0
			while true:
				if j>len(one_include_filter)-1:
					break
				if one_include_filter[j] == r"\\":
					result_cur_result_regex = result_cur_result_regex + "\\\\"
				else:
					result_cur_result_regex = result_cur_result_regex + one_include_filter[j]
					
				j += 1
			var regex = RegEx.new()
			regex.compile(result_cur_result_regex)
			for file_path in new_all_files:
				var result = regex.search(file_path)
				if result:
					ret_all_files.append(file_path)
					
			for dir_path in new_all_dirs:
				var result = regex.search(dir_path)
				if result:
					ret_all_dirs.append(dir_path)

		new_all_files = ret_all_files.duplicate(true)
		new_all_dirs = ret_all_dirs.duplicate(true)
		ret_all_files = []
		ret_all_dirs = []
		
	if len(include_filter_map.keys())<=0:
		ret_all_files = new_all_files
		ret_all_dirs = new_all_dirs
	else:
		for one_exclude_filter in exclude_filter_map.keys():
			var result_cur_result_regex = ""
			var j = 0
			while true:
				if j>len(one_exclude_filter)-1:
					break
				if one_exclude_filter[j] == r"\\":
					result_cur_result_regex = result_cur_result_regex + "\\\\"
				else:
					result_cur_result_regex = result_cur_result_regex + one_exclude_filter[j]
					
				j += 1
			var regex = RegEx.new()
			regex.compile(result_cur_result_regex)
			for file_path in new_all_files:
				var result = regex.search(file_path)
				if result:
					pass
				else:
					ret_all_files.append(file_path)
					
			for dir_path in new_all_dirs:
				var result = regex.search(dir_path)
				if result:
					pass
				else:
					ret_all_dirs.append(dir_path)
	
	return [ret_all_files, ret_all_dirs]

func create_file_node(used_file_sync_uid, sub_path, file_path):
	sub_path = sub_path.simplify_path()
	file_path = file_path.simplify_path()
	var cur_file_node
	if sub_path !="":
		var cur_dir_node = create_dir_node(used_file_sync_uid, sub_path.get_base_dir(), file_path.get_base_dir())
		var cur_merge_dir_node = get_file_merge_node(file_path.get_base_dir())
		
		var cur_merge_file_node = create_file_merge_node(file_path)
		cur_file_node = FileNode.new()
		cur_file_node.parent_node = cur_dir_node
		cur_file_node.file_name = file_path.get_file()
		cur_file_node.file_path = file_path.trim_prefix("/")
		cur_file_node.merge_node = cur_merge_file_node
		cur_file_node.sub_path = sub_path
		cur_file_node.used_file_sync_uid = used_file_sync_uid
		
		
		var cur_file_sync_info = file_sync_info_map[used_file_sync_uid]
		var cur_base_sync_info = null
		if cur_file_sync_info.from_uid!="":
			cur_base_sync_info = file_sync_info_map[cur_file_sync_info.from_uid]
		
		var cur_save_dir = cur_file_sync_info.adapter_need_data["save_dir"]
		if cur_save_dir == "":
			if cur_base_sync_info:
				cur_save_dir = cur_base_sync_info.adapter_need_data["save_dir"]
			if cur_save_dir == "":
				cur_save_dir = GlobalManager.globalize_file_path.path_join(used_file_sync_uid)
			
		cur_file_node.save_path = cur_save_dir.path_join(cur_file_node.sub_path)
		
		
		cur_merge_file_node.merge_file_node[used_file_sync_uid] = cur_file_node
	else:
		var cur_merge_file_node = create_file_merge_node(file_path)
		cur_file_node = FileNode.new()
		cur_file_node.parent_node = null
		cur_file_node.file_name = file_path.get_file()
		cur_file_node.file_path = file_path.trim_prefix("/")
		cur_file_node.merge_node = cur_merge_file_node
		cur_file_node.sub_path = sub_path
		cur_file_node.used_file_sync_uid = used_file_sync_uid
		
		var cur_file_sync_info = file_sync_info_map[used_file_sync_uid]
		var cur_base_sync_info = null
		if cur_file_sync_info.from_uid!="":
			cur_base_sync_info = file_sync_info_map[cur_file_sync_info.from_uid]
		
		var cur_save_dir = cur_file_sync_info.adapter_need_data["save_dir"]
		if cur_save_dir == "":
			if cur_base_sync_info:
				cur_save_dir = cur_base_sync_info.adapter_need_data["save_dir"]
			if cur_save_dir == "":
				cur_save_dir = GlobalManager.globalize_file_path.path_join(used_file_sync_uid)
			
		cur_file_node.save_path = cur_save_dir
		
		cur_merge_file_node.merge_file_node[used_file_sync_uid] = cur_file_node
		
	return cur_file_node

func create_dir_node(used_file_sync_uid, sub_path, dir_path):
	sub_path = sub_path.simplify_path()
	var sub_path_array = sub_path.split("/",false,1)
	dir_path = dir_path.simplify_path()
	
	var root_dir_path = ""
	var base_name = ""
	if sub_path_array.size()>=2:
		root_dir_path = dir_path.trim_suffix(sub_path_array[1])
		base_name = sub_path_array[0]
	else:
		root_dir_path = dir_path
	
	root_dir_path = root_dir_path.trim_suffix("/")
	var cur_merge_dir_parent_node = create_dir_merge_node(root_dir_path.get_base_dir())
	var cur_merge_dir_node = cur_merge_dir_parent_node.get_dir_node(root_dir_path.get_file())
	if cur_merge_dir_node == null:
		cur_merge_dir_node = create_dir_merge_node(root_dir_path)
	
	var cur_dir_node = cur_merge_dir_node.merge_dir_node.get(used_file_sync_uid,null)
	if cur_dir_node == null:
		cur_dir_node = DirNode.new()
		cur_dir_node.parent_node = null
		cur_dir_node.used_file_sync_uid = used_file_sync_uid
		cur_dir_node.sub_path = ""
		cur_dir_node.dir_name = root_dir_path.get_file()
		cur_dir_node.dir_path = root_dir_path.trim_prefix("/")
		cur_dir_node.merge_node = cur_merge_dir_node
		
		
		var cur_file_sync_info = file_sync_info_map[used_file_sync_uid]
		var cur_base_sync_info = null
		if cur_file_sync_info.from_uid!="":
			cur_base_sync_info = file_sync_info_map[cur_file_sync_info.from_uid]
		
		var cur_save_dir = cur_file_sync_info.adapter_need_data["save_dir"]
		if cur_save_dir == "":
			if cur_base_sync_info:
				cur_save_dir = cur_base_sync_info.adapter_need_data["save_dir"]
			if cur_save_dir == "":
				cur_save_dir = GlobalManager.globalize_file_path.path_join(used_file_sync_uid)
			
		cur_dir_node.save_path = cur_save_dir
		
		
		cur_merge_dir_node.merge_dir_node[used_file_sync_uid] = cur_dir_node

	var cur_dir_path = root_dir_path
	var cur_sub_path = ""

	sub_path_array = sub_path.split("/",false,1)
	var cur_sub_split_path = ""
	
	if sub_path_array.size()>=2:
		cur_sub_split_path = sub_path_array[1]
	else:
		cur_sub_split_path = ""
	
	for cur_dir_name in cur_sub_split_path.split("/",false):
		cur_dir_path = "/".join([cur_dir_path,cur_dir_name])
		if cur_sub_path == "":
			cur_sub_path = cur_dir_name
		else:
			cur_sub_path = "/".join([cur_sub_path,cur_dir_name])
		
		var get_cur_merge_dir_node = cur_merge_dir_node.get_dir_node(cur_dir_name)
		if get_cur_merge_dir_node == null:
			get_cur_merge_dir_node = create_dir_merge_node(cur_dir_path)
			
		var get_cur_dir_node = cur_dir_node.get_dir_node(cur_dir_name)
		if get_cur_dir_node == null:
			get_cur_dir_node = DirNode.new()
			get_cur_dir_node.parent_node = cur_dir_node
			get_cur_dir_node.used_file_sync_uid = used_file_sync_uid
			if base_name!="":
				get_cur_dir_node.sub_path = base_name.path_join(cur_sub_path)
			else:
				get_cur_dir_node.sub_path = cur_sub_path
				
			get_cur_dir_node.dir_name = cur_dir_name
			get_cur_dir_node.dir_path = cur_dir_path.trim_prefix("/")
			get_cur_dir_node.merge_node = get_cur_merge_dir_node
			get_cur_merge_dir_node.merge_dir_node[used_file_sync_uid] = get_cur_dir_node
			
			var cur_file_sync_info = file_sync_info_map[used_file_sync_uid]
			var cur_base_sync_info = null
			if cur_file_sync_info.from_uid!="":
				cur_base_sync_info = file_sync_info_map[cur_file_sync_info.from_uid]
			
			var cur_save_dir = cur_file_sync_info.adapter_need_data["save_dir"]
			if cur_save_dir == "":
				if cur_base_sync_info:
					cur_save_dir = cur_base_sync_info.adapter_need_data["save_dir"]
				if cur_save_dir == "":
					cur_save_dir = GlobalManager.globalize_file_path.path_join(used_file_sync_uid)
				
			get_cur_dir_node.save_path = cur_save_dir
			
			cur_dir_node.dirs[cur_dir_name] = get_cur_dir_node
		
		cur_dir_node = get_cur_dir_node
		cur_merge_dir_node = get_cur_merge_dir_node
	
	return cur_dir_node


func get_dir_merge_node(dir_path):
	dir_path = dir_path.simplify_path()
	var cur_node = root_node
	if dir_path!="":
		for cur_name in dir_path.split("/"):
			cur_node = cur_node.get_dir_node(cur_name)
	return cur_node


func get_file_merge_node(file_path):
	file_path = file_path.simplify_path()
	var cur_dir_node = get_dir_merge_node(file_path.get_base_dir())
	var cur_node = cur_dir_node.get_file_node(file_path.get_file())
	return cur_node


func create_dir_merge_node(dir_path):
	dir_path = dir_path.simplify_path()
	var cur_node = root_node
	for cur_name in dir_path.split("/",false):
		var get_cur_node = cur_node.get_dir_node(cur_name)
		if get_cur_node == null:
			var cur_dir_node = DirMergeNode.new()
			cur_dir_node.dir_name = cur_name
			cur_dir_node.dir_path = (cur_node.dir_path+"/"+cur_name).trim_prefix("/")
			cur_dir_node.parent_node = cur_node
			cur_node.dirs[cur_name] = cur_dir_node
			get_cur_node = cur_dir_node
		cur_node = get_cur_node
	return cur_node


func create_file_merge_node(file_path):
	file_path = file_path.simplify_path()
	var cur_dir_node = create_dir_merge_node(file_path.get_base_dir())
	var cur_file_node = FileMergeNode.new()
	cur_file_node.file_name = file_path.get_file()
	cur_file_node.file_path= file_path.trim_prefix("/")
	cur_file_node.parent_node = cur_dir_node
	cur_dir_node.files[cur_file_node.file_name] = cur_file_node
	return cur_file_node


var root_node = null
func _init_root_node():
	root_node = DirMergeNode.new()

func get_ui_instance():
	var cur_node = load(get_absolute_path("ui/main.tscn")).instantiate()
	return cur_node

class FileSyncInfo:
	var uid = ""
	var adapter_name = ""
	var adapter_need_data = {} 
	var mapping_path = ""
	var include = ""
	var exclude = ""
	var from_uid = ""
	var from_path = ""
	var is_used = false


class FileMergeNode:
	var file_name = ""
	var file_path = ""
	var parent_node = null
	var merge_file_node = {}
	func get_type_name():
		return "FileMergeNode"

	
class FileNode:
	var used_file_sync_uid = ""
	var sub_path = "" # we need plus DirNode.sub_path and FileSyncInfo.sub_path to get real_path
	var file_name = ""
	var file_path = ""
	var save_path = ""
	var parent_node = null
	var merge_node = null
	
	
	func get_type_name():
		return "FileNode"
	


class DirMergeNode:
	var dir_name = ""
	var dir_path = ""
	var parent_node = null
	var merge_dir_node = {}
	var files = {}	# merge_file_node
	var dirs = {}	# merge_dir_node

	func get_file_node(cur_file_name):
		return files.get(cur_file_name,null)
	
	func get_dir_node(cur_dir_name):
		return dirs.get(cur_dir_name,null)

	func get_type_name():
		return "DirMergeNode"

class DirNode:
	var files = {}	# file_node
	var dirs = {}	# dir_node
	var parent_node = null
	
	var used_file_sync_uid = ""
	var sub_path = "" # we need plus DirNode.sub_path and FileSyncInfo.sub_path to get real_path
	var dir_name = ""
	var dir_path = ""
	var save_path = ""
	var merge_node = null
	
	func get_file_node(cur_file_name):
		return files.get(cur_file_name,null)
	
	func get_dir_node(cur_dir_name):
		return dirs.get(cur_dir_name,null)
	
	func get_type_name():
		return "DirNode"
