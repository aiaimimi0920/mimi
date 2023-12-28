extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var save_dir = GlobalManager.globalize_file_path

## List all files and file directories under a certain path
func fs_list(sub_path):
	var all_files = FileManager.scan(sub_path)
	
	var all_dirs = []
	for file in all_files:
		var file_dir = file.get_base_dir()
		if file_dir not in all_dirs:
			all_dirs.append(file_dir)
	
	var ret_all_files = []
	var ret_all_dirs = []
	for file in all_files:
		ret_all_files.append(file.simplify_path().trim_prefix("/"))
	for dir in all_dirs:
		ret_all_dirs.append(dir.simplify_path().trim_prefix("/"))

	return [ret_all_files, ret_all_dirs]


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

var now_upload_form_call = {}
## Form upload file
func fs_upload_form(sub_path, target_path =""):
	sub_path = sub_path.simplify_path()
	target_path = target_path.simplify_path()
	FileManager.copy_directory_recursively(sub_path,target_path)
	return [target_path]

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
func fs_download(sub_path, cur_save_dir=""):
	sub_path = sub_path.simplify_path()
	cur_save_dir = cur_save_dir.simplify_path()
	var save_dir = cur_save_dir.path_join(sub_path.get_file())
	FileManager.copy_directory_recursively(sub_path,save_dir)
	return save_dir

