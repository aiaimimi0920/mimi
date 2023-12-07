extends RefCounted

class_name ConversationMessageAPI
signal download_finish

var conversation_message_id:String

var conversation_id:String
var conversation_ins

var MessageType:
	get:
		return get_MessageType()
		
func get_MessageType():
	return ""

var conversation_message_type
var conversation_message_data
var conversation_message_ins

var create_timestamp:int
var random_number:int 

## Note the text message plugin callback and object callbacks will not appear when loading from a file
var plugin_callback
var object_callback
var trigger_counts = 0
var callback_data = {}
var is_bot = true
var like_state = 0 ## 0 : unknown, 1 : dislike,  2 : liking

## If attempting to merge, multiple messages from the same source will be merged into one message display,
## but be careful to like, step on, confirm, and reject will take effect simultaneously and will not take effect independently. 
## Please use with caution. This merger only shows a merging effect in terms of performance and will not have any other effects
## If you want to use merge effects:
## show_message_type=0, Display alone
## show_message_type=1, Display begin
## show_message_type=2, Display center
## show_message_type=3, Display end
var show_message_type = 0 

signal change_trigger_status
signal call_finished

func reduce_trigger_counts(times=1):
	if trigger_counts>0:
		trigger_counts -= 1
		trigger_counts = max(trigger_counts, 0)
		if trigger_counts==0:
			emit_signal("change_trigger_status",false)
	pass

func _init(cur_conversation_message_id,cur_conversation_message_type=null, cur_conversation_message_data=null):
	conversation_message_id = cur_conversation_message_id
	var parameter_array = conversation_message_id.split("_e_")
	conversation_id = parameter_array[0]+"_e"
	var conversation_message_info = parameter_array[1]
	var conversation_message_parameter_array = conversation_message_info.split("_")
	var index = 0
	create_timestamp = int(conversation_message_parameter_array[index])
	index += 1
	random_number = int(conversation_message_parameter_array[index])
	set_message(cur_conversation_message_type, cur_conversation_message_data)

func set_message(cur_conversation_message_type, cur_conversation_message_data):
	conversation_message_type = cur_conversation_message_type
	conversation_message_data = cur_conversation_message_data
	reload_message()

func get_conversation_ins():
	if conversation_ins == null:
		conversation_ins = ConversationAPI.new(conversation_id)
	return conversation_ins

func reload_message():
	if conversation_message_data:
		plugin_callback = conversation_message_data.get("plugin_callback",null)
		object_callback = conversation_message_data.get("object_callback",null)
		trigger_counts = conversation_message_data.get("trigger_counts",0)
		callback_data = conversation_message_data.get("callback_data",null)
		is_bot = conversation_message_data.get("is_bot",false)
	return self


func get_file_path():
	var cur_conversation_ins = get_conversation_ins()
	return cur_conversation_ins.get_file_path()
	
func get_as_text()->String:
	return ""

func to_dict(is_store=true)->Dictionary:
	var cur_json_dict = {}
	if not is_store:
		cur_json_dict["plugin_callback"] = plugin_callback
	if not is_store:
		cur_json_dict["object_callback"] = object_callback
	cur_json_dict["trigger_counts"] = trigger_counts
	cur_json_dict["is_bot"] = is_bot
	if not is_store:
		cur_json_dict["callback_data"] = callback_data
	else:
		## Hiding secret key fields when stored in log files
		var cur_callback_data = callback_data.duplicate(true)
		if cur_callback_data.has("data"):
			for key in cur_callback_data["data"].keys():
				var cur_callback_field_data = cur_callback_data["data"][key]
				if cur_callback_field_data.get("secret",false):
					cur_callback_data["data"].erase(key)
			
		## Data is a custom data field
		## Result is a selection ✔ perhaps × Fields for
		cur_json_dict["callback_data"] = cur_callback_data
		
	var all_data = {}
	all_data["id"] = conversation_message_id
	all_data["type"] = conversation_message_type
	all_data["data"] = cur_json_dict
	return all_data
	
func get_store_text(is_store=true)->String:
	var cur_dict = to_dict(is_store)
	var cur_json_string = JSON.stringify(cur_dict)
	return cur_json_string

