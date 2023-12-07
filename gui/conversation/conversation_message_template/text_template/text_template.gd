extends PanelContainer


var message = null
func set_message(cur_message):
	message = cur_message
	set_message_text()

func set_message_text():
	%TextLabel.text = message.text
