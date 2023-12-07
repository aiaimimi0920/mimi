extends PanelContainer

@export var InputFormFieldTscn:PackedScene

var message = null
func set_message(cur_message):
	message = cur_message
	message.connect("change_trigger_status",change_trigger_status)
	init_all_input_form_field()

func change_trigger_status(can_trigger):
	if can_trigger:
		pass
	else:
		lock_all_field()

func init_all_input_form_field():
	var all_children = %InputFormField.get_children()
	for node in all_children:
		%InputFormField.remove_child(node)
		
	var text_map = message.text_map
	for key in text_map:
		var field_data = text_map[key]
		var node = InputFormFieldTscn.instantiate()
		node.field_name = key
		node.field_data = field_data
		%InputFormField.add_child(node)
		node.connect("field_value_changed",save_all_field_data)

func save_all_field_data():
	var all_field_data = get_all_field_data()
	for key in all_field_data:
		message.cur_text_map[key] = all_field_data[key]
	pass

func get_all_field_data():
	var all_field_data = {}
	var all_children = %InputFormField.get_children()
	for node in all_children:
		var cur_data = node.get_data()
		all_field_data[cur_data["key"]] = cur_data["value"]
	return all_field_data

func lock_all_field():
	var all_children = %InputFormField.get_children()
	for node in all_children:
		node.lock_field()

