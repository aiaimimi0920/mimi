extends ConversationMessageAPI
class_name TextConversationMessage


func get_MessageType():
	return "Plain"

var text:String = ""

func reload_message():
	super.reload_message()
	if conversation_message_data:
		text = conversation_message_data.get("text","")
	return self
	
func get_as_text()->String:
	return text

func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["text"] = text
	return all_data
