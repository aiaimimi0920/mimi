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
func fs_list(sub_path):
	var all_files = []
	var all_dirs = []
	var base_path = "%s/ipfs/%s"%[gatway,sub_path]
	base_path = base_path.simplify_path()
	base_path = base_path+"/"
	
	var http = HTTPClient.new()
	var host_path = get_host_and_path(base_path)
	var err = http.connect_to_host(host_path[0])
	assert(err == OK)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		await get_tree().process_frame
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
	
	var need_search_dir = []
	need_search_dir.append(host_path[1])
	while need_search_dir.size()>0:
		var new_path = need_search_dir.pop_front()
		err = http.request(HTTPClient.METHOD_GET, new_path, [], "")

		assert(err == OK)
		while http.get_status() == HTTPClient.STATUS_REQUESTING:
			http.poll()
			await get_tree().process_frame
		assert(http.get_status() == HTTPClient.STATUS_BODY)
		var is_html = false
		if http.has_response():
			# If there is a response...
			var headers = http.get_response_headers_as_dictionary()
			if headers.get("Content-Type","").contains("text/html") or headers.get("content-type","").contains("text/html"):
				is_html = true
			if is_html == true:
				if http.is_response_chunked():
					# Does it use chunks?
					print("Response is Chunked!")
				else:
					# Or just plain Content-Length
					var bl = http.get_response_body_length()

				var rb = PackedByteArray() # Array that will hold the data.

				while http.get_status() == HTTPClient.STATUS_BODY:
					# While there is body left to be read
					http.poll()
					# Get a chunk.
					var chunk = http.read_response_body_chunk()
					if chunk.size() == 0:
						await get_tree().process_frame
					else:
						rb = rb + chunk

				var html = rb.get_string_from_utf8()
				
				var path_regex = RegEx.new()
				var cur_ipfs_path = base_path.trim_prefix(gatway)
				if not cur_ipfs_path.ends_with("/"):
					cur_ipfs_path = cur_ipfs_path + "/"
				path_regex.compile("\"%s(?<path>.*?)\""%cur_ipfs_path)
				
				all_dirs.append(new_path)
				for path_result in path_regex.search_all(html):
					var cur_path = path_result.get_string("path").strip_edges()
					if cur_ipfs_path.path_join(cur_path)+"/" == new_path or cur_ipfs_path.path_join(cur_path) == new_path + "..":
						pass
					else:
						need_search_dir.append(cur_ipfs_path.path_join(cur_path))
			else:
				all_files.append(new_path)
	
	var ret_files = []
	var ret_dirs = []
	for file in all_files:
		ret_files.append(file.trim_prefix("/ipfs/"))
	
	for dir in all_dirs:
		ret_dirs.append(dir.trim_prefix("/ipfs/"))
	
	all_files = ret_files
	all_dirs = ret_dirs
	
	for file in all_files:
		var file_dir = file.get_base_dir()
		if file_dir not in all_dirs:
			all_dirs.append(file_dir)
	
	return [all_files, all_dirs]

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


func get_host_and_path(uri):
	var host = uri
	var path = ""
	var uri_array = uri.split("://",false,1)
	if uri_array.size()>=2:
		var cur_path_array = uri_array[1].split("/",false,1)
		host = uri_array[0]+"://" + cur_path_array[0]
		path = cur_path_array[1]
		path.trim_prefix("/")
		path = "/" + path
	return [host,path]

func ipfs_get_file(base_path,cur_save_dir, cmd, use_native=false):
	var http = HTTPClient.new()
	var host_path = get_host_and_path(base_path)
	var err = http.connect_to_host(host_path[0])
	assert(err == OK)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		await get_tree().process_frame
	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)

	err = http.request(HTTPClient.METHOD_GET, host_path[1], [], "")

	assert(err == OK)
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		await get_tree().process_frame
	assert(http.get_status() == HTTPClient.STATUS_BODY)
	var is_html = false
	if http.has_response():
		# If there is a response...
		var headers = http.get_response_headers_as_dictionary()
		if headers.get("Content-Type","").contains("text/html") or headers.get("content-type","").contains("text/html"):
			is_html = true
		if is_html == true:
			if http.is_response_chunked():
				# Does it use chunks?
				print("Response is Chunked!")
			else:
				# Or just plain Content-Length
				var bl = http.get_response_body_length()

			var rb = PackedByteArray() # Array that will hold the data.

			while http.get_status() == HTTPClient.STATUS_BODY:
				# While there is body left to be read
				http.poll()
				# Get a chunk.
				var chunk = http.read_response_body_chunk()
				if chunk.size() == 0:
					await get_tree().process_frame
				else:
					rb = rb + chunk

			DirAccess.make_dir_recursive_absolute(cur_save_dir.uri_decode())
			var html = rb.get_string_from_utf8()
			
			var path_regex = RegEx.new()
			var cur_ipfs_path = base_path.trim_prefix(gatway)
			path_regex.compile("\"%s(?<path>.*?)\""%cur_ipfs_path)
			for path_result in path_regex.search_all(html):
				var cur_path = path_result.get_string("path").strip_edges()
				ipfs_get_file(base_path.path_join(cur_path),cur_save_dir.path_join(cur_path),cmd)
		else:
			if cmd:
				cmd.time += 1
			if use_native==true:
				if http.is_response_chunked():
					# Does it use chunks?
					print("Response is Chunked!")
				else:
					# Or just plain Content-Length
					var bl = http.get_response_body_length()
	
				var rb = PackedByteArray() # Array that will hold the data.
	
				while http.get_status() == HTTPClient.STATUS_BODY:
					# While there is body left to be read
					http.poll()
					# Get a chunk.
					var chunk = http.read_response_body_chunk()
					if chunk.size() == 0:
						await get_tree().process_frame
					else:
						rb = rb + chunk
	
				var file = FileAccess.open(cur_save_dir.uri_decode(), FileAccess.WRITE)
				file.store_buffer(rb)
				file.close()

			else:
				http.close()				
				var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
				var options = {}
				options["out"] = cur_save_dir.get_file()
				options["dir"] = cur_save_dir.get_base_dir()
				var download_gid = await downloader_list.new_task([base_path],
					options,"aria2_adapter")
				var is_finish = await downloader_list.wait_task(download_gid, 4)
				is_finish = await downloader_list.delete_task(download_gid)
			if cmd:
				cmd.time -= 1
			var reader := ZIPReader.new()
			err = reader.open(cur_save_dir.uri_decode())
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
