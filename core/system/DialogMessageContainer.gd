extends MarginContainer


signal inactive_dialog

func _input(event):
	var wheel_direction = 0.0
	if (event is InputEventMouseButton): 
		if event.double_click and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			emit_signal("inactive_dialog")
