extends Node

var base_url = "https://platform.aiaimimi.com/api/entity_content"

func check_authorize():
	if AuthorizeManager.id_token:
		return true
	await AuthorizeManager.authorize()
	if AuthorizeManager.id_token:
		return true
	return false


var me_user = null

func get_user_me():
	var url = base_url.path_join("user/me")
	var user = await platform_request(url)
	me_user = user
	printt("me_user",me_user)
	return me_user

func get_user(user_id):
	var url = base_url.path_join("user/{user_id}".format({"user_id":user_id}))
	return await platform_request(url)

func update_user_me(user_name=null,ban=null,anonymous_search_level=null):
	var user_data = {}
	if user_name!=null:
		user_data["name"] = user_name
	if ban!=null:
		user_data["ban"] = ban
	if anonymous_search_level!=null:
		user_data["anonymous_search_level"] = anonymous_search_level
	var url = base_url.path_join("user/me/update")
	return await platform_request(url, user_data)

func get_user_by_name(user_name):
	var url = base_url.path_join("user/name/{user_name}".format({"user_name":user_name}))
	return await platform_request(url)

func create_content(content_name=null,ban=null,anonymous_search_level=null,free=null,store_info={}, method_info={},content_type=0,content_version=0):
	var content_data = {}
	if content_name!=null:
		content_data["name"] = content_name
	if ban!=null:
		content_data["ban"] = ban
	if anonymous_search_level!=null:
		content_data["anonymous_search_level"] = anonymous_search_level
	if free!=null:
		content_data["free"] = free

	content_data["store_info"] = {}
	if store_info and not(store_info.is_empty()):
		content_data["store_info"] = store_info

	content_data["method_info"] = {}
	if method_info and not(method_info.is_empty()):
		content_data["method_info"] = method_info
	
	
	if content_type!=null:
		content_data["content_type"] = content_type
	
	if content_version!=null:
		content_data["content_version"] = content_version
	
	printt("content_data",content_data)
	var url = base_url.path_join("content/create")
	return await platform_request(url, content_data)

func get_content(content_id):
	var url = base_url.path_join("content/{content_id}".format({"content_id":content_id}))
	return await platform_request(url)

func query_best_content(query_text, content_type = 1):
	var url = base_url.path_join("content/best")

	var body_parts = [
		"query_text=%s" % query_text.uri_encode(),
	]
	url = url + "?" + "&".join(body_parts)
	return await platform_request(url)


func update_content(content_id, content_name=null,ban=null,anonymous_search_level=null,free=null):
	var update_info = {}
	if content_name!=null:
		update_info["name"] = content_name
	if ban!=null:
		update_info["ban"] = ban
	if anonymous_search_level!=null:
		update_info["anonymous_search_level"] = anonymous_search_level
	if free!=null:
		update_info["free"] = free
	var url = base_url.path_join("content/{content_id}/update"%{"content_id":content_id})
	return await platform_request(url, update_info)

func get_plugin_info(plugin_name,min_version:int=0,max_version:int=1000000000):
	var url = base_url.path_join("content/plugin/{plugin_name}".format({"plugin_name":plugin_name}))
	var data = ["min_version=%s"%min_version,"max_version=%s"%max_version]
	url = url + "?" + "&".join(data)
	return await platform_request(url)

func platform_request(url, data = null):
	if not await check_authorize():
		return null
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var headers = [
		"user-token: %s"%AuthorizeManager.id_token
	]
	var error
	if data == null:
		error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	else:
		var body = JSON.new().stringify(data)
		error = http_request.request(url, headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
		return false
	var response = await http_request.request_completed
	var response_body = JSON.parse_string(response[3].get_string_from_utf8())
	remove_child(http_request)
	return response_body
	
