extends ConversationMessageAPI
class_name JsonConversationMessage


func get_MessageType():
	return "Json"

var json
var json_data

func reload_message():
	super.reload_message()
	if conversation_message_data:
		json = conversation_message_data.get("json",null)
		json_data = JSON.parse_string(json)
	return self

func get_as_text()->String:
	return "[Json]"


func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["json"] = JSON.stringify(json_data)
	return all_data
