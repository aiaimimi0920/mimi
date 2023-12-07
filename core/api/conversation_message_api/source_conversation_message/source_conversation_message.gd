extends ConversationMessageAPI
class_name SourceConversationMessage
## Note that this type is more commonly used when corresponding to a message in the plugin dialogue list in the main dialogue list
## It's a one-on-one relationship

func get_MessageType():
	return "Source"

## Store the message ID of the reference
var source_id

func reload_message():
	super.reload_message()
	if conversation_message_data:
		source_id = conversation_message_data.get("source_id",null)
	return self
	
func get_as_text()->String:
	return "[MessageReference" +"]"

func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["source_id"] = source_id
	return all_data


