extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

signal update_global_stat
signal update_download_handle
signal download_start
signal download_pause
signal download_stop
signal download_complete
signal download_error
signal bt_download_complete

var task_map = {}

func get_gid(gid, auto_create=false):
	return download_handle_map.get(gid,null)

var download_speed = 0
var upload_speed = 0
var num_active = 0
var num_waiting = 0
var num_stopped = 0

func polling():
	await get_tree().create_timer(0.5).timeout
	download_speed = 0
	upload_speed = 0
	num_active = 0
	num_waiting = 0
	num_stopped = 0
	
	for key in download_handle_map:
		var cur_handle = download_handle_map[key]
		download_speed += cur_handle.download_speed
		upload_speed += cur_handle.upload_speed
		if cur_handle.status == DownloadStatus.DOWNLOAD_ACTIVE:
			num_active+=1
		elif cur_handle.status == DownloadStatus.DOWNLOAD_WAITING:
			num_waiting+=1
		elif cur_handle.status == DownloadStatus.DOWNLOAD_REMOVED or cur_handle.status == DownloadStatus.DOWNLOAD_ERROR or cur_handle.status == DownloadStatus.DOWNLOAD_PAUSED:
			num_stopped+=1

	emit_signal("update_global_stat", download_speed,upload_speed,num_active,num_waiting,num_stopped)
	polling()

func _ready():
	polling()

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


func new_task(uris, options):
	var download_handle
	var gids = []
	for uri in uris:
		var host_path = get_host_and_path(uri)
		download_handle = create_download_handle(HTTPClient.Method.METHOD_GET,host_path[0],host_path[1],PackedStringArray(options.get("header","").split(",",false)),"",
			options,plugin_node.service_config_manager.download_dir,uri.get_file())
		download_handle.connect("download_start",download_start_func)
		download_handle.connect("download_pause",download_pause_func)
		download_handle.connect("download_stop",download_stop_func)
		download_handle.connect("download_complete",download_complete_func)
		download_handle.connect("download_error",download_error_func)
		download_handle.connect("bt_download_complete",bt_download_complete_func)
		download_handle.begin_download()
		gids.append(download_handle.get_download_handle_md5())
	return gids

func download_start_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 1
	call_deferred("emit_signal", "download_start", gid)

func download_pause_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 2
	call_deferred("emit_signal", "download_pause", gid)
	
func download_stop_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 3
	call_deferred("emit_signal", "download_stop", gid)

func download_complete_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 4
	call_deferred("emit_signal", "download_complete", gid)

func download_error_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 5
	call_deferred("emit_signal", "download_error", gid)

func bt_download_complete_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 6
	call_deferred("emit_signal", "bt_download_complete", gid)

	

func new_metalink_task(metalink_file_path, options):
	## TODO:
	return []

func new_bt_task(bt_file_path, options):
	## TODO:
	return ""



func all_task_list():
	return download_handle_map.keys()

func active_task_list():
	return []

func waiting_task_list():
	return []

func stopped_task_list():
	return []

func delete_task(gid, force=false,delete_file=false):
	if gid in download_handle_map:
		download_handle_map[gid].close_download()
		
	if delete_file:
		for cur_file_info in download_handle_map[gid].files:
			DirAccess.remove_absolute(cur_file_info["path"])
	return true

func resume_task(gid):
	## TODO:
	return -1
	
func pause_task(gid, force=false):
	## TODO:
	return -1

func change_position(gid, pos, how=1):
	## TODO:
	return -1

func pause_all_tasks(force=false):
	## TODO:
	return -1

func resume_all_tasks():
	## TODO:
	return -1


func get_body_hash(body):
	var payload_hash
	if typeof(body) == TYPE_STRING:
		payload_hash = body.sha256_text()
	elif typeof(body) == TYPE_PACKED_BYTE_ARRAY:
		var ctx = HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(body)
		payload_hash = ctx.finish()
		payload_hash = payload_hash.hex_encode()
	return payload_hash

