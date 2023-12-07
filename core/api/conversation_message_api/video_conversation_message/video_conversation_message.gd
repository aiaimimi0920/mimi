extends ConversationMessageAPI
class_name VideoConversationMessage

func get_MessageType():
	return "Video"

var video_width
var video_height

var video_id
var video_url
var video_ref_path

var video_name
var video_duration

func reload_message():
	super.reload_message()
	if conversation_message_data:
		video_id = conversation_message_data.get("video_id",null)
		video_url = conversation_message_data.get("video_url",null)
		video_ref_path = conversation_message_data.get("video_ref_path",null)
		video_name = conversation_message_data.get("video_name",null)
		video_duration = conversation_message_data.get("video_duration",null)
		video_width = conversation_message_data.get("video_width",null)
		video_height = conversation_message_data.get("video_height",null)
	return self
	
func get_as_text()->String:
	return "[Video"+ video_name +"]"

func get_video_path():
	if video_ref_path:
		if FileAccess.file_exists(video_ref_path):
			return video_ref_path
	var cur_video_path = GlobalManager.file_path.path_join(video_id)
	if FileAccess.file_exists(cur_video_path):
		return cur_video_path
	if video_url:
		cur_video_path = GlobalManager.file_path.path_join(video_url)
		## TODO: If there are no files available locally, you can try downloading files from the network
		if FileAccess.file_exists(cur_video_path):
			return cur_video_path
	return ""


## It will be returned in buffer format. If you need to customize the return, use get_file_path
func get_video_buffer_data()->PackedByteArray:
	var file_path = get_video_path()
	if file_path != "":
		var file = FileAccess.open(file_path,FileAccess.READ)
		var content = file.get_buffer(file.get_length())
		return content
	return PackedByteArray()


func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["video_id"] = video_id
	all_data["data"]["video_url"] = video_url
	all_data["data"]["video_ref_path"] = video_ref_path
	all_data["data"]["video_name"] = video_name
	all_data["data"]["video_duration"] = video_duration
	all_data["data"]["video_width"] = video_width
	all_data["data"]["video_height"] = video_height
	return all_data


var download_start = false
## Download resources from the URL
func begin_download():
	if download_start == true:
		return
	download_start = true
	if video_url:
		video_ref_path = await base_begin_download(video_url)
		video_ref_path = video_ref_path.simplify_path()
	download_start = false
	emit_signal("download_finish")
	
