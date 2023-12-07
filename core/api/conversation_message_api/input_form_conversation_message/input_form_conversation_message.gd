extends ConversationMessageAPI
class_name InputFormConversationMessage

func get_MessageType():
	return "InputForm"

var text_map = {}
var cur_text_map = {}

func reload_message():
	super.reload_message()
	if conversation_message_data:
		text_map = conversation_message_data.get("text_map",null)
		cur_text_map = text_map.duplicate(true)
		for key in cur_text_map:
			cur_text_map[key] = cur_text_map[key].get("default_text","")
	return self
	
func get_as_text()->String:
	return "[InputParameter"+ " ".join(text_map.keys())+"]"

func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["text_map"] = text_map
	return all_data
