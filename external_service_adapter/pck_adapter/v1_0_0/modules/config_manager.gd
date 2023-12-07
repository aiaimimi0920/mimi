extends BasePluginConfigManager

var export_presets_cfg_path:
	get:
		return get_value("Export","PresetsCfg","res://export_presets.cfg")
	set(value):
		set_value("Export","PresetsCfg",value)

var export_presets_cfg_backup_path:
	get:
		return get_value("Export","PresetsCfgBackup", "res://backup_export_presets.cfg")
	set(value):
		set_value("Export","PresetsCfgBackup",value)
