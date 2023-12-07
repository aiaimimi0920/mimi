extends Control

@export var key_value_tscn:PackedScene
@export var group_tscn:PackedScene

var icw_node

var data:
	get:
		return data
	set(value):
		data = value
		update_ui()
		
		
func update_ui():
	var all_cilldren = %NodeContainer.get_children()
	for cur_node in all_cilldren:
		cur_node.queue_free()
	
	for cur_data in data:
		if cur_data is ggsSetting:
			if cur_data.show_visible:
				var cur_node = key_value_tscn.instantiate()
				%NodeContainer.add_child(cur_node)
				cur_node.icw_node = icw_node
				cur_node.data = cur_data
		elif cur_data is Dictionary:
			var cur_node = group_tscn.instantiate()
			%NodeContainer.add_child(cur_node)
			cur_node.icw_node = icw_node
			cur_node.data = cur_data
	pass

func apply_setting():
	var all_cilldren = %NodeContainer.get_children()
	for cur_node in all_cilldren:
		cur_node.apply_setting()
