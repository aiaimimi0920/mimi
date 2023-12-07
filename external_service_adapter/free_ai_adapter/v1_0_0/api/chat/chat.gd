extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var sub_protocol = preload("./sub_protocol.gd")

func _ready():
	register_all_protocol()

func register_all_protocol():
	## Register all server protocols
	var service_protocol_handle = plugin_node.service_protocol_handle
	service_protocol_handle.register_protocol_format_with_object(sub_protocol, self)
	
	## Individual protocols can be registered through other means
	#local_server_protocol_handle.register_c_s_protocol_format(main_protocol_name, sub_protocol_id, sub_protocol.get(c_s_name), Callable(self, c_s_name))
	#local_server_protocol_handle.register_s_c_protocol_format(main_protocol_name, sub_protocol_id, sub_protocol.get(c_s_name), Callable(self, c_s_name))


func init_completions(http=null, https=null,use_http=true):
	if use_http:
		## Directly calling through the HTTP protocol
		var url = plugin_node.get_ai_url().path_join("/v1/chat/init_completions")
		var http_request = HTTPRequest.new()
		add_child(http_request)
		var data = {}
		data["proxies"] = {"http":http, "https":https}
		var body = JSON.new().stringify(data)
		var error = http_request.request(url, [], HTTPClient.Method.METHOD_POST,body)
		if error != OK:
			push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
		
		var response = await http_request.request_completed
		var response_body = JSON.parse_string(response[3].get_string_from_utf8())
		remove_child(http_request)
		return response_body
	else:
		var data = {}
		data["proxies"] = {"http":http, "https":https}
		var result = await C_S_INIT_COMPLETIONS(-1, data)
		return result


func create_chat_completion(stream=false, messages=[],use_http=true):
	if use_http:
		var data = {}
		data["stream"] = stream
		data["messages"] = messages
		var body = JSON.new().stringify(data)
		if stream == false:
			var url = plugin_node.get_ai_url().path_join("/v1/chat/completions")
			var http_request = HTTPRequest.new()
			add_child(http_request)
			
			var error = http_request.request(url, [], HTTPClient.Method.METHOD_POST,body)
			if error != OK:
				push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
			
			var response = await http_request.request_completed
			var response_body = JSON.parse_string(response[3].get_string_from_utf8())
			remove_child(http_request)
			return response_body
		else:
			var http_request = StreamRequest.new()
			add_child(http_request)
			var host=plugin_node.get_ai_host()
			var port=plugin_node.get_ai_port()
			var error = await http_request.request(host,port,"/v1/chat/completions",body,stream)
			if error != OK:
				push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
			return http_request
	else:
		var data = {}
		data["stream"] = stream
		data["messages"] = messages
		var result = await C_S_CREATE_CHAT_COMPLETION(-1, data)
		return result


## The method name has the same name as the sub protocol
func C_S_INIT_COMPLETIONS(server_syncId, content):
	return await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_INIT_COMPLETIONS"), 600)
	

## The method name has the same name as the sub protocol
func S_C_INIT_COMPLETIONS(server_syncId, content):
	pass


## The method name has the same name as the sub protocol
func C_S_CREATE_CHAT_COMPLETION(server_syncId, content):
	var cur_data = await plugin_node.send_service_request(server_syncId, content, Callable(self, "C_S_CREATE_CHAT_COMPLETION"),600)
	## Please note that there is a field called message that conflicts with the keyword of protobuf, 
	## so it was renamed as message_body, make changes to the data at this location
	if cur_data:
		var choices = cur_data.get("choices",null)
		if choices:
			for i in range(len(choices)):
				var choice = choices[i]
				var message_body = choice.get("message_body","")
				if message_body == null:
					message_body = ""
				cur_data["choices"][i]["message"] = message_body
				choice["message"] = message_body
	return cur_data
	

## The method name has the same name as the sub protocol
func S_C_CREATE_CHAT_COMPLETION(server_syncId, content):
	pass

