extends Node


func send_http_get_request(url:String,headers:PackedStringArray=PackedStringArray([]),timeout:int=20)->HttpRequestResult:
	Logger.info("Attempting to send HTTP Get request to:"+url)
	var node:HttpRequestInstance = HttpRequestInstance.new()
	node.request_url = url
	node.request_headers = headers
	if timeout > 0:
		node.timeout = timeout
	add_child(node)
	var error:int = node.request(url,headers)
	if error:
		node.queue_free()
		Logger.error("An error occurred while sending an HTTP Get request to %s: %s"%[url,error_string(error)])
		var _r:HttpRequestResult = HttpRequestResult.new()
		_r.request_url = url
		_r.request_headers = headers
		return _r
	await node.request_finished
	var result:HttpRequestResult = node.get_result()
	node.queue_free()
	return result
	
	
func send_http_post_request(url:String,data:Variant="",headers:PackedStringArray=PackedStringArray([]),timeout:int=20)->HttpRequestResult:
	Logger.info("Attempting to send HTTP Post request to:"+url)
	if (data is Dictionary) or (data is Array):
		data = JSON.stringify(data)
		var find_h:bool = false
		for h in headers:
			if h.findn("Content-Type: application/json")!=-1 or h.findn("Content-Type:application/json")!=-1:
				find_h = true
				break
		if !find_h:
			headers.append("Content-Type: application/json")
	elif (!(data is String)) and (!(data is PackedByteArray)):
		data = ""
		Logger.warn("Warning: The incoming HTTP request data is not a dictionary/array/string/byte array, so it has been replaced with an empty string(\"\")！")
	var node:HttpRequestInstance = HttpRequestInstance.new()
	node.request_url = url
	node.request_data = data
	node.request_headers = headers
	if timeout > 0:
		node.timeout = timeout
	add_child(node)
	var error:int
	if data is PackedByteArray:
		error = node.request_raw(url,headers,HTTPClient.METHOD_POST,data)
	else:
		error = node.request(url,headers,HTTPClient.METHOD_POST,data)
	if error:
		node.queue_free()
		Logger.error("An error occurred while sending an HTTP Post request to %s: %s"%[url,error_string(error)])
		var _r:HttpRequestResult = HttpRequestResult.new()
		_r.request_url = url
		_r.request_data = data
		_r.request_headers = headers
		return _r
	await node.request_finished
	var result:HttpRequestResult = node.get_result()
	node.queue_free()
	return result


func send_http_put_request(url:String,data:Variant="",headers:PackedStringArray=PackedStringArray([]),timeout:int=20)->HttpRequestResult:
	Logger.info("Attempting to send HTTP Put request to: "+url)
	if (data is Dictionary) or (data is Array):
		data = JSON.stringify(data)
		var find_h:bool = false
		for h in headers:
			if h.findn("Content-Type: application/json")!=-1 or h.findn("Content-Type:application/json")!=-1:
				find_h = true
				break
		if !find_h:
			headers.append("Content-Type: application/json")
	elif (!(data is String)) and (!(data is PackedByteArray)):
		data = ""
		Logger.warn("Warning: The incoming HTTP request data is not a dictionary/array/string/byte array, so it has been replaced with an empty string(\"\")！")
	var node:HttpRequestInstance = HttpRequestInstance.new()
	node.request_url = url
	node.request_data = data
	node.request_headers = headers
	if timeout > 0:
		node.timeout = timeout
	add_child(node)
	var error:int
	if data is PackedByteArray:
		error = node.request_raw(url,headers,HTTPClient.METHOD_PUT,data)
	else:
		error = node.request(url,headers,HTTPClient.METHOD_PUT,data)
	if error:
		node.queue_free()
		Logger.error("An error occurred while sending an HTTP Put request to %s: %s"%[url,error_string(error)])
		var _r:HttpRequestResult = HttpRequestResult.new()
		_r.request_url = url
		_r.request_data = data
		_r.request_headers = headers
		return _r
	await node.request_finished
	var result:HttpRequestResult = node.get_result()
	node.queue_free()
	return result


class HttpRequestInstance:
	extends HTTPRequest

	signal request_finished

	var request_url:String = ""
	var request_data = ""
	var request_headers:PackedStringArray = []
	var result:HttpRequestResult = HttpRequestResult.new()

	func _ready()->void:
		#var proxy:PackedStringArray = ConfigManager.get_http_request_proxy().split(":")
		#if proxy.size() == 2:
			#set_http_proxy(proxy[0],int(proxy[1]))
			#set_https_proxy(proxy[0],int(proxy[1]))
		use_threads = true
		connect("request_completed",_http_request_completed)

	func _http_request_completed(_result:int, _response_code:int, _headers:PackedStringArray, _body:PackedByteArray)->void:
		result.request_url = request_url
		result.request_data = request_data
		result.request_headers = request_headers
		result.result_code = _result
		result.response_code = _response_code
		result.headers = _headers
		result.body = _body
		if _result != HTTPRequest.RESULT_SUCCESS:
			Logger.error("An error occurred while obtaining the HTTP request result from %s, with the error code being:%s"%[request_url,ClassDB.class_get_enum_constants("HTTPRequest","Result")[int(_result)]])
		else:
			Logger.info("Successfully obtained the return result of HTTP request from %s!"%[request_url])
		emit_signal("request_finished")
		
	func get_result()->HttpRequestResult:
		return result
