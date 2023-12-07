extends PanelContainer


var message = null
func set_message(cur_message):
	message = cur_message
	init_message_text()
	message.connect("add_text", add_message_text)
	message.start_response()

func init_message_text():
	%TextLabel.text = message.text
	%TextLabel.visible_characters = %TextLabel.text.length()

func add_message_text(content, all_text):
	%TextLabel.text = all_text
	add_show_characters()
	pass

func add_show_characters():
	if %TextLabel.visible_characters < %TextLabel.text.length():
		%Timer.start(0.02)

func _on_timer_timeout():
	%TextLabel.visible_characters +=1
	if %TextLabel.visible_characters >= %TextLabel.text.length():
		%Timer.stop()
	else:
		add_show_characters()
