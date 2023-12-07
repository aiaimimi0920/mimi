extends Node

var now_use_main_conversation = null

var plugin_type_map = {}

var conversation_main_map = {}
var conversation_plugin_map = {}
signal add_new_main_conversation_finished
signal add_new_plugin_conversation_finished

## It will not be directly added to the conversation during creation
func create(cur_conversation_type="main",cur_conversation_name="")-> ConversationAPI:
	var conversation = ConversationAPI.create(cur_conversation_type,cur_conversation_name) 
	add_conversation(conversation)
	return conversation

func load_by_id(cur_conversation_id="")-> ConversationAPI:
	var conversation = ConversationAPI.new(cur_conversation_id) 
	add_conversation(conversation)
	return conversation

## Note that this method is not called when it is normal, but only when the relevant records of the conversation are deleted
## After the call, the corresponding content will be deleted and moved to another folder
## After the call, the corresponding content in memory will be deleted.
func remove_conversation(cur_conversation_id=""):
	var cur_conversation = get_conversation(cur_conversation_id)
	if cur_conversation:
		var now_file_path = cur_conversation.get_file_path(true)
		var target_file_path = cur_conversation.get_file_path(false)
		DirAccess.rename_absolute(now_file_path, target_file_path)
		if cur_conversation.conversation_type == "main":
			conversation_main_map.erase(cur_conversation.conversation_id)
		else:
			conversation_plugin_map.erase(cur_conversation.conversation_id)
			plugin_type_map.erase(cur_conversation.conversation_name)
	
func create_main_conversation()-> ConversationAPI:
	return create("main","")

func create_plugin_conversation(plugin_name)-> ConversationAPI:
	return create("plugin",plugin_name)


## Note that this add is actually just adding a message reference to the message library,
## and the actual message will still be saved in the conversation
func add_conversation(cur_conversation):
	if cur_conversation.conversation_type == "main":
		conversation_main_map[cur_conversation.conversation_id] = cur_conversation
		emit_signal("add_new_main_conversation_finished", cur_conversation)
	else:
		conversation_plugin_map[cur_conversation.conversation_id] = cur_conversation
		## Note that each plugin only has one dialogue text, so directly overwrite it
		plugin_type_map[cur_conversation.conversation_name] = cur_conversation
		emit_signal("add_new_plugin_conversation_finished", cur_conversation)
	

func get_conversation(cur_conversation_id):
	return conversation_main_map.get(cur_conversation_id,conversation_plugin_map.get(cur_conversation_id))

func get_conversation_by_plugin_name(cur_plugin_name, try_create=false):
	var cur_conversation = plugin_type_map.get(cur_plugin_name, null)
	if cur_conversation == null and try_create:
		cur_conversation = create("plugin",cur_plugin_name)
	return cur_conversation


func plugin_conversation_append_message(cur_plugin_name, cur_message, main_conversation=null):
	var cur_conversation = get_conversation_by_plugin_name(cur_plugin_name, true)
	cur_conversation.append_message(cur_message, main_conversation)

func main_conversation_append_message(cur_message, main_conversation=null):
	if main_conversation == null:
		main_conversation = now_use_main_conversation
	main_conversation.append_message(cur_message)

func _ready():
	load_all_active_conversation()

func load_all_active_conversation():
	## Retrieve all conversation files from the folder
	var dir
	var all_files = []
	for cur_active_status in ["active", "inactive"]:
		for sub_folder in ["main","plugin"]:
			dir = DirAccess.open(GlobalManager.conversation_path.path_join(cur_active_status).path_join(sub_folder))
			if dir:
				if sub_folder=="main":
					all_files.append_array(dir.get_files())
				elif sub_folder=="plugin":
					for sub_dir in dir.get_directories():
						var dir_2 = DirAccess.open(GlobalManager.conversation_path.path_join(cur_active_status).path_join(sub_folder).path_join(sub_dir))
						all_files.append_array(dir_2.get_files())
						
	for cur_conversation_file_name in all_files:
		load_by_id(cur_conversation_file_name)

