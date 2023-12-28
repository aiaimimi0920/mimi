extends Control

var plugin_node = null


func get_plugin_node():
	if plugin_node and is_instance_valid(plugin_node):
		return plugin_node
	var _plugin_result = PluginManager.get_plugin_name(get_script())
	plugin_node = await PluginManager.get_plugin_instance_by_script_name(_plugin_result[0])
	return plugin_node


func update():
	pass


func _ready():
	await init_ui()
	await init_signal()
	await _on_refresh_button_pressed()


func init_signal():
	var cur_plugin_node = await get_plugin_node()
	cur_plugin_node.connect("add_download_adapter", add_download_adapter_func)
	cur_plugin_node.connect("update_global_stat", global_stat_update_func)
	cur_plugin_node.connect("update_download_handle", download_handle_update_func)

	cur_plugin_node.connect("download_start",download_start_func)
	cur_plugin_node.connect("download_pause",download_pause_func)
	cur_plugin_node.connect("download_stop",download_stop_func)
	cur_plugin_node.connect("download_complete",download_complete_func)
	cur_plugin_node.connect("download_error",download_error_func)
	cur_plugin_node.connect("bt_download_complete",bt_download_complete_func)

func download_start_func(gid, adapter_plugin_name):
	await update_by_gid_and_plugin_name(gid, adapter_plugin_name)

func download_pause_func(gid, adapter_plugin_name):
	await update_by_gid_and_plugin_name(gid, adapter_plugin_name)

func download_stop_func(gid, adapter_plugin_name):
	await update_by_gid_and_plugin_name(gid, adapter_plugin_name)

func download_complete_func(gid, adapter_plugin_name):
	await update_by_gid_and_plugin_name(gid, adapter_plugin_name)

func download_error_func(gid, adapter_plugin_name):
	await update_by_gid_and_plugin_name(gid, adapter_plugin_name)

func bt_download_complete_func(gid, adapter_plugin_name):
	await update_by_gid_and_plugin_name(gid, adapter_plugin_name)

func init_ui():
	await init_downloader_list_items()
	await update_task_list()


func init_downloader_list_items():
	var cur_plugin_node = await get_plugin_node()
	%DownloaderListPopupMenu.clear()
	%DownloaderListPopupMenu.add_check_item("ALL_SELECTED", 0)
	%DownloaderListPopupMenu.add_separator()

	for downloader_adapter_name in cur_plugin_node.downloader_adapter_name_list:
		%DownloaderListPopupMenu.add_check_item(downloader_adapter_name)
		%DownloaderListPopupMenu.set_item_checked(%DownloaderListPopupMenu.item_count - 1, true)
	%DownloaderListPopupMenu.set_item_checked(0, true)
	update_show_downloader_adapter()


func add_download_adapter_func(item_name):
	%DownloaderListPopupMenu.add_check_item(item_name)
	%DownloaderListPopupMenu.set_item_checked(%DownloaderListPopupMenu.item_count - 1, true)
	update_show_downloader_adapter()


func _on_downloader_list_popup_menu_index_pressed(index):
	if index == 0:
		var is_item_checked = %DownloaderListPopupMenu.is_item_checked(index)
		for i in range(%DownloaderListPopupMenu.item_count):
			if %DownloaderListPopupMenu.is_item_checkable(i):
				%DownloaderListPopupMenu.set_item_checked(i, not is_item_checked)
	else:
		var is_item_checked = %DownloaderListPopupMenu.is_item_checked(index)
		if %DownloaderListPopupMenu.is_item_checkable(index):
			%DownloaderListPopupMenu.set_item_checked(index, not is_item_checked)
	update_show_downloader_adapter()
	update_task_list()


var task_node_tscn = null

func update_task_list():
	var cur_plugin_node = await get_plugin_node()
	if task_node_tscn == null:
		task_node_tscn = load(cur_plugin_node.get_absolute_path("ui/task_node.tscn"))
	
	for gid_id in cur_plugin_node.task_map:
		if %TaskNodeContainer.get_node_or_null(gid_id):
			pass
		else:
			var cur_gid_info = await cur_plugin_node.get_gid_info(gid_id)
			if cur_gid_info==null or cur_gid_info.dir==null:
				continue
			var cur_node = task_node_tscn.instantiate()
			%TaskNodeContainer.add_child(cur_node)
			cur_node.name = gid_id
			cur_node.update_ui(cur_gid_info, cur_plugin_node.task_map[gid_id].target_plugin_name)

	for cur_node in %TaskNodeContainer.get_children():
		if (
			cur_node.adapter_plugin_name in show_downloader_list
			and (
				%DownloadStat.selected == 0
				or (%DownloadStat.selected == 1 and cur_node.gid_node.status in [0, 1, 2] and cur_node.gid_node.last_event_type in [-1, 1, 2])
				or (%DownloadStat.selected == 2 and (cur_node.gid_node.status in [3, 4, 5] or cur_node.gid_node.last_event_type in [3, 4, 5, 6]))
			)
		):
			cur_node.visible = true
		else:
			cur_node.visible = false
	pass


