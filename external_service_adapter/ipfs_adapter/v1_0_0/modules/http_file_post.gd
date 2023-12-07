extends HTTPRequest

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var boundary = "boundary"

var body_begin = ""
var body_content_array = []
var body_end = ""

func init_all_data():
	body_begin = ""
	body_content_array = []
	body_end = ""


func post_file(url: String, field_name: String, file_path: String, post_fields: Dictionary = {}, content_type: String = "", custom_headers: Array = []):
	init_all_data()
	add_begin(post_fields, custom_headers)
	var file_name = file_path.get_file()
	add_one_file(field_name,file_name,file_path,content_type)
	add_end()
	send(url,custom_headers)
	
func post_dir(url: String, field_name: String, dir_path: String, post_fields: Dictionary = {}, custom_headers: Array = []):
	init_all_data()
	add_begin(post_fields, custom_headers)
	var files = get_all_files(dir_path)
	for file_path in files:
		var file_name = file_path.simplify_path().replace("\\","/").trim_prefix(dir_path.simplify_path().get_base_dir().replace("\\","/"))
		var content_type = ""
		file_path = file_path.lstrip("/")
		add_one_file(field_name,file_name,file_path,content_type)
	add_end()
	send(url,custom_headers)

func get_all_files(dir_path):
	var dir = DirAccess.open(dir_path)
	var cur_files = dir.get_files()
	for i in range(len(cur_files)):
		cur_files[i] = dir_path.path_join(cur_files[i]).simplify_path()
	for key in dir.get_directories():
		cur_files.append_array(get_all_files(dir_path.path_join(key)))
		pass
	return cur_files

func add_begin(post_fields, custom_headers):
	custom_headers.append("Content-Type: multipart/form-data; boundary=" + boundary)
	body_begin = "\r\n\r\n"
	for key in post_fields:
		body_begin += "--" + boundary + "\r\n"
		body_begin += "Content-Disposition: form-data; name=\"" + key + "\"\r\n\r\n" + post_fields[key] + "\r\n"
	return

func add_one_file(field_name,file_name,file_path,content_type):
	## Note that this is a special logic for IPFS uploading. If it is a file ending in PCK, 
	## compress the file into zip format before uploading, because Pinata does not support uploading PCK files
	var file = FileAccess.open(file_path, FileAccess.READ)
	var data = file.get_buffer(file.get_length())
	if file_path.get_extension() in plugin_node.service_config_manager.need_zip_file:
		var writer := ZIPPacker.new()
		var err := writer.open(file_path+".zip")
		if err != OK:
			return err
		var add_file_name = file_name.get_file()
		writer.start_file(add_file_name)
		writer.write_file(data)
		writer.close_file()
		writer.close()
		add_one_file(field_name, file_name+".zip", file_path+".zip", content_type)
		return 
	var body_content = ""
	body_content += "--" + boundary + "\r\n"
	body_content += "Content-Disposition: form-data; name=\"" + field_name + "\"; filename=\"Root/" + file_name + "\"\r\nContent-Type: "
	if content_type != "":
		body_content += content_type
	elif data is String:
		body_content += "text/plain"
	else:
		body_content += "application/octet-stream"
		#body_content += "text/plain"
	body_content += "\r\n\r\n"
	if data is String:
		body_content += data
		body_content_array.append(body_content.to_utf8_buffer())
	elif data is PackedByteArray:
		body_content = body_content.to_utf8_buffer()+data
		body_content_array.append(body_content)


func add_end():
	body_end = "\r\n" + "--" + boundary + "--"
	return

func send(url,custom_headers):
	var post_content
	post_content = body_begin.to_utf8_buffer()
	for cur_content in body_content_array:
		if cur_content is String:
			post_content = post_content + cur_content.to_utf8_buffer() + "\r\n".to_utf8_buffer()
		elif cur_content is PackedByteArray:
			post_content = post_content + cur_content + "\r\n".to_utf8_buffer()
	post_content = post_content+body_end.to_utf8_buffer()
	var err = request_raw(url, custom_headers, HTTPClient.METHOD_POST, post_content)