func get_options_hash(options):
	var cur_options_md5=""
	for key in options:
		cur_options_md5 += (key+options[key]).md5_text()
	cur_options_md5 = cur_options_md5.md5_text()
	return cur_options_md5

func download_chunk_call(rb,file):
	#var file = FileAccess.open(target_save_path, FileAccess.WRITE)
	file.seek_end()
	file.store_buffer(rb)
	#file.close()
	return true

func download_all_chunk_call(rb, file):
	#var file = FileAccess.open(target_save_path, FileAccess.WRITE)
	#file.close()
	return true

var download_handle_map = {}

func create_download_handle(method: HTTPClient.Method, host: String, url:String, headers: PackedStringArray, body, options, save_dir, save_name):
	save_dir = save_dir.simplify_path()
	save_name = save_name.simplify_path()
	var download_handle_md5 = (save_dir+save_name).md5_text()
	var cur_download_handle
	if download_handle_md5 in download_handle_map:
		cur_download_handle = download_handle_map[download_handle_md5]
		if cur_download_handle.host != host or cur_download_handle.url != url or cur_download_handle.headers!=headers\
			or get_body_hash(cur_download_handle.body)!= get_body_hash(body) or get_options_hash(cur_download_handle.options)!= get_options_hash(options)\
			or cur_download_handle.dir!= save_dir or cur_download_handle.save_name!= save_name or cur_download_handle.method!= method:
			## close old download , create new download
			cur_download_handle.close_download()
		else:
			return cur_download_handle
	
	cur_download_handle = DownloadHandle.new()
	add_child(cur_download_handle)
	cur_download_handle.gid = download_handle_md5
	cur_download_handle.host = host
	cur_download_handle.url = url
	cur_download_handle.headers = headers
	cur_download_handle.dir = save_dir
	cur_download_handle.options = options
	cur_download_handle.save_name = save_name
	cur_download_handle.body = body
	cur_download_handle.method = method
	var target_save_path = cur_download_handle.get_save_path()
	cur_download_handle.files = [{
			"index":0,
			"path":target_save_path,
			"length":0,
			"completed_length":0,
			"selected":true,
			"used_uris":[url],
			"waiting_uris":[],
		}
	]
	
	DirAccess.make_dir_recursive_absolute(target_save_path.get_base_dir())
	DirAccess.remove_absolute(target_save_path)
	
	cur_download_handle.chunk_call = download_chunk_call
	cur_download_handle.all_chunk_call = download_all_chunk_call
	download_handle_map[download_handle_md5] = cur_download_handle
	return cur_download_handle

enum DownloadStatus {DOWNLOAD_ACTIVE, DOWNLOAD_WAITING, DOWNLOAD_PAUSED, DOWNLOAD_COMPLETE, DOWNLOAD_ERROR, DOWNLOAD_REMOVED}
 
