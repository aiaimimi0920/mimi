extends RefCounted

class_name ConversationAPI

var conversation_id:String
var user_id:String
var conversation_type:String
var conversation_name:String
var create_timestamp:int
var random_number:int 

var message_chain = []
## The current stored message content will not be changed
var last_message_store_line = 0
var iter_current:int = 0

signal append_one_message

func _iter_should_continue()->bool:
	return (iter_current < message_chain.size())


func _iter_init(_arg)->bool:
	iter_current = 0
	return _iter_should_continue()


func _iter_next(_arg)->bool:
	iter_current += 1
	return _iter_should_continue()


func _iter_get(_arg)->ConversationMessageAPI:
	return get_message(iter_current)

func get_message(index:int)->ConversationMessageAPI:
	return message_chain[index]

func _init(cur_conversation_id):
	conversation_id = cur_conversation_id
	var parameter_array = conversation_id.split("_")
	var index = 0
	user_id = parameter_array[index]
	index += 1
	conversation_type = parameter_array[index]
	index += 1
	if conversation_type == "main":
		conversation_name = ""
	else:
		var cur_parameter_array = parameter_array.slice(index,-3)
		if len(cur_parameter_array)==1:
			conversation_name = cur_parameter_array[0]
		else:
			conversation_name="_".join(cur_parameter_array)
		index += 1
		
	create_timestamp = int(parameter_array[-3])
	random_number = int(parameter_array[-2])
	reload_message_chain()

func get_file_path(is_active = true):
	var cur_active_state = "active" if is_active else "inactive"
	var file_path = ""
	if conversation_type == "main":
		file_path = GlobalManager.conversation_path.path_join(cur_active_state).path_join(conversation_type)
	else:
		file_path = GlobalManager.conversation_path.path_join(cur_active_state).path_join("plugin").path_join(conversation_name)
	
	file_path = file_path.path_join(conversation_id)
	return file_path

func reload_message_chain():
	message_chain = []
	last_message_store_line = 0
	var cur_file_path = get_file_path()
	if not FileAccess.file_exists(cur_file_path):
		var make_dir = DirAccess.make_dir_recursive_absolute(cur_file_path.get_base_dir())
		var make_file = FileAccess.open(cur_file_path, FileAccess.WRITE)
		pass
	var file = FileAccess.open(cur_file_path, FileAccess.READ)
	if not file:
		return 
	while file.get_position() < file.get_length():
		var content = file.get_line()
		var data = JSON.parse_string(content)
		if data:
			## Load the message field
			var ins =  ConversationMessageManager.create(data["type"], data["data"], data["id"])
			message_chain.append(ins)
		last_message_store_line+=1

func append_message(cur_message,main_conversation=null):
	message_chain.append(cur_message)
	emit_signal("append_one_message",cur_message)
	if conversation_type=="main":
		pass
	else:
		## Synchronize to the current main conversation, 
		if main_conversation==null:
			main_conversation = ConversationManager.now_use_main_conversation
		if main_conversation:
			main_conversation.append_message(cur_message)



static func create(cur_conversation_type="main",cur_conversation_name="")-> ConversationAPI:
	var cur_conversation_id = ""
	var cur_user_id = "229CBCE9-F615-44D1-8ABB-9ed76231d6c1"
	if Platform.me_user:
		cur_user_id = Platform.me_user.id
	cur_conversation_id += cur_user_id
	cur_conversation_id += ("_"+cur_conversation_type)
	if cur_conversation_type!="main":
		cur_conversation_id += ("_"+cur_conversation_name)
	
	var cur_timestamp = int(Time.get_unix_time_from_system()*100)
	cur_conversation_id += ("_"+"%d"%cur_timestamp)
	var cur_random_number = randi_range(0,999)
	cur_conversation_id += ("_"+"%d"%cur_random_number)
	cur_conversation_id += ("_"+"e")
	var ins:ConversationAPI = ConversationAPI.new(cur_conversation_id)
	return ins


func save_file(store_source=false): 
	var cur_file_path = get_file_path()
	var file = FileAccess.open(cur_file_path, FileAccess.WRITE)
	var cur_last_message_store_line = last_message_store_line
	for i in range(cur_last_message_store_line,len(message_chain)):
		var cur_message = message_chain[i]
		if cur_message.conversation_id == conversation_id or store_source:
			file.store_line(cur_message.get_store_text())
		else:
			## If different, only store the reference message
			file.store_line(cur_message.get_store_source_text())
			pass
		last_message_store_line+=1

## Export as a MD file
func export_md():
	var f_path:String = GlobalManager.file_path.path_join(conversation_id+Time.get_datetime_string_from_system().replace(":","-")+".md")
	var file = FileAccess.open(f_path, FileAccess.WRITE)
	var cur_last_message_store_line = last_message_store_line
	for i in range(len(message_chain)):
		var cur_message = message_chain[i]
		file.store_line(cur_message.get_store_text())
