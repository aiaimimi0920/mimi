extends BasePluginConfigManager

var search_configs:
	get:
		return get_value("General","SearchConfigs", '{"defaultView1":{"apply_exclude":false,"apply_include":false,"exclude":"","hide_empty_dirs":true,"icon":"res://plugin/file_list/v1_0_0/ui/assets/folder.svg","include":"","name":"(Default)"}}')
		#return get_value("General","SearchConfigs", "")
	set(value):
		set_value("General","SearchConfigs",value)
