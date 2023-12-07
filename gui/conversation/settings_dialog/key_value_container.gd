extends HBoxContainer

@export var arrow_list_tscn:PackedScene
@export var check_box_tscn:PackedScene
@export var input_btn_tscn:PackedScene
@export var option_list_tscn:PackedScene
@export var radio_list_tscn:PackedScene
@export var slider_tscn:PackedScene
@export var spin_box_tscn:PackedScene
@export var switch_tscn:PackedScene
@export var text_field_tscn:PackedScene
@export var toggle_btn_tscn:PackedScene

var icw_node

var data:
	get:
		return data
	set(value):
		data = value
		update_ui()
		
		
func update_ui():
	var all_cilldren = %ValueContainer.get_children()
	for cur_node in all_cilldren:
		cur_node.queue_free()
	
	%KeyLabel.text = data.show_name
	
	add_by_show_ui(data.show_ui)
	var com_scene: PackedScene
	


func add_by_show_ui(show_type,is_auto=false):
	var ui_node = null
	match show_type:
		0:
			## None，Self matching mode
			if data.value_type == TYPE_BOOL:
				## Prioritize using Checkbox
				return add_by_show_ui(2,true)
			elif data.value_type == TYPE_STRING:
				## Prioritize using Text Field
				return add_by_show_ui(9,true)
			elif data.value_type == TYPE_INT:
				if data.value_hint == PROPERTY_HINT_ENUM:
					## Prioritize using OptionList
					return add_by_show_ui(4,true)
				else:
					## Prioritize using SpineBox
					return add_by_show_ui(7,true)
			elif data.value_type == TYPE_FLOAT:
				## Prioritize using Slider 
				return add_by_show_ui(6,true)
			elif data.value_type == TYPE_ARRAY:
				## Prioritize using Input Btn, 
				## Note that this writing method can easily cause problems with the setting of values represented by other array types
				return add_by_show_ui(3,true)
				pass
			pass
		1:
			# Arrow List
			ui_node = add_arrow_list_com()
		2:
			# Checkbox
			ui_node = add_check_box_com()
		3:
			# Input Btn
			ui_node = add_input_btn_com()
		4:
			# Option List
			ui_node = add_option_list_com()
		5:
			# Radio List
			ui_node = add_radio_list_com()
		6:
			# Slider
			ui_node = add_slider_com()
		7:
			# SpinBox
			ui_node = add_spin_box_com()
		8:
			# Switch
			ui_node = add_switch_com()
		9:
			# Text Field
			ui_node = add_text_field_com()
		10:
			# Toggle Btn
			ui_node = add_toggle_btn_com()
	
	if ui_node == null and show_type!=0 and is_auto==false:
		## If there is no node, revert back to self matching mode
		ui_node = add_by_show_ui(0)
	return ui_node

# finish
func add_arrow_list_com():
	var component = add_base_com(arrow_list_tscn)
	if component == null:
		return null
	if data.value_hint == PROPERTY_HINT_ENUM:
		var hint_array = data.value_hint_string.split(",")
		if data.value_type == TYPE_INT:
			var lsat_index = 0
			for cur_index in range(len(hint_array)):
				var cur_data = hint_array[cur_index]
				var split_data = cur_data.split(":")
				if len(split_data)>=2:
					lsat_index = split_data[1]
					
				component.options.append(split_data[0])
				component.option_ids.append(lsat_index)
				lsat_index+=1
		elif data.value_type == TYPE_BOOL:
			## If it is a variable of type bool, there are only two options
			var lsat_index = 0
			if len(hint_array) != 2:
				return 
			for cur_index in range(len(hint_array)):
				var cur_data = hint_array[cur_index]
				var split_data = cur_data.split(":")
				if len(split_data)>=2:
					lsat_index = split_data[1]
				component.options.append(split_data[0])
				component.option_ids.append(lsat_index)
				lsat_index+=1
	return component

# finish
func add_check_box_com():
	var component = add_base_com(check_box_tscn)
	if component == null:
		return null
	return component

func add_input_btn_com():
	var component = add_base_com(input_btn_tscn)
	if component == null:
		return null
	component.accept_modifiers = true
	component.accept_mouse = true
	component.accept_axis = true
	component.ICW = icw_node
	return component

# finish
func add_option_list_com():
	var component = add_base_com(option_list_tscn)
	if component == null:
		return null
	component.use_ids = true
	if data.value_hint == PROPERTY_HINT_ENUM:
		var hint_array = data.value_hint_string.split(",")
		if data.value_type == TYPE_INT:
			var lsat_index = 0
			for cur_index in range(len(hint_array)):
				var cur_data = hint_array[cur_index]
				var split_data = cur_data.split(":")
				if len(split_data)>=2:
					lsat_index = split_data[1]
				component.Btn.add_item(split_data[0],lsat_index)
				lsat_index+=1
		elif data.value_type == TYPE_BOOL:
			var lsat_index = 0
			if len(hint_array) != 2:
				return 
			for cur_index in range(len(hint_array)):
				var cur_data = hint_array[cur_index]
				var split_data = cur_data.split(":")
				if len(split_data)>=2:
					lsat_index = split_data[1]
				component.Btn.add_item(split_data[0],lsat_index)
				lsat_index+=1
	return component

