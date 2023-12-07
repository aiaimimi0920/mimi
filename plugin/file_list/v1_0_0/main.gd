extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"file_list","mimi",plugin_version,"Provides file storage and download services through various different storage providers.","plugin",
		{"ipfs_adapter":["v1_0_0"],"aws_adapter":["v1_0_0"],"cloudflare_adapter":["v1_0_0"],})
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

var cloud_storage_msp = {
	0:"ipfs_adapter",
	1:"cloudflare_adapter",
	2:"aws_adapter",
}

## TODO:List all files and file directories under a certain path
func fs_list(sub_path, region="", bucket="", access_key="", secret_key="", service="",account_id=""):
	pass

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

## @API
## @brief: Store files or folders through different storage service providers such as IPFS, Cloudflare, AWS, etc
## @param: [sub_path] - The address of the stored file or folder
## @param: [base_dir_path] - The root address of the stored file or folder address
## @param: [use_cloud_storage] - Storage service provider, with a default service provider value of -1, IPFS value of 0, Cloudflare value of 1, and AWS value of 2
## @param: [region] - Storage region when using Cloudflare or AWS
## @param: [bucket] - Storage bucket name when using Cloudflare or AWS
## @param: [access_key] - access_key when using Cloudflare or AWS
## @param: [secret_key] - secret_key when using Cloudflare or AWS
## @param: [service] - service name when using Cloudflare or AWS
## @param: [account_id] - account_id when using Cloudflare
## @param: [pinta_key] - pinta_key when using ipfs
func fs_upload_form(sub_path, base_dir_path="",use_cloud_storage=-1,
					region="", bucket="", access_key="",
					secret_key="", service="",account_id="",
					pinta_key=""):
	if use_cloud_storage == -1:
		use_cloud_storage = service_config_manager.preferred_cloud_storage
		
	var use_cloud_storage_name=cloud_storage_msp[use_cloud_storage]
	var cloud_storage_adapter = await PluginManager.get_plugin_instance_by_script_name(use_cloud_storage_name)
	var result_text = ""
	var result
	if use_cloud_storage_name == "ipfs_adapter":
		result = await cloud_storage_adapter.fs_upload_form(sub_path, pinta_key)
		result_text = "File saved to ipfs, ipfs id: %s"%result
	elif use_cloud_storage_name == "cloudflare_adapter":
		result = await cloud_storage_adapter.fs_upload_form(sub_path, base_dir_path, region,
			bucket,access_key,secret_key,service,account_id)
		result_text = "File saved to cloudflare, file path: {path}, region: {region}, bucket: {bucket}, user id: {account}".format({
			"path":result[0],"region":result[1],"bucket":result[2],"account":result[4]
		})
	elif use_cloud_storage_name == "aws_adapter":
		result = await cloud_storage_adapter.fs_upload_form(sub_path, base_dir_path, region,
			bucket,access_key,secret_key,service)
		result_text = "File saved to AWS, file path: {path}, region: {region}, bucket: {bucket}".format({
			"path":result[0],"region":result[1],"bucket":result[2]
		})
	var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":result_text,"is_bot":true},null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
	return result

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

## @API
## @brief: Download files or folders from different storage service providers such as IPFS, Cloudflare, AWS, etc
## @param: [sub_path] - The file or folder address stored when using Cloudflare or AWS
## @param: [ipfs_id] - The ipfs_id when using ipfs
## @param: [cur_save_dir] - Directory of saved file addresses
## @param: [use_cloud_storage] - Storage service provider, with a default service provider value of -1, IPFS value of 0, Cloudflare value of 1, and AWS value of 2
## @param: [region] - Storage region when using Cloudflare or AWS
## @param: [bucket] - Storage bucket name when using Cloudflare or AWS
## @param: [access_key] - access_key when using Cloudflare or AWS
## @param: [secret_key] - secret_key when using Cloudflare or AWS
## @param: [service] - service name when using Cloudflare or AWS
## @param: [account_id] - account_id when using Cloudflare
func fs_download(sub_path="",ipfs_id="",cur_save_dir="",use_cloud_storage=-1, region="", bucket="", 
			access_key="", secret_key="", service="",account_id=""):
	if use_cloud_storage == -1:
		use_cloud_storage = service_config_manager.preferred_cloud_storage
		
	var use_cloud_storage_name=cloud_storage_msp[use_cloud_storage]
	var cloud_storage_adapter = await PluginManager.get_plugin_instance_by_script_name(use_cloud_storage_name)
	var result_text = ""
	var result
	if use_cloud_storage_name == "ipfs_adapter":
		result = await cloud_storage_adapter.fs_download(ipfs_id, cur_save_dir)
		result_text = "Downloaded file from ipfs, file address: %s"%result
	elif use_cloud_storage_name == "cloudflare_adapter":
		result = await cloud_storage_adapter.fs_download(sub_path, cur_save_dir, region,
			bucket,access_key,secret_key,service,account_id)
		result_text = "Downloaded file from cloudflare, file address: %s"%result
	elif use_cloud_storage_name == "aws_adapter":
		result = await cloud_storage_adapter.fs_download(sub_path, cur_save_dir, region,
			bucket,access_key,secret_key,service)
		result_text = "Downloaded file from aws, file address: %s"%result
	var cur_message = ConversationMessageManager.plugin_create("Plain",{"text":result_text,"is_bot":true},null,plugin_name)
	ConversationManager.plugin_conversation_append_message(plugin_name,cur_message)
	return result
