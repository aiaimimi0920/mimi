extends PanelContainer

@export var text_edit_min_y = 80

func _on_code_edit_text_changed():
	if %CodeEdit.size.y >= text_edit_min_y*3:
		%CodeEdit.custom_minimum_size.y = text_edit_min_y*3
		%CodeEdit.scroll_fit_content_height = false
	else:
		%CodeEdit.custom_minimum_size.y = text_edit_min_y
		%CodeEdit.scroll_fit_content_height = true

var message = null
func set_message(cur_message):
	message = cur_message
	%CodeEdit.text = message.xml

func _ready():
	%CodeEdit.custom_minimum_size.y = text_edit_min_y
