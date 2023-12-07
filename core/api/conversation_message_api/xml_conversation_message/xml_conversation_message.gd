extends ConversationMessageAPI
class_name XmlConversationMessage


func get_MessageType():
	return "Xml"

var xml

func reload_message():
	super.reload_message()
	if conversation_message_data:
		xml = conversation_message_data.get("xml",null)
	return self

func get_as_text()->String:
	return "[Xml]"


func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["xml"] = xml
	return all_data
