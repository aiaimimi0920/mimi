extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var save_dir = GlobalManager.globalize_file_path
signal update_global_stat
signal update_download_handle
signal download_start
signal download_pause
signal download_stop
signal download_complete
signal download_error
signal bt_download_complete

var task_map = {}

func get_gid(gid, auto_create = false):
	if gid not in task_map and auto_create:
		var cur_gid = Gid.new()
		cur_gid.gid = gid
		task_map[cur_gid.gid] = cur_gid
	return task_map.get(gid, null)


var aria2_singleton:
	get:
		return Engine.get_singleton("Aria2")


func _ready():
	aria2_singleton.connect("download_handle_update", download_handle_update_func)
	aria2_singleton.connect("global_stat_update", global_stat_update_func)
	aria2_singleton.connect("download_start", download_start_func)
	aria2_singleton.connect("download_pause", download_pause_func)
	aria2_singleton.connect("download_stop", download_stop_func)
	aria2_singleton.connect("download_complete", download_complete_func)
	aria2_singleton.connect("download_error", download_error_func)
	aria2_singleton.connect("bt_download_complete", bt_download_complete_func)


func download_start_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 1
	if cur_gid_node and check_need_filter(cur_gid_node):
		return false
	call_deferred("emit_signal", "download_start", gid)

func download_pause_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 2
	if cur_gid_node and check_need_filter(cur_gid_node):
		return false
	call_deferred("emit_signal", "download_pause", gid)
	
func download_stop_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 3
	if cur_gid_node and check_need_filter(cur_gid_node):
		return false
	call_deferred("emit_signal", "download_stop", gid)

func download_complete_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 4
	if cur_gid_node and check_need_filter(cur_gid_node):
		return false
	call_deferred("emit_signal", "download_complete", gid)

func download_error_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 5
	if cur_gid_node and check_need_filter(cur_gid_node):
		return false
	call_deferred("emit_signal", "download_error", gid)

func bt_download_complete_func(gid):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		cur_gid_node.last_event_type = 6
	if cur_gid_node and check_need_filter(cur_gid_node):
		return false
	call_deferred("emit_signal", "bt_download_complete", gid)


var download_speed = 0
var upload_speed = 0
var num_active = 0
var num_waiting = 0
var num_stopped = 0


func global_stat_update_func(
	cur_download_speed, cur_upload_speed, cur_num_active, cur_num_waiting, cur_num_stopped
):
	download_speed = cur_download_speed
	upload_speed = cur_upload_speed
	num_active = cur_num_active
	num_waiting = cur_num_waiting
	num_stopped = cur_num_stopped
	call_deferred(
		"emit_signal",
		"update_global_stat",
		cur_download_speed,
		cur_upload_speed,
		cur_num_active,
		cur_num_waiting,
		cur_num_stopped
	)


func download_handle_update_func(
	gid, status, completed_length, upload_length, download_speed, upload_speed, error_code
):
	var cur_gid_node = get_gid(gid)
	if cur_gid_node:
		if check_need_filter(cur_gid_node):
			return false
		cur_gid_node.set_data(aria2_singleton.get_task_info(cur_gid_node.gid))
		call_deferred(
			"emit_signal",
			"update_download_handle",
			gid,
			status,
			completed_length,
			upload_length,
			download_speed,
			upload_speed,
			error_code
		)


func new_task(uris, options):
	var cur_gids = await aria2_singleton.new_task(PackedStringArray(uris), options)
	for cur_gid in cur_gids:
		var cur_gid_node = get_gid(cur_gid, true)
		cur_gid_node.set_data(aria2_singleton.get_task_info(cur_gid))
	return cur_gids


func new_metalink_task(metalink_file_path, options):
	var cur_gids = await aria2_singleton.new_metalink_task(metalink_file_path, options)
	for cur_gid in cur_gids:
		var cur_gid_node = get_gid(cur_gid, true)
		cur_gid_node.set_data(aria2_singleton.get_task_info(cur_gid))
	return cur_gids


