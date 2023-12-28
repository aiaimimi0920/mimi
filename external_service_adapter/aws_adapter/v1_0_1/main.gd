extends PluginAPI
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"aws_adapter","mimi",plugin_version,"It is possible to call the functions of AWS",
		"service",{"downloader_list":["v1_0_0"],"file_list":["v1_0_1"]})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	

func _ready()->void:
	service_utils = load(get_absolute_path("modules/utils.gd")).new()
	service_s3 = load(get_absolute_path("modules/s3.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()


var service_utils
var service_s3
var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	service_s3.name = "s3"
	service_utils.name = "utils"
	add_child(service_config_manager,true)
	add_child(service_utils,true)
	add_child(service_s3,true)
	service_config_manager.init_config()


func _config_loaded()->void:
	var file_list = await PluginManager.get_plugin_instance_by_script_name("file_list")
	file_list.trigger_file_adapter(plugin_name, 0)

func get_fs_list_need_args():
	return {"path":"","region":"","bucket":"","access_key":"","secret_key":"","service":""}

## List all files and file directories under a certain path
func fs_list(adapter_need_data):
	var path = adapter_need_data["path"]
	var region = adapter_need_data["region"]
	var bucket = adapter_need_data["bucket"]
	var access_key = adapter_need_data["access_key"]
	var secret_key = adapter_need_data["secret_key"]
	var service = adapter_need_data["service"]
	return await service_s3.fs_list(path, region, bucket, access_key, secret_key, service)


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
	return {"path":"","base_dir_path":"","region":"","bucket":"","access_key":"","secret_key":"","service":""}

## Form upload file
func fs_upload_form(adapter_need_data):
	var path = adapter_need_data["path"]
	var base_dir_path = adapter_need_data["base_dir_path"]
	var region = adapter_need_data["region"]
	var bucket = adapter_need_data["bucket"]
	var access_key = adapter_need_data["access_key"]
	var secret_key = adapter_need_data["secret_key"]
	var service = adapter_need_data["service"]
	return await service_s3.fs_upload_form(path, base_dir_path, region, bucket, access_key, secret_key, service)


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
	return {"path":"","save_dir":"","region":"","bucket":"","access_key":"","secret_key":"","service":""}

## download files or folders
func fs_download(adapter_need_data):
	var path = adapter_need_data["path"]
	var save_dir = adapter_need_data["save_dir"]
	var region = adapter_need_data["region"]
	var bucket = adapter_need_data["bucket"]
	var access_key = adapter_need_data["access_key"]
	var secret_key = adapter_need_data["secret_key"]
	var service = adapter_need_data["service"]
	return await service_s3.fs_download(path, save_dir, region, bucket, access_key, secret_key, service)
