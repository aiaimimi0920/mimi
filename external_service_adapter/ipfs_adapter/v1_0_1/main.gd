extends PluginAPI
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"ipfs_adapter","mimi",plugin_version,"It is possible to call the functions of ipfs",
		"service",{"downloader_list":["v1_0_0"],"file_list":["v1_0_1"]})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	
func _ready()->void:
	service_pinata = load(get_absolute_path("modules/pinata.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	pass

var service_pinata
var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	service_pinata.name = "pinata"
	add_child(service_config_manager,true)
	add_child(service_pinata,true)
	service_config_manager.init_config()

func _config_loaded()->void:
	var file_list = await PluginManager.get_plugin_instance_by_script_name("file_list")
	file_list.trigger_file_adapter(plugin_name, 0)

func get_fs_list_need_args():
	return {"path":""}

## List all files and file directories under a certain path
func fs_list(adapter_need_data):
	var ipfs_id = adapter_need_data["path"]
	return await service_pinata.fs_list(ipfs_id)

func get_fs_get_info_need_args():
	return {}

## TODO:Get information about a certain file/directory
func fs_get_info(adapter_need_data):
	pass

func get_fs_dirs_need_args():
	return {}

## TODO:Get all directories under a certain path
func fs_dirs(adapter_need_data):
	pass

func get_fs_search_need_args():
	return {}

## TODO:Search for files or folders
func fs_search(adapter_need_data):
	pass

func get_fs_mkdir_need_args():
	return {}

## TODO:Create a new folder
func fs_mkdir(adapter_need_data):
	pass

func get_fs_rename_need_args():
	return {}

## TODO:rename file
func fs_rename(adapter_need_data):
	pass

func get_fs_batch_rename_need_args():
	return {}

## TODO:batch rename file
func fs_batch_rename(adapter_need_data):
	pass


func get_fs_regex_rename_need_args():
	return {}

## TODO:Regular renaming file
func fs_regex_rename(adapter_need_data):
	pass

func get_fs_upload_form_need_args():
	return {"path":"","pinta_key":""}

## Form upload file
func fs_upload_form(adapter_need_data):
	var path = adapter_need_data["path"]
	var pinta_key = adapter_need_data["pinta_key"]
	return await service_pinata.fs_upload_form(path, pinta_key)
	
func get_fs_upload_put_need_args():
	return {}

## TODO:Streaming file upload
func fs_upload_put(adapter_need_data):
	pass


func get_fs_move_need_args():
	return {}

## TODO:move file
func fs_move(adapter_need_data):
	pass

func get_fs_copy_need_args():
	return {}

## TODO:copy file
func fs_copy(adapter_need_data):
	pass

func get_fs_remove_need_args():
	return {}

## TODO:remove files or folders
func fs_remove(adapter_need_data):
	pass

func get_fs_remove_empty_directory_need_args():
	return {}

## TODO:remove empty folder
func fs_remove_empty_directory(adapter_need_data):
	pass

func get_fs_recursive_move_need_args():
	return {}

## TODO:recursive move file
func fs_recursive_move(adapter_need_data):
	pass

func get_fs_download_need_args():
	return {"path":"","save_dir":""}

## download files or folders
func fs_download(adapter_need_data):
	var path = adapter_need_data["path"]
	var save_dir = adapter_need_data["save_dir"]
	return await service_pinata.fs_download(path, save_dir)
