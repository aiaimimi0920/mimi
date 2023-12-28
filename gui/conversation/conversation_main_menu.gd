extends PopupMenu
class_name ConversationMainMenu

# -------------------------------------------------------------------------------------------------
signal open_message_dialog
signal open_ui_dialog
signal open_about_dialog
signal open_settings_dialog
signal open_manual_url
signal open_bug_tracker_url
signal export_md

# -------------------------------------------------------------------------------------------------
const ITEM_MESSAGE 		:= 0
const ITEM_UI 			:= 1
const ITEM_EXPORT 		:= 2
const ITEM_SETTINGS 	:= 3
const ITEM_MANUAL 		:= 4
const ITEM_BUG_TRACKER 	:= 5
const ITEM_ABOUT 		:= 6

# -------------------------------------------------------------------------------------------------
func _ready() -> void:
	# main menu
	_apply_language()
	#GlobalSignals.connect("language_changed", self, "_apply_language")

# -------------------------------------------------------------------------------------------------
func _apply_language() -> void:
	clear()
	## 先不启用导出功能
	#add_item(tr("MENU_EXPORT"), ITEM_EXPORT)
	add_item(tr("MENU_MESSAGE"), ITEM_MESSAGE)
	add_item(tr("MENU_UI"), ITEM_UI)
	add_separator()
	add_item(tr("MENU_SETTINGS"), ITEM_SETTINGS)
	add_separator()
	add_item(tr("MENU_MANUAL"), ITEM_MANUAL)
	add_item(tr("MENU_BUG_TRACKER"), ITEM_BUG_TRACKER)
	add_item(tr("MENU_ABOUT"), ITEM_ABOUT)

# -------------------------------------------------------------------------------------------------
func _on_MainMenu_id_pressed(id: int):
	match id:
		ITEM_MESSAGE: emit_signal("open_message_dialog")
		ITEM_UI: emit_signal("open_ui_dialog")
		ITEM_EXPORT: emit_signal("export_md")
		ITEM_SETTINGS: emit_signal("open_settings_dialog")
		ITEM_MANUAL: emit_signal("open_manual_url")
		ITEM_BUG_TRACKER: emit_signal("open_bug_tracker_url")
		ITEM_ABOUT: emit_signal("open_about_dialog")

