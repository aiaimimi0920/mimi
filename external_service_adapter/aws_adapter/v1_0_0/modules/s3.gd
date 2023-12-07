extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)
var service_utils:
	get:
		return plugin_node.service_utils

var save_dir = GlobalManager.globalize_file_path

var boundary = "boundary"

## List all files and file directories under a certain path
func fs_list(sub_path, region="", bucket="", access_key="", secret_key="", service="", all_files = null,all_dirs = null,continuation_token=null):
	sub_path = sub_path.simplify_path()

	if not sub_path.ends_with("/"):
		sub_path = sub_path+"/"

	var query_string_map = {}
	query_string_map["list-type"] = "2"
	query_string_map["prefix"] = sub_path
	if continuation_token:
		query_string_map["continuation-token"] = continuation_token
	
	if all_files == null:
		all_files = []
	if all_dirs == null:
		all_dirs = []

	await service_utils.http_request(
		HTTPClient.METHOD_GET,
		"/",
		"",
		query_string_map,
		"",
		null,
		fs_list_all_chunk_call.bind(all_dirs,all_files,[sub_path, region, bucket, access_key, secret_key, service, continuation_token]),
		null,
		region,
		bucket,
		access_key,
		secret_key,
		service,
	)
	for file in all_files:
		var file_dir = file.get_base_dir()
		if file_dir not in all_dirs:
			all_dirs.append(file_dir)
	
	return [all_files, all_dirs]


func fs_list_all_chunk_call(rb, all_dirs, all_files, call_cmd):
	var parser = XMLParser.new()
	parser.open_buffer(rb)
	var all_data = {"Key":[]}
	var now_key = null
	while parser.read() != ERR_FILE_EOF:
		if parser.get_node_type() == XMLParser.NODE_ELEMENT:
			var node_name = parser.get_node_name()
			now_key = node_name
		elif parser.get_node_type() == XMLParser.NODE_ELEMENT_END:
			now_key = null
			pass
		elif parser.get_node_type() == XMLParser.NODE_TEXT:
			if now_key:
				if now_key == "Key":
					all_data[now_key].append(parser.get_node_data())
				elif now_key == "IsTruncated":
					all_data[now_key] = false if parser.get_node_data() == "false" else true
				elif now_key == "NextContinuationToken":
					all_data[now_key] = parser.get_node_data()
	if all_data.get("IsTruncated",false) == true:
		await fs_list(call_cmd[0], call_cmd[1], call_cmd[2], call_cmd[3], call_cmd[4], call_cmd[5], all_files, all_dirs, all_data["NextContinuationToken"])
	all_files.append_array(all_data["Key"])
	return

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


func fs_upload_form_all_chunk_call(rb):
	var text = rb.get_string_from_ascii()
	print("Text: ", text)

var now_upload_form_call = {}
## Form upload file
func fs_upload_form(sub_path, base_dir_path="", region="", bucket="", access_key="", secret_key="", service=""):
	sub_path = sub_path.simplify_path()
	base_dir_path = base_dir_path.simplify_path()
	var call_md5 = (sub_path+base_dir_path+region+bucket+access_key+secret_key+service).md5_text()
	var cmd
	if call_md5 in now_upload_form_call:
		cmd = now_upload_form_call[call_md5]
	else:
		cmd = service_utils.RequestInstance.new()
		now_upload_form_call[call_md5] = cmd
		var all_files = []
		if base_dir_path == "":
			base_dir_path = sub_path.get_base_dir()
		if DirAccess.dir_exists_absolute(sub_path):
			all_files = get_all_files(sub_path)
			pass
		else:
			all_files = [sub_path]
		
		for file_path in all_files:
			var file = FileAccess.open(file_path, FileAccess.READ)
			var data = file.get_buffer(file.get_length())
			var query_url_path = ProjectSettings.globalize_path(file_path).trim_prefix(ProjectSettings.globalize_path(base_dir_path))

			service_utils.http_request(
				HTTPClient.METHOD_PUT,
				query_url_path,
				"",
				{},
				data,
				null,
				fs_upload_form_all_chunk_call,
				cmd,
				region,
				bucket,
				access_key,
				secret_key,
				service,
			)

	await cmd.request_finished
	var result_path = ProjectSettings.globalize_path(sub_path).trim_prefix(ProjectSettings.globalize_path(base_dir_path))
	var result_region = region if (region and region != "") else plugin_node.service_config_manager.region_name
	var result_bucket = bucket if (bucket and bucket != "") else plugin_node.service_config_manager.bucket_name
	var result_service = service if (service and service != "") else plugin_node.service_config_manager.service_name
	return [result_path.trim_prefix("/"), result_region, result_bucket, result_service]

func get_all_files(dir_path):
	var dir = DirAccess.open(dir_path)
	var cur_files = dir.get_files()
	for i in range(len(cur_files)):
		cur_files[i] = dir_path.path_join(cur_files[i]).simplify_path()
	for key in dir.get_directories():
		cur_files.append_array(get_all_files(dir_path.path_join(key)))
		pass
	return cur_files

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

var now_download_call = {}
## download files or folders
func fs_download(sub_path, cur_save_dir="", region="", bucket="", access_key="", secret_key="", service=""):
	sub_path = sub_path.simplify_path()
	cur_save_dir = cur_save_dir.simplify_path()
	var call_md5 = (sub_path+cur_save_dir+region+bucket+access_key+secret_key+service).md5_text()
	var cmd
	if call_md5 in now_download_call:
		cmd = now_download_call[call_md5]
	else:
		cmd = service_utils.RequestInstance.new()
		now_download_call[call_md5] = cmd
		if cur_save_dir == "":
			cur_save_dir = save_dir
		var all_files_dirs = await fs_list(sub_path, region, bucket, access_key, secret_key, service)
		printt("all_files_dirs",all_files_dirs)
		var all_files = []
		if len(all_files_dirs[0]) == 0:
			## The explanation is actually a file
			all_files = [sub_path]
		else:
			all_files = all_files_dirs[0]
		
		cmd.data["save_dir"] = cur_save_dir.path_join(sub_path)
		
		for sub_file_path in all_files:
			var save_path = cur_save_dir.path_join(sub_file_path).uri_decode()
			## The logic of deleting downloaded files and determining whether they need to be re downloaded has already been done in the outer layer, 
			## which belongs to the business layer logic. Simply delete it here
			DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
			DirAccess.remove_absolute(save_path)
			printt("save_path",save_path)
			var file = FileAccess.open(save_path, FileAccess.WRITE)
			service_utils.http_request(
				HTTPClient.METHOD_GET,
				sub_file_path,
				"",
				{},
				"",
				fs_download_chunk_call.bind(file),
				fs_download_all_chunk_call.bind(file),
				cmd,
				region,
				bucket,
				access_key,
				secret_key,
				service,
			)
	await cmd.request_finished
	var save_dir = cmd.data["save_dir"]
	now_download_call.erase(call_md5)
	return save_dir


func fs_download_chunk_call(rb,file):
	file.store_buffer(rb)
	return

func fs_download_all_chunk_call(rb, file):
	file.close()
	return


