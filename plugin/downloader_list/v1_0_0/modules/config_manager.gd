extends BasePluginConfigManager

var preferred_downloader:
	get:
		return get_value("General","PreferredDownloader", "aria2_adapter,godot_http_adapter")
	set(value):
		set_value("General","PreferredDownloader",value)
