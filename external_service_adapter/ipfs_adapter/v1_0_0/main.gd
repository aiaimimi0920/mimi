extends PluginAPI
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"ipfs_adapter","mimi",plugin_version,"It is possible to call the functions of ipfs","service",{})
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
	pass



## List all files and file directories under a certain path
func fs_list(ipfs_id):
	return await service_pinata.fs_list(ipfs_id)

## TODO:Get information about a certain file/directory
func fs_get_info():
	pass

## TODO:Get all directories under a certain path
func fs_dirs():
	pass

## TODO:Search for files or folders
func fs_search():
	pass

## TODO:Create a new folder
func fs_mkdir():
	pass

## TODO:rename file
func fs_rename():
	pass

## TODO:batch rename file
func fs_batch_rename():
	pass

## TODO:Regular renaming file
func fs_regex_rename():
	pass


## Form upload file
func fs_upload_form(sub_path, pinta_key=""):
	return await service_pinata.fs_upload_form(sub_path, pinta_key)

## TODO:Streaming file upload
func fs_upload_put():
	pass

## TODO:move file
func fs_move():
	pass

## TODO:copy file
func fs_copy():
	pass

## TODO:remove files or folders
func fs_remove():
	pass

## TODO:remove empty folder
func fs_remove_empty_directory():
	pass

## TODO:recursive move file
func fs_recursive_move():
	pass

## download files or folders
func fs_download(ipfs_id,cur_save_dir="",):
	return await service_pinata.fs_download(ipfs_id,cur_save_dir)
