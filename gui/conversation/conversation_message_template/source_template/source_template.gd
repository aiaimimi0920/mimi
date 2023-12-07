extends PanelContainer


var message = null
func set_message(cur_message):
	message = cur_message
	set_source()

func set_source():
	%SourceLabel.text = message.source_id

