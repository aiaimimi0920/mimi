extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

signal add_download_adapter
signal update_global_stat
signal update_download_handle

signal download_start
signal download_pause
signal download_stop
signal download_complete
signal download_error
signal bt_download_complete

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"downloader_list","mimi",plugin_version,"Collection of download methods, you can download content in multiple ways",
		"plugin", {})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)


var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	add_child(service_config_manager,true)
	service_config_manager.init_config()

func _config_loaded()->void:
	pass

func _ready()->void:
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	
var downloader_adapter_name_list = []
var downloader_adapter_name_map = {}

func sort_downloader_adapter(a, b):
	if downloader_adapter_name_map[a] < downloader_adapter_name_map[b]:
		return true
	if downloader_adapter_name_map[a] == downloader_adapter_name_map[b]:
		if a<b:
			return true
		return false
	return false

func trigger_download_adapter(adapter_plugin_name, target_index):
	downloader_adapter_name_map[adapter_plugin_name] = target_index
	downloader_adapter_name_list=downloader_adapter_name_map.keys()
	downloader_adapter_name_list.sort_custom(sort_downloader_adapter)
	task_reverse_map[adapter_plugin_name] = {}
	var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(adapter_plugin_name)
	download_plugin_adapter.connect("update_global_stat",global_stat_update_func.bind(adapter_plugin_name))
	download_plugin_adapter.connect("update_download_handle",download_handle_update_func.bind(adapter_plugin_name))
	
	download_plugin_adapter.connect("download_start",download_start_func.bind(adapter_plugin_name))
	download_plugin_adapter.connect("download_pause",download_pause_func.bind(adapter_plugin_name))
	download_plugin_adapter.connect("download_stop",download_stop_func.bind(adapter_plugin_name))
	download_plugin_adapter.connect("download_complete",download_complete_func.bind(adapter_plugin_name))
	download_plugin_adapter.connect("download_error",download_error_func.bind(adapter_plugin_name))
	download_plugin_adapter.connect("bt_download_complete",bt_download_complete_func.bind(adapter_plugin_name))

	emit_signal("add_download_adapter",adapter_plugin_name)

var user_preferred_downloader:
	get:
		return service_config_manager.preferred_downloader


func download_start_func(gid,adapter_plugin_name):
	emit_signal("download_start",gid,adapter_plugin_name)
	var cur_gid = await get_reverse_gid(adapter_plugin_name,gid)
	if has_user_signal(cur_gid+"_wait_task"):
		emit_signal(cur_gid+"_wait_task",1)

func download_pause_func(gid,adapter_plugin_name):
	emit_signal("download_pause",gid,adapter_plugin_name)
	var cur_gid = await get_reverse_gid(adapter_plugin_name,gid)
	if has_user_signal(cur_gid+"_wait_task"):
		emit_signal(cur_gid+"_wait_task",2)
	
func download_stop_func(gid,adapter_plugin_name):
	emit_signal("download_stop",gid,adapter_plugin_name)
	var cur_gid = await get_reverse_gid(adapter_plugin_name,gid)
	if has_user_signal(cur_gid+"_wait_task"):
		emit_signal(cur_gid+"_wait_task",3)
	
func download_complete_func(gid,adapter_plugin_name):
	emit_signal("download_complete", gid, adapter_plugin_name)
	var cur_gid = await get_reverse_gid(adapter_plugin_name,gid)
	if has_user_signal(cur_gid+"_wait_task"):
		emit_signal(cur_gid+"_wait_task",4)

func download_error_func(gid,adapter_plugin_name):
	emit_signal("download_error",gid,adapter_plugin_name)
	var cur_gid = await get_reverse_gid(adapter_plugin_name,gid)
	if has_user_signal(cur_gid+"_wait_task"):
		emit_signal(cur_gid+"_wait_task",5)

func bt_download_complete_func(gid,adapter_plugin_name):
	emit_signal("bt_download_complete",gid,adapter_plugin_name)
	var cur_gid = await get_reverse_gid(adapter_plugin_name,gid)
	if has_user_signal(cur_gid+"_wait_task"):
		emit_signal(cur_gid+"_wait_task",6)


func global_stat_update_func(download_speed,upload_speed,num_active,num_waiting,num_stopped,adapter_plugin_name):
	emit_signal("update_global_stat", download_speed,upload_speed,num_active,num_waiting,num_stopped,adapter_plugin_name)

func download_handle_update_func(gid, status,completed_length,upload_length,download_speed,upload_speed,error_code,adapter_plugin_name):
	emit_signal("update_download_handle", gid, status,completed_length,upload_length,download_speed,upload_speed,error_code,adapter_plugin_name)

func get_plugin_gid_info(gid, adapter_plugin_name):
	var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(adapter_plugin_name)
	return await download_plugin_adapter.get_gid(gid)

