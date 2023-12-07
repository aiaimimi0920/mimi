extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var save_dir = GlobalManager.globalize_file_path

var gatway:
	get:
		return plugin_node.service_config_manager.gateway

const HTTPFilePost = preload("./http_file_post.gd")

var ipfs_map_path = {}
var path_map_ipfs = {}


class RequestInstance:
	extends RefCounted
	signal request_finished
	var time = 0

var now_download_path = {}

## List all files and file directories under a certain path
func fs_list(ipfs_id):
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

## Form upload file
func fs_upload_form(sub_path, pinta_key="",pin=true):
	var http_request = HTTPFilePost.new()
	add_child(http_request)
	if pinta_key == "":
		pinta_key = plugin_node.service_config_manager.pinata_key
	
	var custom_headers = ["accept:application/json","authorization:Bearer %s"%pinta_key]
	if sub_path.get_extension()=="":
		## is folder
		var base_path = sub_path.simplify_path().split("/")[-1]
		var cur_json = {
			"name":base_path
		}
		var json_string = JSON.stringify(cur_json)
		http_request.post_dir("https://api.pinata.cloud/pinning/pinFileToIPFS","file",sub_path,{"pinataMeatadata":json_string},custom_headers)
		pass
	else:
		## is file
		var base_path = sub_path.simplify_path().get_basename().split("/")[-1]
		var cur_json = {
			"name":base_path
		}
		var json_string = JSON.stringify(cur_json)
		http_request.post_file("https://api.pinata.cloud/pinning/pinFileToIPFS","file",sub_path,{"pinataMeatadata":json_string},"",custom_headers)

	var results = await http_request.request_completed
	var result = results[0]
	var response_code = results[1]
	var headers = results[2]
	var body = results[3]
	var json = JSON.new()
	json.parse(body.get_string_from_utf8())
	var response = json.get_data()
	remove_child(http_request)
	return response["IpfsHash"]


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
func fs_download(ipfs_id, cur_save_dir=""):
	var base_path = "%s/ipfs/%s"%[gatway,ipfs_id]
	cur_save_dir = cur_save_dir.simplify_path()
	if cur_save_dir == "":
		cur_save_dir = save_dir
	cur_save_dir = cur_save_dir.path_join(ipfs_id)
	var cmd:RequestInstance = RequestInstance.new()
	if ipfs_id in now_download_path:
		cmd = now_download_path[ipfs_id]
	else:
		now_download_path[ipfs_id] = cmd
		ipfs_get_file(base_path,cur_save_dir,cmd)
	await cmd.request_finished
	now_download_path.erase(ipfs_id)
	
	var dir = DirAccess.open(cur_save_dir)
	if dir:
		var cur_directories = dir.get_directories()
		if len(cur_directories)>0:
			return cur_save_dir.path_join(cur_directories[0])
		var cur_files = dir.get_files()
		if len(cur_files)>0:
			return cur_save_dir.path_join(cur_files[0])
	return cur_save_dir


func ipfs_get_file(base_path,cur_save_dir,cmd):
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request(base_path)
	cmd.time += 1
	var results = await http_request.request_completed
	var result = results[0]
	var response_code = results[1]
	var headers = results[2]
	var is_html = false
	for header in headers:
		if header == "Content-Type: text/html":
			is_html = true
			break
	var body = results[3]
	remove_child(http_request)
	cmd.time-=1
	if is_html:
		DirAccess.make_dir_recursive_absolute(cur_save_dir.uri_decode())
		var html = body.get_string_from_utf8()
		var path_regex = RegEx.new()
		var cur_ipfs_path = base_path.trim_prefix(gatway)
		path_regex.compile("\"%s/(?<path>.*?)\""%cur_ipfs_path)
		for path_result in path_regex.search_all(html):
			var cur_path = path_result.get_string("path").strip_edges()
			ipfs_get_file(base_path.path_join(cur_path),cur_save_dir.path_join(cur_path),cmd)
	else:
		var file = FileAccess.open(cur_save_dir.uri_decode(), FileAccess.WRITE)
		file.store_buffer(body)
		file.close()
		var reader := ZIPReader.new()
		var err := reader.open(cur_save_dir.uri_decode())
		if err == OK:
			if len(reader.get_files()) == 1:
				var file_name = reader.get_files()[0]
				if file_name.get_extension() in plugin_node.service_config_manager.need_zip_file:
					var res := reader.read_file(file_name)
					var pck_file = FileAccess.open(cur_save_dir.uri_decode().get_base_dir().path_join(file_name), FileAccess.WRITE)
					pck_file.store_buffer(res)
					pck_file.close()
					## delete file
					reader.close()
					DirAccess.remove_absolute(cur_save_dir.uri_decode())
		

	if cmd.time <= 0:
		cmd.emit_signal("request_finished")
	
