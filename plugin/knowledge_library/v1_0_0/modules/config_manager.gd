extends BasePluginConfigManager

var load_files_path:
	get:
		return get_value("Library","LoadFilesPath","")
	set(value):
		set_value("Library","LoadFilesPath",value)


var exclude_filter:
	get:
		return get_value("Library","ExcludeFilter","")
	set(value):
		set_value("Library","ExcludeFilter",value)
		
	
var include_filter:
	get:
		return get_value("Library","IncludeFilter","")
	set(value):
		set_value("Library","IncludeFilter",value)

func apply_all():
	plugin_node.set_filter(include_filter, exclude_filter)
