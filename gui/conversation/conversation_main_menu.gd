extends PopupMenu
class_name ConversationMainMenu

# -------------------------------------------------------------------------------------------------
signal open_about_dialog
signal open_settings_dialog
signal open_manual_url
signal open_bug_tracker_url
signal export_md

# -------------------------------------------------------------------------------------------------
const ITEM_EXPORT 		:= 0
const ITEM_SETTINGS 	:= 1
const ITEM_MANUAL 		:= 2
const ITEM_BUG_TRACKER 	:= 3
const ITEM_ABOUT 		:= 4

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
	add_item(tr("MENU_SETTINGS"), ITEM_SETTINGS)
	add_separator()
	add_item(tr("MENU_MANUAL"), ITEM_MANUAL)
	add_item(tr("MENU_BUG_TRACKER"), ITEM_BUG_TRACKER)
	add_item(tr("MENU_ABOUT"), ITEM_ABOUT)

# -------------------------------------------------------------------------------------------------
func _on_MainMenu_id_pressed(id: int):
	match id:
		ITEM_EXPORT: emit_signal("export_md")
		ITEM_SETTINGS: emit_signal("open_settings_dialog")
		ITEM_MANUAL: emit_signal("open_manual_url")
		ITEM_BUG_TRACKER: emit_signal("open_bug_tracker_url")
		ITEM_ABOUT: emit_signal("open_about_dialog")

