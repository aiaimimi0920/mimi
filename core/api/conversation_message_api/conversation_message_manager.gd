extends Node

var message_map = {}

## It will not be directly added to the conversation during creation
func main_create(cur_conversation_message_type=null,cur_conversation_message_data=null, cur_conversation=null)-> ConversationMessageAPI:
	var cur_conversation_id = ""
	if cur_conversation == null:
		cur_conversation = ConversationManager.now_use_main_conversation
		
	cur_conversation_id = cur_conversation.conversation_id
	var message = ConversationMessageAPI.create(cur_conversation_id,cur_conversation_message_type,cur_conversation_message_data) 
	add_message(message)
	return message
	
func plugin_create(cur_conversation_message_type=null,cur_conversation_message_data=null, cur_conversation=null, cur_plugin_name="")-> ConversationMessageAPI:
	var cur_conversation_id = ""
	if cur_conversation == null:
		cur_conversation = ConversationManager.get_conversation_by_plugin_name(cur_plugin_name, true)
	cur_conversation_id = cur_conversation.conversation_id
	var message = ConversationMessageAPI.create(cur_conversation_id,cur_conversation_message_type,cur_conversation_message_data) 
	add_message(message)
	return message

func create(cur_conversation_message_type=null,cur_conversation_message_data=null, cur_conversation_id="")-> ConversationMessageAPI:
	var message = ConversationMessageAPI.create(cur_conversation_id,cur_conversation_message_type,cur_conversation_message_data) 
	add_message(message)
	return message_map[message.conversation_message_id]

## Note that this add is actually just adding a message reference to the message library, and the actual message will still be saved in the conversation
func add_message(cur_message):
	if cur_message.conversation_message_id not in message_map:
		message_map[cur_message.conversation_message_id] = cur_message
	else:
		if cur_message.conversation_message_type != "Source" and message_map[cur_message.conversation_message_id].conversation_message_type=="Source":
			message_map[cur_message.conversation_message_id] = cur_message

func get_message(message_id, try_load_conversation=false):
	var cur_message = message_map.get(message_id,null)
	if cur_message == null and try_load_conversation:
		## You can try loading the corresponding plugin
		var parameter_array = message_id.split("_e_")
		var cur_conversation_id = parameter_array[0]+"_e"
		ConversationManager.load_by_id(cur_conversation_id)
		cur_message = message_map.get(message_id,null)
	return cur_message
