extends PanelContainer

var plugin_node = null
func get_plugin_node():
	if plugin_node and is_instance_valid(plugin_node):
		return plugin_node
	var _plugin_result = PluginManager.get_plugin_name(get_script())
	plugin_node = await PluginManager.get_plugin_instance_by_script_name(_plugin_result[0])
	return plugin_node

var gid_node
var adapter_plugin_name

enum UpdateType{UPDATE,BEGIN,FINISH,ERROR}

func update_ui(cur_gid_node,cur_adapter_plugin_name):
	gid_node = cur_gid_node
	adapter_plugin_name = cur_adapter_plugin_name
	var dir_path = gid_node.dir.simplify_path()
	var file_path
	if gid_node.files.size()>0:
		file_path = gid_node.files[0]["path"].simplify_path()
	else:
		file_path = ""
	var task_name 
	if file_path!="":
		task_name = file_path.trim_prefix(dir_path).split("/",false)[0]
	else:
		if gid_node.files.size()>0:
			task_name = gid_node.files[0]["waiting_uris"][0].split("/",false)[-1]
		else:
			task_name = "unknown"
	%FileName.text = task_name
	
	var total_length = gid_node.total_length
	var completed_length = gid_node.completed_length
	var gid_node_status = gid_node.status
	var download_speed = gid_node.download_speed
	var upload_speed = gid_node.upload_speed
	if gid_node.last_event_type == 4:
		completed_length = total_length
		gid_node_status = 3
		download_speed = 0

	
	%DownloadSize.text = FormatUtils.get_format_file_size(completed_length)+" / " +FormatUtils.get_format_file_size(total_length)
	if total_length<=0:
		#total_length = completed_length*2
		%ProgressBar.value = 0
	else:
		%ProgressBar.value = completed_length*1.0/total_length*100
	
	%UploadSpeed.text = FormatUtils.get_format_file_size(upload_speed)
	%DownloadSpeed.text = FormatUtils.get_format_file_size(download_speed)
	
	if download_speed<=0:
		download_speed = 1000
	
	if total_length<=0:
		%LeftTime.text = "unknown"
	else:
		if total_length<completed_length:
			total_length = completed_length
		%LeftTime.text = FormatUtils.get_format_time((total_length-completed_length)/download_speed)
	
	%NodeNum.text = "%d"%gid_node.connections
		
	match gid_node_status:
		0,1:
			if gid_node.last_event_type == 2:
				set_start_button_type(1)
			else:
				set_start_button_type(0)
		2:
			set_start_button_type(1)
		3, 4, 5:
			set_start_button_type(2)

func set_start_button_type(cur_type):
	if cur_type == 0:
		%StartButton.visible = true
		%StartButton.set_pressed_no_signal(true)
	elif cur_type == 1:
		%StartButton.visible = true
		%StartButton.set_pressed_no_signal(false)
	elif cur_type == 2:
		%StartButton.visible = false
		#%StartButton.set_pressed_no_signal(false)

func _on_close_button_pressed():
	var cur_plugin_node = await get_plugin_node()	
	var ret_gid = await cur_plugin_node.get_reverse_gid( adapter_plugin_name,gid_node.gid)
	if ret_gid==null:
		return false
	await cur_plugin_node.delete_task(ret_gid, false, false)


func _on_delete_button_pressed():
	var cur_plugin_node = await get_plugin_node()	
	var ret_gid = await cur_plugin_node.get_reverse_gid(adapter_plugin_name,gid_node.gid)
	if ret_gid==null:
		return false
	await cur_plugin_node.delete_task(ret_gid, false, true)


func _on_folder_button_pressed():
	OS.shell_show_in_file_manager(gid_node.dir.simplify_path())


func _on_link_button_pressed():
	var uri = gid_node.files[0]["used_uris"][0]
	DisplayServer.clipboard_set(uri)
	return true


func _on_start_button_toggled(toggled_on):
	if toggled_on:
		var cur_plugin_node = await get_plugin_node()
		var ret_gid = await cur_plugin_node.get_reverse_gid(adapter_plugin_name,gid_node.gid)
		if ret_gid==null:
			return false
		await cur_plugin_node.resume_task(ret_gid)
	else:
		var cur_plugin_node = await get_plugin_node()
		var ret_gid = await cur_plugin_node.get_reverse_gid( adapter_plugin_name,gid_node.gid)
		if ret_gid == null:
			return false
		await cur_plugin_node.pause_task(ret_gid)
