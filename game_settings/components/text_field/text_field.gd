@tool
extends ggsUIComponent

@onready var TextField: LineEdit = $TextField

static var static_compatible_types = [TYPE_STRING]
func _ready() -> void:
	compatible_types = [TYPE_STRING]
	static_compatible_types = compatible_types
	if Engine.is_editor_hint():
		return
	
	super()
	TextField.text_submitted.connect(_on_TextField_text_submitted)
	TextField.text_changed.connect(_on_TextField_text_submitted)


func init_value() -> void:
	super()
	TextField.text = setting_value


func _on_TextField_text_submitted(submitted_text: String) -> void:
	setting_value = submitted_text
	GGS.play_sfx(GGS.SFX.INTERACT)
	if apply_on_change:
		apply_setting()


### Setting

func reset_setting() -> void:
	super()
	TextField.text = setting_value
