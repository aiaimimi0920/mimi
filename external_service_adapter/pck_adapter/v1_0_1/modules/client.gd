extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var export_presets_cfg_path:
	get:
		return plugin_node.service_config_manager.export_presets_cfg_path

var export_presets_cfg_backup_path:
	get:
		return plugin_node.service_config_manager.export_presets_cfg_backup_path
		


func create_pck(folder, only_big_version=false):
	create_pck_begin()
	var cur_folder = PluginManager.get_big_version_folder(folder, only_big_version)
	var file_name_list = get_all_files(cur_folder)
	var addons_folder = "res://addons"
	var include_filter = ".godot/*,%s/*"%folder
	if only_big_version:
		## Select only the file with the largest version among them
		include_filter +=",%s/"
		pass
	
	var exclude_filter = []
	var dir = DirAccess.open("res://")
	for cur_dir in dir.get_directories():
		var need_add = true
		for file in file_name_list:
			if file.begins_with(("res://"+cur_dir)):
				need_add = false
				break
		if need_add:
			exclude_filter.append(cur_dir+"/*")
	for file in dir.get_files():
		exclude_filter.append(file)
		
	#printt("file_name_list",file_name_list)
	var channel = modify_export_presets(PackedStringArray(file_name_list),",".join(exclude_filter),include_filter)
	var output = []
	var cur_plugin_pck_path = PluginManager.get_globalize_plugin_file_dir_path(plugin_name).path_join(PluginManager.plugin_pck_name)
	var array = ["--export-pack", str(channel),cur_plugin_pck_path]
	var args = PackedStringArray(array)
	## It is possible to create a new process to package this process, but it is not necessary. 
	## It is more important for developers to ensure the integrity of the packaging, just wait for it to be executed
	OS.execute(OS.get_executable_path(), args, output)
	create_pck_end()
	return cur_plugin_pck_path

func create_pck_begin():
	backup_export_presets()

func create_pck_end():
	restore_export_presets()

## Backup export files
func backup_export_presets():
	var d = DirAccess.copy_absolute(export_presets_cfg_path,export_presets_cfg_backup_path)

## Restore exported files
func restore_export_presets():
	var d = DirAccess.copy_absolute(export_presets_cfg_backup_path,export_presets_cfg_path)
	
func get_all_files(dir_path):
	var dir = DirAccess.open(dir_path)
	var cur_files = dir.get_files()
	for i in range(len(cur_files)):
		cur_files[i] = dir_path.path_join(cur_files[i]).simplify_path()
	for key in dir.get_directories():
		cur_files.append_array(get_all_files(dir_path.path_join(key)))
		pass
	return cur_files

func modify_export_presets(export_files,exclude_filter="",include_filter=""):
	var presets_cfg = ConfigFile.new()
	var err = presets_cfg.load(export_presets_cfg_path)
	var section_name
	for section in presets_cfg.get_sections():
		var platform_name = presets_cfg.get_value(section,"platform")
		if platform_name != "Windows Desktop":
			continue
		section_name = presets_cfg.get_value(section,"name")
		presets_cfg.set_value(section,"export_filter","resources")
		presets_cfg.set_value(section,"export_files",export_files)
		presets_cfg.set_value(section,"exclude_filter",exclude_filter)
		presets_cfg.set_value(section,"include_filter",include_filter)
		break 
	presets_cfg.save(export_presets_cfg_path)
	return section_name
