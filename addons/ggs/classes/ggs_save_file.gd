@tool
extends ConfigFile
class_name ggsSaveFile

var path: String = ggsUtils.get_plugin_data().dir_save_file


func _init() -> void:
	pass

func set_path(cur_path=""):
	if cur_path == "":
		cur_path = path
	else:
		path = cur_path
	if not FileAccess.file_exists(cur_path):
		save(cur_path)
	self.load(cur_path)
	return self


func set_key(section: String, key: String, value: Variant) -> void:
	set_value(section, key, value)
	save(path)
