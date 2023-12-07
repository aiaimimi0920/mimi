extends Node
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)


var boundary = "boundary"

func sign_hmac(key: PackedByteArray, msg: String) -> PackedByteArray:
	var crypto = Crypto.new()
	return crypto.hmac_digest(HashingContext.HASH_SHA256, key, msg.to_utf8_buffer())


func getSignatureKey(
	key: String, date_stamp: String, regionName: String, serviceName: String
) -> PackedByteArray:
	var kDate := sign_hmac(("AWS4" + key).to_utf8_buffer(), date_stamp)
	var kRegion := sign_hmac(kDate, regionName)
	var kService := sign_hmac(kRegion, serviceName)
	var kSigning := sign_hmac(kService, "aws4_request")
	return kSigning


func presigned_URL(
	method,
	query_url_path = "/",
	query_string_str = "",
	request_parameters = "",
	region = "",
	bucket = "",
	access_key = "",
	secret_key = "",
	service = "",
	content_type = "multipart/form-data; boundary=%s" % boundary
):
	if region == "" or region == null:
		region = plugin_node.service_config_manager.region_name

	if bucket == "" or bucket == null:
		bucket = plugin_node.service_config_manager.bucket_name

	if access_key == "" or access_key == null:
		access_key = plugin_node.service_config_manager.access_key

	if secret_key == "" or secret_key == null:
		secret_key = plugin_node.service_config_manager.secret_access_key

	if service == "" or service == null:
		service = plugin_node.service_config_manager.service_name

	var host = bucket + "." + service + "." + region + ".amazonaws.com"

	var datetime = Time.get_datetime_dict_from_system(true)
	if str(datetime["month"]).length() == 1:
		datetime["month"] = "0" + str(datetime["month"])
	if str(datetime["day"]).length() == 1:
		datetime["day"] = "0" + str(datetime["day"])
	if str(datetime["hour"]).length() == 1:
		datetime["hour"] = "0" + str(datetime["hour"])
	if str(datetime["minute"]).length() == 1:
		datetime["minute"] = "0" + str(datetime["minute"])
	if str(datetime["second"]).length() == 1:
		datetime["second"] = "0" + str(datetime["second"])
	var amz_date = (
		str(datetime["year"])
		+ str(datetime["month"])
		+ str(datetime["day"])
		+ "T"
		+ str(datetime["hour"])
		+ str(datetime["minute"])
		+ str(datetime["second"])
		+ "Z"
	)
	var date_stamp = str(datetime["year"]) + str(datetime["month"]) + str(datetime["day"])

	# ************* TASK 1: CREATE A CANONICAL REQUEST *************
	# http://docs.aws.amazon.com/general/latest/gr/sigv4-create-canonical-request.html

	# Step 1 is to define the verb (GET, POST, etc.)--already done.
	var method_name = ""
	if typeof(method) == TYPE_STRING:
		method_name = method.to_upper()
	else:
		match method:
			HTTPClient.METHOD_GET:
				method_name = "GET"
			HTTPClient.METHOD_HEAD:
				method_name = "HEAD"
			HTTPClient.METHOD_POST:
				method_name = "POST"
			HTTPClient.METHOD_PUT:
				method_name = "PUT"
			HTTPClient.METHOD_DELETE:
				method_name = "DELETE"
			HTTPClient.METHOD_OPTIONS:
				method_name = "OPTIONS"
			HTTPClient.METHOD_TRACE:
				method_name = "TRACE"
			HTTPClient.METHOD_CONNECT:
				method_name = "CONNECT"
			HTTPClient.METHOD_PATCH:
				method_name = "PATCH"

	# Step 2: Create canonical URI--the part of the URI from domain to query
	# string (use '/' if no path)
	var canonical_uri = query_url_path

	## Step 3: Create the canonical query string. In this example, request
	# parameters are passed in the body of the request and the query string
	# is blank.
	var canonical_query_string = query_string_str

	# Step 6: Create payload hash. In this example, the payload (body of
	# the request) contains the request parameters.

	var payload_hash
	if typeof(request_parameters) == TYPE_STRING:
		payload_hash = request_parameters.sha256_text()
	elif typeof(request_parameters) == TYPE_PACKED_BYTE_ARRAY:
		var ctx = HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(request_parameters)
		payload_hash = ctx.finish()
		payload_hash = payload_hash.hex_encode()

	# Step 4: Create the canonical headers. Header names must be trimmed
	# and lowercase, and sorted in code point order from low to high.
	# Note that there is a trailing \n.
	var canonical_headers = (
		""
		+ "content-type:"
		+ content_type
		+ "\n"
		+ "host:"
		+ host
		+ "\n"
		+ "x-amz-content-sha256:"
		+ payload_hash
		+ "\n"
		+ "x-amz-date:"
		+ amz_date
		+ "\n"
	)

	# Step 5: Create the list of signed headers. This lists the headers
	# in the canonical_headers list, delimited with ";" and in alpha order.
	# Note: The request can include any headers; canonical_headers and
	# signed_headers include those that you want to be included in the
	# hash of the request. "Host" and "x-amz-date" are always required.
	# For DynamoDB, content-type and x-amz-target are also required.
	var signed_headers = "content-type;host;x-amz-content-sha256;x-amz-date"

	# Step 7: Combine elements to create canonical request
	var canonical_request = (
		method_name
		+ "\n"
		+ canonical_uri
		+ "\n"
		+ canonical_query_string
		+ "\n"
		+ canonical_headers
		+ "\n"
		+ signed_headers
		+ "\n"
		+ payload_hash
	)

	# ************* TASK 2: CREATE THE STRING TO SIGN*************
	# Match the algorithm to the hashing algorithm you use, either SHA-1 or
	# SHA-256 (recommended)
	var algorithm = "AWS4-HMAC-SHA256"
	var credential_scope = date_stamp + "/" + region + "/" + service + "/" + "aws4_request"
	var string_to_sign = (
		algorithm
		+ "\n"
		+ amz_date
		+ "\n"
		+ credential_scope
		+ "\n"
		+ canonical_request.sha256_text()
	)

	# ************* TASK 3: CALCULATE THE SIGNATURE *************
	# Create the signing key using the function defined above.
	var signing_key = getSignatureKey(secret_key, date_stamp, region, service)

	# Sign the string_to_sign using the signing_key
	var crypto = Crypto.new()
	var signature = (
		(crypto.hmac_digest(
			HashingContext.HASH_SHA256, signing_key, string_to_sign.to_utf8_buffer()
		))
		. hex_encode()
	)

	# ************* TASK 4: ADD SIGNING INFORMATION TO THE REQUEST *************
	# Put the signature information in a header named Authorization.
	var authorization_header = (
		algorithm
		+ " "
		+ "Credential="
		+ access_key
		+ "/"
		+ credential_scope
		+ ", "
		+ "SignedHeaders="
		+ signed_headers
		+ ", "
		+ "Signature="
		+ signature
	)

	# For DynamoDB, the request can include any headers, but MUST include "host", "x-amz-date",
	# "x-amz-target", "content-type", and "Authorization". Except for the authorization
	# header, the headers must be included in the canonical_headers and signed_headers values, as
	# noted earlier. Order here is not significant.
	# # Python note: The 'host' header is added automatically by the Python 'requests' library.
	var headers = PackedStringArray(
		[
			"Content-Type:" + content_type,
			"X-Amz-Date:" + amz_date,
			"X-Amz-Content-Sha256:" + payload_hash,
			"Authorization:" + authorization_header
		]
	)
	return [host, headers]