class DownloadHandle:
	extends Node
	var gid=""
	var status:DownloadStatus = DownloadStatus.DOWNLOAD_ACTIVE
	var total_length=0
	var completed_length=0
	var upload_length=0
	var download_speed=0
	var upload_speed = 0
	var info_hash=""
	var error_code=0
	var host
	var url
	var headers
	var dir=""
	var connections=0
	var files=[]
	var options={}
	var save_name = ""
	var chunk_call
	var all_chunk_call
	var body
	var method
	var http
	signal download_start
	signal download_pause
	signal download_stop
	signal download_complete
	signal download_error
	signal bt_download_complete

	var time = 0
	
	var download_length_map = []
	
	var last_event_type = -1
	var following = 0
	
	func get_save_path():
		return ProjectSettings.globalize_path(dir.path_join(save_name))
	
	func get_download_handle_md5():
		return (dir+save_name).md5_text()
	
	func close_download():
		if http:
			http.close()
		status = DownloadStatus.DOWNLOAD_COMPLETE
		download_speed = 0
		last_event_type = 4
		emit_signal("download_complete",get_download_handle_md5())
		#queue_free()

	func begin_download():
		status = DownloadStatus.DOWNLOAD_ACTIVE
		time += 1
		if time==1:
			last_event_type = 1
			emit_signal("download_start",get_download_handle_md5())
			runing_download()
			polling()
			return true
		else:
			return true
		
	
	func runing_download():
		var target_save_path = get_save_path()
		http = HTTPClient.new()
		var err = http.connect_to_host(host)
		assert(err == OK)
		while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
			http.poll()
			await get_tree().process_frame
		
		assert(http.get_status() == HTTPClient.STATUS_CONNECTED)

		if typeof(body)==TYPE_STRING:
			err = http.request(method, url, headers, body)
		elif typeof(body)==TYPE_PACKED_BYTE_ARRAY:
			err = http.request_raw(method, url, headers, body)
		
		assert(err == OK)
		while http.get_status() == HTTPClient.STATUS_REQUESTING:
			http.poll()
			await get_tree().process_frame
		
		if http.get_response_code() in [301,302]:
			assert(http.get_status() == HTTPClient.STATUS_BODY)
			var new_headers = http.get_response_headers()
			var response_headers = {}
			for cur_header in new_headers:
				var cur_header_array = cur_header.split(":",false,1)
				response_headers[cur_header_array[0]]=cur_header_array[1]
			var location = response_headers.get("Location",response_headers.get("location",null))
			if location==null:
				emit_signal("download_error",get_download_handle_md5())
				return false
			var host_and_path = get_parent().get_host_and_path(location)
			err = http.connect_to_host(host_and_path[0])
			assert(err == OK)
			while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
				http.poll()
				await get_tree().process_frame
				## TODO:
				emit_signal("download_error",get_download_handle_md5())
				return false
				if typeof(body)==TYPE_STRING:
					err = http.request(method, host_and_path[1], new_headers, body)
				elif typeof(body)==TYPE_PACKED_BYTE_ARRAY:
					err = http.request_raw(method, host_and_path[1], new_headers, body)
				assert(err == OK)
				while http.get_status() == HTTPClient.STATUS_REQUESTING:
					http.poll()
					await get_tree().process_frame

		assert(http.get_status() == HTTPClient.STATUS_BODY)
		if http.has_response():
			if http.is_response_chunked():
				print("Response is Chunked!")
			else:
				var bl = http.get_response_body_length()
				total_length = bl
				files[0]["length"] = total_length
			var rb = PackedByteArray()
			var file = FileAccess.open(target_save_path, FileAccess.WRITE)
			while http.get_status() == HTTPClient.STATUS_BODY:
				http.poll()
				var chunk = http.read_response_body_chunk()
				if chunk.size() == 0:
					file.close()
					await get_tree().create_timer(0.5).timeout
					file = FileAccess.open(target_save_path, FileAccess.WRITE)
				else:
					rb = rb + chunk
				completed_length += chunk.size()
				files[0]["completed_length"] = completed_length
				download_length_map.append([Time.get_unix_time_from_system(), chunk.size()])
				
				if chunk_call != null:
					chunk_call.call(chunk,file)
				await get_tree().process_frame
					
			if all_chunk_call != null:
				all_chunk_call.call(rb,file)
				file.close()
				chunk_call = null
				all_chunk_call = null
				download_length_map = []

		time -= 1
		if time<=0:
			close_download()
		return true
	
	func polling():
		await get_tree().create_timer(0.5).timeout
		var cur_download_speed = 0
		if download_length_map.size()==0:
			cur_download_speed = 0
		else:
			var cur_time = download_length_map[-1][0]-download_length_map[0][0]
			for value in download_length_map:
				cur_download_speed += value[1]
			if cur_time == 0:
				pass
			else:
				cur_download_speed = cur_download_speed/cur_time
		
		download_speed = cur_download_speed
		
		if download_length_map.size()>3:
			download_length_map = download_length_map.slice(-3)
		get_parent().emit_signal("update_download_handle", get_download_handle_md5(), status,completed_length,0,cur_download_speed,0,error_code)
		if status != DownloadStatus.DOWNLOAD_COMPLETE:
			polling()

	
