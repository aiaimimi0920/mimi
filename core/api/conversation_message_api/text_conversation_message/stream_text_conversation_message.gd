extends TextConversationMessage
class_name StreamTextConversationMessage
signal add_text

func get_MessageType():
	return "StreamPlain"

var response

func reload_message():
	super.reload_message()
	if conversation_message_data:
		response = conversation_message_data.get("response",null)
	return self
	
func get_as_text()->String:
	return "[StreamText" +"]"
	
## Note that if streaming text is stored in a file, it will be converted into text
func to_dict(is_store=true)->Dictionary:
	var all_data = super.to_dict(is_store)
	all_data["type"] = "Plain"
	all_data["data"]["text"] = text
	return all_data


var response_start = false
func start_response()->void:
	if response_start == true:
		return 
	response_start = true
	if response:
		response.get_response.connect(_on_get_response)
		response.get_all_response.connect(_on_get_all_response)
		response.start_response()

func _on_get_response(line_data, content):
	text += content
	emit_signal("add_text", content, text)
	
func _on_get_all_response(all_data, content):
	text = content
	emit_signal("add_text", content, text)

