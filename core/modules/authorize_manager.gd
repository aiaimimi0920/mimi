extends Node
const PORT := 8362
const BINDING := "127.0.0.1"
const client_secret := "f1_ZkmLWNT3VteOKnO0Rp6z5vwOAI75W1b6njwaKos0"
const client_ID := "HdOw2meXmNYMTuzViO02n_y1VYQG9aEZAF20p6SyzZA"
const base_server := "https://vme.fief.dev/"
const token_req := "https://vme.fief.dev/api/token"
const openid_configuration := ".well-known/openid-configuration"
var openid_configuration_dict = {}

var redirect_server := TCPServer.new() # 
var redirect_uri := "http://%s:%s" % [BINDING, PORT]
#var redirect_uri := "http://localhost:8000"

var id_token
var refresh_token
var token

signal token_recieved

func _ready():
	set_process(false)
	authorize()


func authorize():
	load_tokens()
	if !await is_token_valid():
		if !await refresh_tokens():
			get_auth_code()
	if await is_token_valid():
		await Platform.get_user_me()


func _process(_delta):
	if redirect_server.is_connection_available():
		var connection = redirect_server.take_connection()
		var request = connection.get_string(connection.get_available_bytes())
		var code_str = RegEx.new()
		code_str.compile("\\/\\?code=(?<code>\\S*)")
		var code = null
		var result = code_str.search(request)
		if result:
			code = result.get_string("code").strip_edges()
		if code:
			set_process(false)
			await get_token_from_auth(code)
			connection.put_data(("HTTP/1.1 %d\r\n" % 200).to_ascii_buffer())
			connection.put_data(load_HTML().to_ascii_buffer())
			redirect_server.stop()

func init_openid_configuration_dict():
	if openid_configuration_dict.is_empty():
		var http_request = HTTPRequest.new()
		add_child(http_request)
	
		var error = http_request.request(base_server.path_join(openid_configuration), [], HTTPClient.METHOD_GET)
		if error != OK:
			push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
		
		var response = await http_request.request_completed
		var response_body = JSON.parse_string(response[3].get_string_from_utf8())
		openid_configuration_dict = response_body
		remove_child(http_request)


func get_auth_code():
	set_process(true)
# warning-ignore:unused_variable
	var redir_err = redirect_server.listen(PORT, BINDING)
	var body_parts = [
		"client_id=%s" % client_ID,
		"redirect_uri=%s" % redirect_uri.uri_encode(),
		"response_type=code",
		"scope=openid offline_access",
	]
	var url = openid_configuration_dict["authorization_endpoint"] + "?" + "&".join(body_parts)
	
# warning-ignore:return_value_discarded
	OS.shell_open(url) # Opens window for user authentication


func get_token_from_auth(auth_code):
	
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	headers = PackedStringArray(headers)
	
	var body_parts = [
		"code=%s" % auth_code, 
		"client_id=%s" % client_ID,
		"client_secret=%s" % client_secret,
		"redirect_uri=%s" % redirect_uri.uri_encode(),
		"grant_type=authorization_code"
	]
	
	var body = "&".join(body_parts)
	
# warning-ignore:return_value_discarded
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(openid_configuration_dict["token_endpoint"], headers, HTTPClient.METHOD_POST, body)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = await http_request.request_completed
	var response_body = JSON.parse_string(response[3].get_string_from_utf8())

	token = response_body.get("access_token")
	id_token = response_body["id_token"]
	refresh_token = response_body.get("refresh_token")
	save_tokens()
	emit_signal("token_recieved")
	remove_child(http_request)


## Update token using refresh key
func refresh_tokens():
	await init_openid_configuration_dict()
	var headers = [
		"Content-Type: application/x-www-form-urlencoded"
	]
	
	var body_parts = [
		"client_id=%s" % client_ID,
		"client_secret=%s" % client_secret,
		"refresh_token=%s" % refresh_token,
		"grant_type=refresh_token"
	]
	var body = "&".join(body_parts)
	
# warning-ignore:return_value_discarded
	var http_request = HTTPRequest.new()
	add_child(http_request)
	
	var error = http_request.request(openid_configuration_dict["token_endpoint"], headers, HTTPClient.METHOD_POST, body)

	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
	
	var response = await http_request.request_completed
	
	var response_body = JSON.parse_string(response[3].get_string_from_utf8())
	remove_child(http_request)
	if response_body.get("access_token") and response_body.get("id_token"):
		token = response_body["access_token"]
		id_token = response_body["id_token"]
		save_tokens()
		emit_signal("token_recieved")
		return true
	else:
		return false

# SAVE/LOAD
const SAVE_DIR = 'user://token/'
var save_path = SAVE_DIR + 'token.dat'


func save_tokens():
	if !DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if file:
		var tokens = {
			"token" : token,
			"refresh_token" : refresh_token,
			"id_token" : id_token
		}
		file.store_var(tokens)


func load_tokens():
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		if file:
			var tokens = file.get_var()
			token = tokens.get("token")
			refresh_token = tokens.get("refresh_token")
			id_token = tokens.get("id_token")
	

const display_html = """
<html>
<style>
	body {
		background-color: 1A1A1A;
		position: absolute;
		top: 50%;
		left: 50%;
		-ms-transform: translate(-50%, -50%);
		transform: translate(-50%, -50%);
		text-align: center;
		vertical-align: middle;
		font-family: arial;
		font-size: 24px;
		font-weight: bold;
	}
</style>

<body>
	<img alt="" width=50% src="https://user-images.githubusercontent.com/63984796/166126738-063f7b9b-8f78-4d3d-9853-79000f95549c.png">
	<br>
	<h2 style="color:e0e0e0;">Success!</h2>
	<h2 style="color:e0e0e0;">Please close this tab and return to the application.</h2>
</body>

</html>
"""


func load_HTML():
	var HTML = display_html.replace("    ", "\t").insert(0, "\n")
	return HTML


func is_token_valid():
	if !id_token:
		await get_tree().create_timer(0.001).timeout
		return false
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	var headers = [
		"user-token: %s"%id_token
	]
	printt("id_token",id_token)
	var target_url = Platform.base_url.path_join("user/me")
	var url = target_url
	var error = http_request.request(url, headers, HTTPClient.METHOD_GET)
	if error != OK:
		push_error("An error occurred in the HTTP request with ERR Code: %s" % error)
		return false
	var response = await http_request.request_completed
	## This is the current player information, but it is not used. This is only to verify if it is a valid ID_Token
	var response_body = JSON.parse_string(response[3].get_string_from_utf8())
	remove_child(http_request)
	if response_body == null or response[1]!=200:
		return false
	return true
