extends BasePluginConfigManager

var download_dir:
	get:
		return get_value("Aria2Services","DownloadDir","")
	set(value):
		set_value("Aria2Services","DownloadDir",value)

var session_file:
	get:
		return get_value("Aria2Services","SessionFile","")
	set(value):
		set_value("Aria2Services","SessionFile",value)

var last_track_update:
	get:
		return get_value("Aria2Services","LastTrackUpdateTime","0000-00-00")
	set(value):
		set_value("Aria2Services","LastTrackUpdateTime",value)

var trackers_url:
	get:
		return get_value("Aria2Services","TrackersURL","https://cdn.jsdelivr.net/gh/ngosang/trackerslist/trackers_best.txt,https://cdn.jsdelivr.net/gh/ngosang/trackerslist/trackers_best_ip.txt")
	set(value):
		set_value("Aria2Services","TrackersURL",value)


var download_gids = []

func apply_all():
	var options = {}
	if download_dir=="":
		options["dir"] = PluginManager.get_globalize_plugin_file_dir_path(plugin_name)
	else:
		options["dir"] = download_dir
	
	if session_file=="":
		options["input-file"] = PluginManager.get_globalize_plugin_file_dir_path(plugin_name).path_join("aria2.session")
		options["save-session"] = options["input-file"]
	else:
		options["input-file"] = session_file
		options["save-session"] = session_file
	
	plugin_node.change_global_options(options)
	
	if not FileAccess.file_exists(options["input-file"]):
		var file = FileAccess.open(options["input-file"], FileAccess.WRITE)
		file.close()
	
	if last_track_update<Time.get_date_string_from_system():
		## update tracker
		download_gids = []
		var cur_save_file = PluginManager.get_globalize_plugin_file_dir_path(plugin_name)
		plugin_node.connect("download_complete", download_track_file_finish_func)
		for one_url in trackers_url.split(","):
			DirAccess.remove_absolute(cur_save_file.path_join(one_url.get_file()))
			var cur_download_gids = plugin_node.new_task([one_url],{"dir":cur_save_file})
			for key in cur_download_gids:
				download_gids.append(key)
	else:
		var trackers_str = get_trackers_str()
		options["bt-tracker"] = trackers_str

	plugin_node.add_user_options(options)


func get_trackers_str():
	var cur_save_file = PluginManager.get_globalize_plugin_file_dir_path(plugin_name)
	var cur_array = []
	for one_url in trackers_url.split(","):
		var cur_string = FileAccess.get_file_as_string(cur_save_file.path_join(one_url.get_file()))
		cur_array.append_array(cur_string.split("\n",false))
	var trackers_str = "\n".join(cur_array)
	return trackers_str

func download_track_file_finish_func(gid):
	if gid in download_gids:
		download_gids.erase(gid)
	if download_gids.size()==0:
		plugin_node.disconnect("download_complete", download_track_file_finish_func)
		last_track_update=Time.get_date_string_from_system()
		## If you try to only update the bt tracker, it will get stuck in an infinite restart, and the reason is currently unknown
		apply_all()