func get_store_source_text(is_store=true)->String:
	var cur_dict = to_dict(is_store)
	cur_dict["type"] = "Source"
	cur_dict["data"] = {"source_id":conversation_message_id}
	var cur_json_string = JSON.stringify(cur_dict)
	return cur_json_string

## When creating, it is necessary to specify the conversation ID of the message. One message is only stored in one conversation,
## and other conversations only retain the reference ID of this message
static func create(cur_conversation_id="",cur_conversation_message_type=null,cur_conversation_message_data=null)-> ConversationMessageAPI:
	var ins
	var cur_conversation_message_id = static_create_new_conversation_message_id(cur_conversation_id)
	if cur_conversation_message_type!=null:
		match cur_conversation_message_type:
			"Audio":
				ins = AudioConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"VoiceAudio":
				ins = VoiceAudioConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"File":
				ins = FileConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"Image":
				ins = ImageConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"InputForm":
				ins = InputFormConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"Json":
				ins = JsonConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"Quote":
				ins = QuoteConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"StreamPlain":
				ins = StreamTextConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"Plain":
				ins = TextConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"Video":
				ins = VideoConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"Xml":
				ins = XmlConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
			"Source":
				ins = SourceConversationMessage.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
	else:
		ins = ConversationMessageAPI.new(cur_conversation_message_id, cur_conversation_message_type, cur_conversation_message_data)
	return ins


static func static_create_new_conversation_message_id(cur_conversation_id):
	var cur_conversation_message_id = cur_conversation_id
	var cur_timestamp = int(Time.get_unix_time_from_system()*100)
	cur_conversation_message_id += ("_"+"%d"%cur_timestamp)
	var cur_random_number = randi_range(0,999)
	cur_conversation_message_id += ("_"+"%d"%cur_random_number)
	cur_conversation_message_id += ("_"+"e")
	return cur_conversation_message_id


## Download resources from the URL
## TODO: Because of IPFS_adapter, s3_adapter interface has changed, and this code needs to be adjusted
func base_begin_download(cur_file_url):
	if cur_file_url.begins_with("ipfs-"):
		var ipfs_adapter = await PluginManager.get_plugin_instance_by_script_name("ipfs_adapter")
		var cur_ipfs_id = cur_file_url.trim_prefix("ipfs-")
		var file_path = await ipfs_adapter.get_file(cur_ipfs_id)
		return file_path
	elif cur_file_url.begins_with("s3-"):
		var s3_adapter = await PluginManager.get_plugin_instance_by_script_name("s3_adapter")
		var cur_s3_path = cur_file_url.trim_prefix("s3-")
		cur_s3_path = cur_s3_path.trim_prefix("https://")
		cur_s3_path = cur_s3_path.trim_prefix("http://")
		var cur_s3_array = cur_s3_path.split(".",true,3)
		var bucket = cur_s3_array[0]
		var service = cur_s3_array[1]
		var region = cur_s3_array[2]
		var s3_path = cur_s3_array[3].split("/",true,1)[1]
		var file_path = await s3_adapter.get_file(s3_path, region, bucket,"","",service)
		return file_path
	pass

## Unit in bytes
static func get_format_file_size(cur_file_size):
	if typeof(cur_file_size)==TYPE_INT:
		var kb = int(cur_file_size/1024)
		var show_kb = int(kb%1024)
		var mb = int(kb/1024)
		var show_mb = mb%1024
		var gb = int(mb/1024)
		var show_gb = gb%1024
		var tb = int(gb/1024)
		var show_tb = tb
		if show_tb!=0:
			## Display TB
			return "%.2f TB"%show_tb+(show_gb*1.0/1024)
		if show_gb!=0:
			## Display GB
			return "%.2f GB"%show_gb+(show_mb*1.0/1024)
		if show_mb!=0:
			## Display MB
			return "%.2f MB"%show_mb+(show_kb*1.0/1024)
		if show_kb!=0:
			## Display KB
			return "%.2f KB"%show_kb
	if cur_file_size:
		return cur_file_size
	else:
		return "0 KB"
