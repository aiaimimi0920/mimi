extends Node
class_name BaseConfigManager

var DIR_SAVE_FILE_DEFAULT: String = "user://main_settings.cfg"
var DIR_SETTINGS_DEFAULT: String = "res://game_settings/settings"

var config_file:ggsSaveFile

var priority_list=[]

func _init():
	reload_config_file()

func reload_config_file():
	config_file = ggsSaveFile.new()
	config_file.set_path(DIR_SAVE_FILE_DEFAULT)
	

func get_all_settings() -> PackedStringArray:
	var all_settings: PackedStringArray
	var path: String = DIR_SETTINGS_DEFAULT
	
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		var categories: PackedStringArray = dir.get_directories()
		for category in categories:
			if category.begins_with("_"):
				continue
			
			dir.change_dir(path.path_join(category))
			var settings: PackedStringArray = _get_settings_in_dir(dir)
			all_settings.append_array(settings)
			
			var groups: PackedStringArray = dir.get_directories()
			for group in groups:
				dir.change_dir(path.path_join(category).path_join(group))
				var subsettings: PackedStringArray = _get_settings_in_dir(dir)
				all_settings.append_array(subsettings)
	return all_settings


func _get_settings_in_dir(dir: DirAccess) -> PackedStringArray:
	var result: PackedStringArray
	var settings: PackedStringArray = dir.get_files()
	for setting in settings:
		if setting.ends_with(".gd"):
			continue
		result.append(dir.get_current_dir().path_join(setting))
	return result

func load_all_settings_tres():
	var all_settings: PackedStringArray = get_all_settings()
	var all_settings_tres = {}
	for setting_path in all_settings:
		var setting: ggsSetting = load(setting_path)
		setting.save_path = DIR_SAVE_FILE_DEFAULT
		all_settings_tres[setting.name] = setting
	return all_settings_tres

func _apply_settings() -> void:
	var all_settings: PackedStringArray = get_all_settings()
	for setting_path in all_settings:
		var setting: ggsSetting = load(setting_path)
		setting.save_path = DIR_SAVE_FILE_DEFAULT
		var value: Variant = setting.get_current()
		## This step will set the value to the user file
		setting.set_current(value)
		setting.apply(value)


func get_value(section: String, key: String, default: Variant = null):	
	return config_file.get_value(section, key, default)
	

func set_value(section: String, key: String, value: Variant):
	config_file.set_value(section, key, value)
	config_file.save(DIR_SAVE_FILE_DEFAULT)
