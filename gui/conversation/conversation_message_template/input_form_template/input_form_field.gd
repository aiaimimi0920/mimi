extends HBoxContainer
signal field_value_changed

var field_name:
	set(val):
		field_name = val
		%KeyLabel.text = field_name
	get:
		return field_name
		
var field_data:
	set(val):
		field_data = val
		%ValueLineEdit.placeholder_text = field_data.get("placeholder_text","")
		%ValueLineEdit.text = field_data.get("default_text","")
		%ValueLineEdit.editable = true
	get:
		return field_data

## Unable to unlock after being locked according to business logic
func lock_field():
	%ValueLineEdit.editable = false

func get_data():
	return {"key":field_name,"value":%ValueLineEdit.text}


func _on_value_line_edit_text_changed(new_text):
	emit_signal("field_value_changed")
