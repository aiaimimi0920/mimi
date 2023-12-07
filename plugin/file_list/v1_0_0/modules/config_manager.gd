extends BasePluginConfigManager

var preferred_cloud_storage:
	get:
		return get_value("General","PreferredCloudStorage", "cloudflare")
	set(value):
		set_value("General","PreferredCloudStorage",value)