class StreamRequest extends Node:
	signal get_response
	signal get_all_response
	var stream = true
	var http = null
	func request(host,port,path,json_string,stream):
		self.stream = stream
		var http = HTTPClient.new()
		self.http = http
		var err = http.connect_to_host(host, port)
		assert(err == OK)
		while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
			http.poll()
			print("Connecting...")
			if OS.has_feature("web"):
				await get_tree().process_frame
			else:
				await get_tree().create_timer(0.5).timeout
			
		assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
		var headers = [
			"User-Agent: Pirulo/1.0 (Godot)",
			"Accept: */*"
		]
		err = http.request(HTTPClient.METHOD_POST, "/v1/chat/completions", headers, json_string)
		assert(err == OK) # Make sure all is OK.
		while http.get_status() == HTTPClient.STATUS_REQUESTING:
			http.poll()
			print("Requesting...")
			if OS.has_feature("web"):
				await get_tree().process_frame
			else:
				await get_tree().create_timer(0.5).timeout

		assert(http.get_status() == HTTPClient.STATUS_BODY or http.get_status() == HTTPClient.STATUS_CONNECTED) # Make sure request finished well.
		print("response: ", http.has_response()) # Site might not have a response.
		if http.has_response():
			# If there is a response...
	
			headers = http.get_response_headers_as_dictionary() # Get response headers.
			print("code: ", http.get_response_code()) # Show response code.
			print("**headers:\\n", headers) # Show headers.
	
			# Getting the HTTP Body
	
			if http.is_response_chunked():
				# Does it use chunks?
				print("Response is Chunked!")
			else:
				# Or just plain Content-Length
				var bl = http.get_response_body_length()
				print("Response Length: ", bl)
		
		return OK

	
	func start_response():
		if self.stream:
			# This method works for both anyway
			var pending = null
			while http.get_status() == HTTPClient.STATUS_BODY:
				# While there is body left to be read
				http.poll()
				# Get a chunk.
				var chunk = http.read_response_body_chunk()
				if chunk.size() == 0:
					if OS.has_feature("web"):
						await get_tree().process_frame
					else:
						await get_tree().create_timer(1).timeout
				else:
					var chunk_str = chunk.get_string_from_utf8()
					if pending != null:
						chunk_str = pending+chunk_str
					
					var lines = chunk_str.split("\n",false)
					var cur_lines = []
					for line in lines:
						cur_lines.append_array(line.split("\r",false))
					
					if cur_lines and len(cur_lines)>0 and chunk and cur_lines[-1][-1]==chunk_str[-1]:
						pending = cur_lines.pop_back()
					else:
						pending = null
					
					for line in cur_lines:
						## Note that the returned information is complete and needs to be parsed again in the subroutine
						emit_signal("get_response",line,self.just_get_content_from_line_str(line))
		else:
			var rb = PackedByteArray()
			while http.get_status() == HTTPClient.STATUS_BODY:
				# While there is body left to be read
				http.poll()
				# Get a chunk.
				var chunk = http.read_response_body_chunk()
				if chunk.size() == 0:
					if OS.has_feature("web"):
						await get_tree().process_frame
					else:
						await get_tree().create_timer(1).timeout
				else:
					rb = rb + chunk # Append to read buffer.
			var text = rb.get_string_from_ascii()
			## Note that the returned information is complete and needs to be parsed again in the subroutine
			emit_signal("get_all_response",text,self.just_get_content_from_all_str(text))
		self.queue_free()

	func just_get_content_from_line_str(line):
		if line.begins_with("data: "):
			var cur_line = line.trim_prefix("data: ")
			printt("cur_line",cur_line)
			if cur_line.begins_with("[DONE]"):
				return ""
			var cur_data = JSON.parse_string(cur_line)
			if cur_data and "choices" in cur_data:
				if len(cur_data["choices"])>0:
					if "delta" in cur_data["choices"][0]:
						return cur_data["choices"][0]["delta"].get("content","")
		return ""
	
	func just_get_content_from_all_str(text):
		printt("text",text)
		var cur_data = JSON.parse_string(text)
		return cur_data["choices"][0]["message"]["content"]