# finish
func add_radio_list_com():
	var component = add_base_com(radio_list_tscn)
	if component == null:
		return null
	if data.value_hint == PROPERTY_HINT_ENUM:
		var hint_array = data.value_hint_string.split(",")
		if data.value_type == TYPE_INT:
			var lsat_index = 0
			for cur_index in range(len(hint_array)):
				var cur_data = hint_array[cur_index]
				var split_data = cur_data.split(":")
				if len(split_data)>=2:
					lsat_index = split_data[1]
				component.option_ids.append(lsat_index)
				var cur_node = Button.new()
				cur_node.toggle_mode = true
				cur_node.text = split_data[0]
				component.ActiveList.add_child(cur_node)
				cur_node.button_group = component.btngrp
				cur_node.mouse_entered.connect(component._on_AnyBtn_mouse_entered.bind(cur_node))
				cur_node.focus_entered.connect(component._on_AnyBtn_focus_entered)
				lsat_index+=1
		elif data.value_type == TYPE_BOOL:
			## If it is a variable of type bool, there are only two options
			var lsat_index = 0
			if len(hint_array) != 2:
				return 
			for cur_index in range(len(hint_array)):
				var cur_data = hint_array[cur_index]
				var split_data = cur_data.split(":")
				if len(split_data)>=2:
					lsat_index = split_data[1]
				component.option_ids.append(lsat_index)
				var cur_node = Button.new()
				cur_node.toggle_mode = true
				cur_node.text = split_data[0]
				component.ActiveList.add_child(cur_node)
				cur_node.button_group = component.btngrp
				cur_node.mouse_entered.connect(component._on_AnyBtn_mouse_entered.bind(cur_node))
				cur_node.focus_entered.connect(component._on_AnyBtn_focus_entered)
				lsat_index+=1
	return component


# finish
func add_slider_com():
	var component = add_base_com(slider_tscn)
	if component == null:
		return null
	if data.value_hint == PROPERTY_HINT_RANGE:
		var hint_array = data.value_hint_string.split(",")
		if data.value_type == TYPE_FLOAT:
			if len(hint_array)>=2:
				component.slider.min_value = hint_array[0].to_float()
				component.slider.max_value = hint_array[1].to_float()
			if len(hint_array)>2:
				component.slider.step = hint_array[2].to_float()
			else:
				component.slider.step = 0.01
		elif data.value_type == TYPE_INT:
			if len(hint_array)>=2:
				component.slider.min_value = hint_array[0].to_int()
				component.slider.max_value = hint_array[1].to_int()
			if len(hint_array)>2:
				component.slider.step = hint_array[2].to_int()
			else:
				component.slider.step = 1
	return component

# finish
func add_spin_box_com():
	var component = add_base_com(spin_box_tscn)
	if component == null:
		return null
	if data.value_hint == PROPERTY_HINT_RANGE:
		var hint_array = data.value_hint_string.split(",")
		if data.value_type == TYPE_FLOAT:
			if len(hint_array)>=2:
				component.spin_box.min_value = hint_array[0].to_float()
				component.spin_box.max_value = hint_array[1].to_float()
			if len(hint_array)>2:
				component.spin_box.step = hint_array[2].to_float()
			else:
				component.spin_box.step = 0.01
		elif data.value_type == TYPE_INT:
			if len(hint_array)>=2:
				component.spin_box.min_value = hint_array[0].to_int()
				component.spin_box.max_value = hint_array[1].to_int()
			if len(hint_array)>2:
				component.spin_box.step = hint_array[2].to_int()
			else:
				component.spin_box.step = 1
	
	return component
	
# finish
func add_switch_com():
	var component = add_base_com(switch_tscn)
	if component == null:
		return null
	return component

# finish
func add_text_field_com():
	var component = add_base_com(text_field_tscn)
	if component == null:
		return null
	return component

# finish
func add_toggle_btn_com():
	var component = add_base_com(toggle_btn_tscn)
	if component == null:
		return null
	return component


## Just adding basic controls, as some controls require resetting some properties
func add_base_com(com_scene):
	var Component: Control = com_scene.instantiate()
	if data.value_type not in Component.static_compatible_types:
		## Type mismatch returns null
		return null
	Component.setting = data
	Component.apply_on_change = false
	Component.grab_focus_on_mouse_over = ggsUtils.get_plugin_data().grab_focus_on_mouse_over_all
	%ValueContainer.add_child(Component, true)
	Component.owner = self
	return Component

func apply_setting():
	var all_cilldren = %ValueContainer.get_children()
	for cur_node in all_cilldren:
		cur_node.apply_setting()
