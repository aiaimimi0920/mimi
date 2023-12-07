extends ConversationMessageAPI
class_name FileConversationMessage


func get_MessageType():
	return "File"
	
var file_id
var file_name
var file_size:
	get:
		if file_size==null or file_size==0:
			if file_ref_path:
				var file = FileAccess.open(file_ref_path, FileAccess.READ)
				file_size = file.get_length()
		return file_size
		
var file_url
var file_base64
var file_ref_path

func reload_message():
	super.reload_message()
	if conversation_message_data:
		file_id = conversation_message_data.get("file_id",null)
		file_name = conversation_message_data.get("file_name",null)
		file_size = conversation_message_data.get("file_size",0)
		file_url = conversation_message_data.get("file_url",null)
		file_base64 = conversation_message_data.get("file_base64",null)
		file_ref_path = conversation_message_data.get("file_ref_path",null)
	return self
	
func get_as_text()->String:
	return "[File"+file_name+"]"

func get_file_path():
	if file_ref_path:
		if FileAccess.file_exists(file_ref_path):
			return file_ref_path
	var cur_file_path = GlobalManager.file_path.path_join(file_id)
	if FileAccess.file_exists(cur_file_path):
		return cur_file_path
	if file_url:
		cur_file_path = GlobalManager.file_path.path_join(file_url)
		## TODO: If there are no files available locally, you can try downloading files from the network
		## Note that file classes are not downloaded by default, as the file may be very large, 
		## so it is more reasonable to manually trigger the download
		if FileAccess.file_exists(cur_file_path):
			return cur_file_path
	return ""
	
## It will be returned in text format. If you need to customize the return, use get_file_path
func get_file_text_data()->String:
	var file_path = get_file_path()
	if file_path != "":
		var file = FileAccess.open(file_path,FileAccess.READ)
		var content = file.get_as_text()
		return content
	return ""

## It will be returned in buffer format. If you need to customize the return, use get_file_path
func get_file_buffer_data()->PackedByteArray:
	if file_base64:
		return Marshalls.base64_to_raw(file_base64)
	var file_path = get_file_path()
	if file_path != "":
		var file = FileAccess.open(file_path,FileAccess.READ)
		var content = file.get_buffer(file.get_length())
		return content
	return PackedByteArray()
	
	
func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["file_id"] = file_id
	all_data["data"]["file_name"] = file_name
	all_data["data"]["file_size"] = file_size
	all_data["data"]["file_url"] = file_url
	all_data["data"]["file_base64"] = file_base64
	all_data["data"]["file_ref_path"] = file_ref_path
	return all_data

var download_start = false
## Download resources from the URL
func begin_download():
	if download_start == true:
		return
	download_start = true
	file_ref_path = await base_begin_download(file_url)
	file_ref_path = file_ref_path.simplify_path()
	download_start = false
	emit_signal("download_finish")
