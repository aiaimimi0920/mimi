extends PanelContainer
class_name ConversationTab

# -------------------------------------------------------------------------------------------------

const STYLE_ACTIVE = preload("res://gui/conversation/style_tab_active_dark.tres")
const STYLE_INACTIVE = preload("res://gui/conversation/style_tab_inactive_dark.tres")

# -------------------------------------------------------------------------------------------------
signal selected
signal close_requested

# -------------------------------------------------------------------------------------------------

var is_active := false
var title: String:
	set(val):
		title = val
		if %NameButton != null:
			%NameButton.text = title

var title_tooltip_text: String:
	set(val):
		title_tooltip_text = val
		if %NameButton != null:
			%NameButton.tooltip_text = title_tooltip_text


var conversation_id: String

# -------------------------------------------------------------------------------------------------
func _ready():
	set_active(false)
	%NameButton.text = title
	%NameButton.tooltip_text = title_tooltip_text

# -------------------------------------------------------------------------------------------------
func _on_NameButton_pressed():
	emit_signal("selected", self)

# -------------------------------------------------------------------------------------------------
func _on_CloseButton_pressed():
	emit_signal("close_requested", self)

# -------------------------------------------------------------------------------------------------
func set_active(active: bool) -> void:
	is_active = active
	var new_style = STYLE_INACTIVE
	if is_active:
		new_style = STYLE_ACTIVE
	set("theme_override_styles/panel", new_style)