func get_gid_info(gid):
	var cur_gid = task_map[gid]
	var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(cur_gid.target_plugin_name)
	var ret_gid_info = await download_plugin_adapter.get_gid(cur_gid.target_gids[0])
	return ret_gid_info
	

func get_use_downloader_plugin_name(download_plugin_name, used_plugin_name):
	if download_plugin_name!="":
		return download_plugin_name
	var cur_user_preferred_downloader = user_preferred_downloader.split(",",false)
	if cur_user_preferred_downloader.size()!=0:
		for value in cur_user_preferred_downloader:
			if value not in used_plugin_name:
				return value
	for value in downloader_adapter_name_list:
		if value not in used_plugin_name:
			return value
	return ""
	

func get_use_downloader_plugin(download_plugin_name, used_plugin_name):
	download_plugin_name = get_use_downloader_plugin_name(download_plugin_name,used_plugin_name)
	if download_plugin_name=="":
		return null
	var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(download_plugin_name)
	return download_plugin_adapter
	
var task_map={}
var task_reverse_map={}

func get_new_gid_id():
	var cur_gid = ""
	var cur_timestamp = int(Time.get_unix_time_from_system()*100)
	cur_gid += ("%d"%cur_timestamp)
	var cur_random_number = randi_range(0,999)
	cur_gid += ("_"+"%d"%cur_random_number)
	if cur_gid not in task_map:
		return cur_gid
	return get_new_gid_id()

func add_gid(gids_ret,download_plugin_adapter):
	var cur_gid = Gid.new()
	cur_gid.gid_id = get_new_gid_id()
	cur_gid.target_gids = gids_ret
	cur_gid.target_plugin_name = download_plugin_adapter.plugin_name
	task_map[cur_gid.gid_id] = cur_gid
	for cur_adapter_gid in gids_ret:
		task_reverse_map[download_plugin_adapter.plugin_name][cur_adapter_gid] = cur_gid.gid_id
	return cur_gid.gid_id

func get_reverse_gid(cur_plugin_name, cur_adapter_gid, auto_create=true):
	var cur_id = task_reverse_map.get(cur_plugin_name,{}).get(cur_adapter_gid,null)
	if cur_id==null and auto_create:
		var download_plugin_adapter = await get_use_downloader_plugin(cur_plugin_name,[])
		if download_plugin_adapter == null:
			return null
		return add_gid([cur_adapter_gid],download_plugin_adapter)
	return cur_id

func wait_task(cur_id, target_type=0):
	if not has_user_signal(cur_id+"_wait_task"):
		add_user_signal(cur_id+"_wait_task")
	if target_type==0:
		var cur_type = await Signal(self,cur_id+"_wait_task")
		return cur_type
	else:
		while true:
			var cur_type = await Signal(self,cur_id+"_wait_task")
			if cur_type==target_type:
				return cur_type


func new_task(uris, options={}, download_plugin_name="", used_plugin_name=[]):
	var download_plugin_adapter = await get_use_downloader_plugin(download_plugin_name, used_plugin_name)
	if download_plugin_adapter==null:
		return false
	var cur_gids_ret = await download_plugin_adapter.new_task(uris, options)
	return add_gid(cur_gids_ret,download_plugin_adapter)


func new_metalink_task(metalink_file_path, options={}, download_plugin_name="", used_plugin_name=[]):
	var download_plugin_adapter = await get_use_downloader_plugin(download_plugin_name,used_plugin_name)
	if download_plugin_adapter==null:
		return false
	var cur_gids_ret = await download_plugin_adapter.new_metalink_task(metalink_file_path, options)
	return add_gid(cur_gids_ret,download_plugin_adapter)


func new_bt_task(bt_file_path, options={}, download_plugin_name="", used_plugin_name=[]):
	var download_plugin_adapter = await get_use_downloader_plugin(download_plugin_name,used_plugin_name)
	if download_plugin_adapter==null:
		return false
	var cur_gid_ret = await download_plugin_adapter.new_bt_task(bt_file_path, options)
	return add_gid([cur_gid_ret],download_plugin_adapter)

func all_task_list(download_plugin_name=""):
	var active_gids = []
	var cur_downloader_adapter_name_list = []
	if download_plugin_name=="":
		cur_downloader_adapter_name_list = downloader_adapter_name_list
	else:
		cur_downloader_adapter_name_list = [download_plugin_name]
	for target_plugin_name in cur_downloader_adapter_name_list:
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(target_plugin_name)
		var cur_active_task_list = await download_plugin_adapter.all_task_list()
		for active_gid in cur_active_task_list:
			var cur_gid = await get_reverse_gid(target_plugin_name, active_gid)
			active_gids.append(cur_gid)
	return active_gids

