extends BaseConfigManager

func _init():
	DIR_SAVE_FILE_DEFAULT = "user://main_settings.cfg"
	DIR_SETTINGS_DEFAULT = "res://game_settings/settings"
	super()

var last_conversation_id:
	get:
		return get_value("General","LastConversationID","")
	set(value):
		set_value("General","LastConversationID",value)
