extends HBoxContainer
signal yes_or_no

var message_array:
	set(val):
		message_array = val
		init_message_array_ui()

func init_message_array_ui():
	%ConversationMessage.message_array = message_array
	%ConversationMessage.update_message_array_ui()
	
	if (not message_array.is_empty()):
		visible = true
		## TODO:Be sure to set icons
		if message_array[-1].is_bot:
			%LeftIcon.modulate.a = 1
			%RightIcon.modulate.a = 0
		else:
			%LeftIcon.modulate.a = 0
			%RightIcon.modulate.a = 1
	else:
		## no message？
		visible = false


func _on_conversation_message_yes_or_no(cur_message, cur_result):
	emit_signal("yes_or_no", cur_message, cur_result)


func update_button_ui(is_last):
	%ConversationMessage.update_button_ui(is_last)
