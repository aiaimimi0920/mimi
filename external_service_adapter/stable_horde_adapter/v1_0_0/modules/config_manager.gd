extends BasePluginConfigManager

var aihorde_url:
	get:
		return get_value("General","AIHordeUrl","https://aihorde.net")
	set(value):
		set_value("General","AIHordeUrl",value)