func _on_downloader_list_toggled(toggled_on):
	if toggled_on:
		%DownloaderListPopupMenu.popup(
			Rect2i(Vector2i(%DownloaderList.global_position)+Vector2i(0, %DownloaderList.size.y),Vector2i(0, %DownloaderList.size.y))
		)
	else:
		%DownloaderListPopupMenu.hide()


func _on_download_stat_item_selected(index):
	update_task_list()

func global_stat_update_func(
	download_speed, upload_speed, num_active, num_waiting, num_stopped, adapter_plugin_name
):
	update_global_stat_ui()

var show_downloader_list = []

enum UpdateType{UPDATE,BEGIN,FINISH,ERROR}

func update_show_downloader_adapter():
	show_downloader_list = []
	for i in range(%DownloaderListPopupMenu.item_count):
		if i != 0:
			if %DownloaderListPopupMenu.is_item_checkable(i):
				if %DownloaderListPopupMenu.is_item_checked(i):
					show_downloader_list.append(%DownloaderListPopupMenu.get_item_text(i))


func update_global_stat_ui():
	var total_download_speed = 0
	var total_upload_speed = 0

	for adapter_plugin_name in show_downloader_list:
		var cur_plugin_node = await PluginManager.get_plugin_instance_by_script_name(
			adapter_plugin_name
		)
		total_download_speed += cur_plugin_node.download_speed
		total_upload_speed += cur_plugin_node.upload_speed

	%TotalUploadSpeed.text = FormatUtils.get_format_file_size(total_upload_speed)
	%TotalDownloadSpeed.text = FormatUtils.get_format_file_size(total_download_speed)


func download_handle_update_func(
	gid,
	status,
	completed_length,
	upload_length,
	download_speed,
	upload_speed,
	error_code,
	adapter_plugin_name
):
	await update_by_gid_and_plugin_name(gid, adapter_plugin_name)
	
func update_by_gid_and_plugin_name(gid,adapter_plugin_name):
	var cur_plugin_node = await get_plugin_node()
	var ret_gid = await cur_plugin_node.get_reverse_gid(adapter_plugin_name,gid)
	if ret_gid==null:
		return false
	var cur_node = %TaskNodeContainer.get_node_or_null(ret_gid)
	if cur_node:
		var cur_gid_info = await cur_plugin_node.get_gid_info(ret_gid)
		cur_node.update_ui(cur_gid_info, cur_plugin_node.task_map[ret_gid].target_plugin_name)


func _on_add_task_folder_button_pressed():
	%AddTaskFolderFileDialog.popup()
	pass  # Replace with function body.


func _on_add_task_folder_file_dialog_file_selected(path):
	%AddTaskURL.text = path
	pass  # Replace with function body.


func _on_add_task_store_dir_button_pressed():
	%AddTaskStoreDirFileDialog.popup()
	pass  # Replace with function body.


func _on_add_task_store_dir_file_dialog_dir_selected(dir):
	%AddTaskStoreDir.text = dir


func _on_cancel_add_task_panel_pressed():
	set_task_container_visible(true)


func _on_submit_add_task_pressed():
	set_task_container_visible(true)
	var options = {}
	var url_path = %AddTaskURL.text.strip_edges()
	var rename = %AddTaskRenameName.text.strip_edges()
	var split_num = %AddTaskSplitNum.value
	var store_dir = %AddTaskStoreDir.text.strip_edges()
	var header_str = %AddTaskHeader.text.strip_edges()
	if rename != "":
		options["out"] = rename
	if split_num > 0:
		options["split"] = int(split_num)
	if store_dir != "":
		options["dir"] = store_dir
	if header_str != "":
		options["header"] = "\n".join(header_str.split("\n", false))

	var cur_plugin_node = await get_plugin_node()
	var file_extension = url_path.get_extension().to_lower()
	if file_extension == "metalink":
		await cur_plugin_node.new_metalink_task(url_path, options)
		pass
	elif file_extension == "torrent":
		await cur_plugin_node.new_bt_task(url_path, options)
	else:
		await cur_plugin_node.new_task([url_path], options)
	await _on_refresh_button_pressed()

func set_task_container_visible(bvisible):
	%TaskContainer.visible = bvisible
	%AddTaskContainer.visible = not bvisible


func _on_add_button_pressed():
	set_task_container_visible(false)


func _on_refresh_button_pressed():
	var cur_plugin_node = await get_plugin_node()
	await cur_plugin_node.all_task_list()
	update_task_list()


func _on_close_button_pressed():
	for cur_node in %TaskNodeContainer.get_children():
		if cur_node.visible:
			cur_node._on_close_button_pressed()

func _on_delete_button_pressed():
	for cur_node in %TaskNodeContainer.get_children():
		if cur_node.visible:
			cur_node._on_delete_button_pressed()


func _on_start_button_pressed():
	for cur_node in %TaskNodeContainer.get_children():
		if cur_node.visible:
			cur_node._on_start_button_toggled(true)


func _on_pause_button_pressed():
	for cur_node in %TaskNodeContainer.get_children():
		if cur_node.visible:
			cur_node._on_start_button_toggled(false)
