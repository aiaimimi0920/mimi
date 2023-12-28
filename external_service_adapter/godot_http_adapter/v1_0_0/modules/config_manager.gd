extends BasePluginConfigManager

var download_dir:
	get:
		return get_value("HttpServices","DownloadDir",PluginManager.get_globalize_plugin_file_dir_path(plugin_name))
	set(value):
		set_value("HttpServices","DownloadDir",value)

var session_file:
	get:
		return get_value("HttpServices","SessionFile","")
	set(value):
		set_value("HttpServices","SessionFile",value)

