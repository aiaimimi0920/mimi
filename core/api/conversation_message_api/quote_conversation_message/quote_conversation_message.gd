extends ConversationMessageAPI
class_name QuoteConversationMessage

func get_MessageType():
	return "Quote"

## Store the message ID of the reference
var quote_array

func reload_message():
	super.reload_message()
	if conversation_message_data:
		quote_array = conversation_message_data.get("quote_array",null)
	return self
	
func get_as_text()->String:
	return "[MessageReference" +"]"

func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["data"]["quote_array"] = quote_array
	return all_data