func active_task_list(download_plugin_name=""):
	var active_gids = []
	var cur_downloader_adapter_name_list = []
	if download_plugin_name=="":
		cur_downloader_adapter_name_list = downloader_adapter_name_list
	else:
		cur_downloader_adapter_name_list = [download_plugin_name]
	for target_plugin_name in cur_downloader_adapter_name_list:
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(target_plugin_name)
		var cur_active_task_list = await download_plugin_adapter.active_task_list()
		for active_gid in cur_active_task_list:
			var cur_gid = await get_reverse_gid(target_plugin_name, active_gid)
			active_gids.append(cur_gid)
	return active_gids

func waiting_task_list(download_plugin_name=""):
	var active_gids = []
	var cur_downloader_adapter_name_list = []
	if download_plugin_name=="":
		cur_downloader_adapter_name_list = downloader_adapter_name_list
	else:
		cur_downloader_adapter_name_list = [download_plugin_name]
	for target_plugin_name in cur_downloader_adapter_name_list:
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(target_plugin_name)
		var cur_active_task_list = await download_plugin_adapter.waiting_task_list()
		for active_gid in cur_active_task_list:
			var cur_gid = await get_reverse_gid(target_plugin_name, active_gid)
			active_gids.append(cur_gid)
	return active_gids

func stopped_task_list(download_plugin_name=""):
	var active_gids = []
	var cur_downloader_adapter_name_list = []
	if download_plugin_name=="":
		cur_downloader_adapter_name_list = downloader_adapter_name_list
	else:
		cur_downloader_adapter_name_list = [download_plugin_name]
	for target_plugin_name in cur_downloader_adapter_name_list:
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(target_plugin_name)
		var cur_active_task_list = await download_plugin_adapter.stopped_task_list()
		for active_gid in cur_active_task_list:
			var cur_gid = await get_reverse_gid(target_plugin_name, active_gid)
			active_gids.append(cur_gid)
	return active_gids

func delete_task(gid, force=false, delete_file=false):
	if gid in task_map:
		var cur_gid = task_map[gid]
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(cur_gid.target_plugin_name)
		for cur_gid_id in cur_gid.target_gids:
			await download_plugin_adapter.delete_task(cur_gid_id, force, delete_file)
	return true
	

func resume_task(gid):
	if gid in task_map:
		var cur_gid = task_map[gid]
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(cur_gid.target_plugin_name)
		for cur_gid_id in cur_gid.target_gids:
			await download_plugin_adapter.resume_task(cur_gid_id)
	return true


func pause_task(gid, force=false):
	if gid in task_map:
		var cur_gid = task_map[gid]
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(cur_gid.target_plugin_name)
		for cur_gid_id in cur_gid.target_gids:
			await download_plugin_adapter.pause_task(cur_gid_id, force)
	return true
	

func change_position(gid, pos, how=1):
	## TODO:
	return true

func pause_all_tasks(force=false, download_plugin_name=""):
	var cur_downloader_adapter_name_list = []
	if download_plugin_name=="":
		cur_downloader_adapter_name_list = downloader_adapter_name_list
	else:
		cur_downloader_adapter_name_list = [download_plugin_name]
	for target_plugin_name in cur_downloader_adapter_name_list:
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(target_plugin_name)
		await download_plugin_adapter.pause_all_tasks(force)
	return true
	

func resume_all_tasks(download_plugin_name=""):
	var cur_downloader_adapter_name_list = []
	if download_plugin_name=="":
		cur_downloader_adapter_name_list = downloader_adapter_name_list
	else:
		cur_downloader_adapter_name_list = [download_plugin_name]
	for target_plugin_name in cur_downloader_adapter_name_list:
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(target_plugin_name)
		await download_plugin_adapter.resume_all_tasks()
	return true

func add_user_options(options={}, download_plugin_name=""):
	var cur_downloader_adapter_name_list = []
	if download_plugin_name=="":
		cur_downloader_adapter_name_list = downloader_adapter_name_list
	else:
		cur_downloader_adapter_name_list = [download_plugin_name]
	for target_plugin_name in cur_downloader_adapter_name_list:
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(target_plugin_name)
		await download_plugin_adapter.add_user_options(options)
	return true


func remove_user_options(options_keys=[], download_plugin_name=""):
	var cur_downloader_adapter_name_list = []
	if download_plugin_name=="":
		cur_downloader_adapter_name_list = downloader_adapter_name_list
	else:
		cur_downloader_adapter_name_list = [download_plugin_name]
	for target_plugin_name in cur_downloader_adapter_name_list:
		var download_plugin_adapter = await PluginManager.get_plugin_instance_by_script_name(target_plugin_name)
		await download_plugin_adapter.remove_user_options(options_keys)
	return true

func get_ui_instance():
	var cur_node = load(get_absolute_path("ui/main.tscn")).instantiate()
	return cur_node

class Gid:
	var gid_id
	var target_gids
	var target_plugin_name