func http_request(
	method,
	query_url_path = "/",
	query_string_str = "",
	query_string_map = {},
	request_parameters = "",
	chunk_call=null,
	all_chunk_call=null,
	cmd = null,
	region = "",
	bucket = "",
	access_key = "",
	secret_key = "",
	service = "",
	content_type = "multipart/form-data; boundary=%s" % boundary,
):
	if query_string_str=="" and query_string_map.size()>0:
		var cur_query_string_map = {}
		var query_string_map_keys = query_string_map.keys()
		query_string_map_keys.sort()
		for key in query_string_map_keys:
			query_string_str += (key.uri_encode()+"="+query_string_map[key].uri_encode()+"&")
		query_string_str = query_string_str.trim_suffix("&")

	if query_url_path == "":
		query_url_path = "/"
	if not query_url_path.begins_with("/"):
		query_url_path = "/"+query_url_path
	# if not query_url_path.ends_with("/"):
	# 	query_url_path = query_url_path +"/"

	var cur_presigned_URL = presigned_URL(
		method,
		query_url_path,
		query_string_str,
		request_parameters,
		region,
		bucket,
		access_key,
		secret_key,
		service,
		content_type
	)
	var host = cur_presigned_URL[0]
	var headers = cur_presigned_URL[1]
	
	if (access_key == "" or access_key == null) and (plugin_node.service_config_manager.access_key=="" or plugin_node.service_config_manager.access_key == null):
		headers = PackedStringArray()
		
	var endpoint = "https://" + host + "/"
	var http = HTTPClient.new()
	var err = http.connect_to_host("https://"+host)
	assert(err == OK)
	while http.get_status() == HTTPClient.STATUS_CONNECTING or http.get_status() == HTTPClient.STATUS_RESOLVING:
		http.poll()
		# print("Connecting...")
		await get_tree().process_frame

	assert(http.get_status() == HTTPClient.STATUS_CONNECTED)
	var request_query_url_path = query_url_path
	if query_string_str != "":
		request_query_url_path += "?" + query_string_str
	
	if typeof(request_parameters)==TYPE_STRING:
		err = http.request(method, request_query_url_path, headers, request_parameters)
	elif typeof(request_parameters)==TYPE_PACKED_BYTE_ARRAY:
		err = http.request_raw(method, request_query_url_path, headers, request_parameters)
	if cmd:
		cmd.time += 1
	assert(err == OK)
	while http.get_status() == HTTPClient.STATUS_REQUESTING:
		http.poll()
		# print("Requesting...")
		await get_tree().process_frame
	
	assert(http.get_status() == HTTPClient.STATUS_BODY)
	
	if http.has_response():
		# If there is a response...
		headers = http.get_response_headers_as_dictionary() # Get response headers.
		# Getting the HTTP Body
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
				rb = rb + chunk # Append to read buffer.
			
			if chunk_call != null:
				chunk_call.call(chunk)
		if all_chunk_call != null:
			all_chunk_call.call(rb)

	if cmd:
		cmd.time-=1
		if cmd.time <= 0:
			cmd.emit_signal("request_finished")
	return true

class RequestInstance:
	extends RefCounted
	signal request_finished
	var time = 0
	var data = {}