func new_bt_task(bt_file_path, options):
	var cur_gids = await aria2_singleton.new_bt_task(bt_file_path, options)
	for cur_gid in cur_gids:
		var cur_gid_node = get_gid(cur_gid, true)
		cur_gid_node.set_data(aria2_singleton.get_task_info(cur_gid))
	return cur_gids

func all_task_list():
	var cur_1 = await active_task_list()
	var cur_2 = await waiting_task_list()
	var cur_3 = await stopped_task_list()
	return cur_1+cur_2+cur_3

func check_need_filter(cur_data):
	if cur_data["files"][0]["waiting_uris"].size()>0:
		if cur_data["files"][0]["waiting_uris"][0].begins_with("http://tracker") or cur_data["files"][0]["waiting_uris"][0].ends_with("/announce"):
			return true
	if cur_data["files"][0]["used_uris"].size()>0:
		if cur_data["files"][0]["used_uris"][0].begins_with("http://tracker") or cur_data["files"][0]["used_uris"][0].ends_with("/announce"):
			return true
	return false

func active_task_list():
	var cur_gids = await aria2_singleton.active_task_list()
	var ret_cur_gids = []
	for cur_gid in cur_gids:
		var cur_data = aria2_singleton.get_task_info(cur_gid)
		if check_need_filter(cur_data):
			continue

		var cur_gid_node = get_gid(cur_gid, true)
		cur_gid_node.set_data(cur_data)
		ret_cur_gids.append(cur_gid)
	return ret_cur_gids

func waiting_task_list():
	var cur_gids = await aria2_singleton.waiting_task_list()
	var ret_cur_gids = []
	for cur_gid in cur_gids:
		var cur_data = aria2_singleton.get_task_info(cur_gid)
		if check_need_filter(cur_data):
			continue
		var cur_gid_node = get_gid(cur_gid, true)
		cur_gid_node.set_data(cur_data)
		ret_cur_gids.append(cur_gid)
	return ret_cur_gids

func stopped_task_list():
	var cur_gids = await aria2_singleton.stopped_task_list()
	var ret_cur_gids = []
	for cur_gid in cur_gids:
		var cur_data = aria2_singleton.get_task_info(cur_gid)
		#printt("cur_data",cur_data)
		if check_need_filter(cur_data):
			continue
		var cur_gid_node = get_gid(cur_gid, true)
		cur_gid_node.set_data(cur_data)
		ret_cur_gids.append(cur_gid)
	return ret_cur_gids

func delete_task(gid, force = false, delete_file=false):
	var task_info = null
	if delete_file == true:
		task_info=aria2_singleton.get_task_info(gid)
	await aria2_singleton.delete_task(gid, force)
	if task_info and delete_file:
		for cur_file_info in task_info["files"]:
			DirAccess.remove_absolute(cur_file_info["path"])
	return true


func resume_task(gid):
	return await aria2_singleton.resume_task(gid)


func pause_task(gid, force = false):
	return await aria2_singleton.pause_task(gid, force)


func change_position(gid, pos, how = 1):
	return await aria2_singleton.change_position(gid, pos, how)


func pause_all_tasks(force = false):
	return await aria2_singleton.pause_all_tasks(force)

func resume_all_tasks():
	return await aria2_singleton.resume_all_tasks()

func change_global_options(options):
	return await aria2_singleton.change_global_options(options)

func add_user_options(options):
	return await aria2_singleton.add_user_options(options)


func remove_user_options(options_keys):
	return await aria2_singleton.remove_user_options(PackedStringArray(options_keys))


class Gid:
	var gid = ""
	var status = 0
	var total_length = 0
	var completed_length = 0
	var upload_length = 0
	var download_speed = 0
	var upload_speed = 0
	var error_code = 0
	var dir = ""
	var connections = 0
	var files = [""]
	var last_event_type = -1
	var following = 0

	func set_data(cur_data):
		gid = cur_data["gid"]
		status = cur_data["status"]
		total_length = cur_data["total_length"]
		completed_length = cur_data["completed_length"]
		upload_length = cur_data["upload_length"]
		download_speed = cur_data["download_speed"]
		upload_speed = cur_data["upload_speed"]
		error_code = cur_data["error_code"]
		dir = cur_data["dir"]
		connections = cur_data["connections"]
		files = cur_data["files"]
