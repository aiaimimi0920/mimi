extends VBoxContainer

@export var conversation_message_container_tscn:PackedScene

var conversation:ConversationAPI:
	set(val):
		if conversation==val:
			return 
		if conversation:
			conversation.disconnect("append_one_message", append_message_ui)
		conversation = val
		if conversation:
			conversation.connect("append_one_message", append_message_ui)
		init_conversation_ui()
		
func init_conversation_ui():
	var all_children = get_children()
	for node in all_children:
		remove_child(node)
	
	for cur_message in conversation:
		append_message_ui(cur_message)
	
var append_message_last_node
var append_message_array = []


func append_message_ui(cur_message):
	if cur_message.show_message_type == 0:
		append_message_array = []
		append_message_array.append(cur_message)
		var node = conversation_message_container_tscn.instantiate()
		add_child(node)
		if append_message_last_node:
			append_message_last_node.update_button_ui(false)
		append_message_last_node = node
		node.message_array = append_message_array
	elif cur_message.show_message_type == 1:
		append_message_array = []
		append_message_array.append(cur_message)
	elif cur_message.show_message_type == 2:
		append_message_array.append(cur_message)
	elif cur_message.show_message_type == 3:
		append_message_array.append(cur_message)
		var node = conversation_message_container_tscn.instantiate()
		add_child(node)
		if append_message_last_node:
			append_message_last_node.update_button_ui(false)
		append_message_last_node = node
		node.message_array = append_message_array
		node.update_button_ui(true)

