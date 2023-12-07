extends TextureButton

# -------------------------------------------------------------------------------------------------
@export var hover_tint := Color.WHITE
@export var pressed_tint := Color.WHITE
var _normal_tint: Color

# -------------------------------------------------------------------------------------------------
func _ready() -> void:
	_normal_tint = self_modulate
	connect("mouse_entered", _on_mouse_entered)
	connect("mouse_exited", _on_mouse_exited)
	connect("pressed", _on_pressed)

	if toggle_mode && button_pressed:
		self_modulate = pressed_tint

# -------------------------------------------------------------------------------------------------
func _exit_tree() -> void:
	disconnect("mouse_entered", _on_mouse_entered)
	disconnect("mouse_exited", _on_mouse_exited)
	disconnect("pressed", _on_pressed)

# -------------------------------------------------------------------------------------------------
func _on_mouse_entered() -> void:
	if !button_pressed:
		self_modulate = hover_tint

# -------------------------------------------------------------------------------------------------
func _on_mouse_exited() -> void:
	if !button_pressed:
		self_modulate = _normal_tint

# -------------------------------------------------------------------------------------------------
func _toggled(toggled_on) -> void:
	if toggled_on:
		self_modulate = pressed_tint
	else:
		self_modulate = _normal_tint

# -------------------------------------------------------------------------------------------------
func _pressed() -> void:
	_on_pressed()

# -------------------------------------------------------------------------------------------------
func _on_pressed() -> void:
	if toggle_mode:
		if button_pressed:
			self_modulate = pressed_tint
		else:
			self_modulate = _normal_tint
