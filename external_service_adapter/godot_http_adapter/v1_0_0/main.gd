extends PluginAPI
var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

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
	## Note that this plugin is only a proxy for godot http_client, excluding advanced features such as disconnection and reconnection
	set_plugin_info(plugin_name,"godot_http_adapter","mimi",plugin_version,"Abstract the HTTP download function of Godot",
		"service",{"downloader_list":["v1_0_0"]})
	Logger.add_file_appender_by_name_path(PluginManager.get_plugin_log_path(plugin_name), plugin_name)
	var cur_new_conversation = ConversationManager.get_conversation_by_plugin_name(plugin_name, true)
	
func _ready()->void:
	service_http = load(get_absolute_path("modules/http.gd")).new()
	service_config_manager = load(get_absolute_path("modules/config_manager.gd")).new()
	start()
	pass

var service_http
var service_config_manager

func start()->void:
	service_config_manager.connect("config_loaded",_config_loaded)
	service_config_manager.name = "ConfigManager"
	service_http.name = "http"
	add_child(service_config_manager,true)
	add_child(service_http,true)
	service_http.connect("update_global_stat",global_stat_update_func)
	service_http.connect("update_download_handle",download_handle_update_func)
	
	service_http.connect("download_start",download_start_func)
	service_http.connect("download_pause",download_pause_func)
	service_http.connect("download_stop",download_stop_func)
	service_http.connect("download_complete",download_complete_func)
	service_http.connect("download_error",download_error_func)
	service_http.connect("bt_download_complete",bt_download_complete_func)
	
	service_config_manager.init_config()


func download_start_func(gid):
	call_deferred("emit_signal", "download_start", gid)

func download_pause_func(gid):
	call_deferred("emit_signal", "download_pause", gid)
	
func download_stop_func(gid):
	call_deferred("emit_signal", "download_stop", gid)

func download_complete_func(gid):
	call_deferred("emit_signal", "download_complete", gid)

func download_error_func(gid):
	call_deferred("emit_signal", "download_error", gid)

func bt_download_complete_func(gid):
	call_deferred("emit_signal", "bt_download_complete", gid)


func global_stat_update_func(download_speed,upload_speed,num_active,num_waiting,num_stopped):
	emit_signal("update_global_stat", download_speed,upload_speed,num_active,num_waiting,num_stopped)

func download_handle_update_func(gid, status,completed_length,upload_length,download_speed,upload_speed,error_code):
	emit_signal("update_download_handle", gid, status,completed_length,upload_length,download_speed,upload_speed,error_code)

func _config_loaded()->void:
	#await get_tree().process_frame
	service_config_manager.apply_all()
	var downloader_list = await PluginManager.get_plugin_instance_by_script_name("downloader_list")
	downloader_list.trigger_download_adapter(plugin_name,1)

func new_task(uris, options={}):
	return await service_http.new_task(uris, options)

func new_metalink_task(metalink_file_path, options={}):
	return await service_http.new_metalink_task(metalink_file_path, options)

func new_bt_task(bt_file_path, options={}):
	return await service_http.new_bt_task(bt_file_path, options)

func all_task_list():
	return await service_http.all_task_list()

func active_task_list():
	return await service_http.active_task_list()

func waiting_task_list():
	return await service_http.waiting_task_list()

func stopped_task_list():
	return await service_http.stopped_task_list()


func delete_task(gid, force=false, delete_file=false):
	return await service_http.delete_task(gid, force, delete_file)

func resume_task(gid):
	return await service_http.resume_task(gid)

func pause_task(gid, force=false):
	return await service_http.pause_task(gid, force)

func change_position(gid, pos, how=1):
	return await service_http.change_position(gid, pos, how)

func pause_all_tasks(force=false):
	return await service_http.pause_all_tasks(force)

func resume_all_tasks():
	return await service_http.resume_all_tasks()

func add_user_options(options={}):
	return await service_http.add_user_options(options)

func remove_user_options(options_keys=[]):
	return await service_http.remove_user_options(options_keys)

func get_gid(gid, auto_create=false):
	return await service_http.get_gid(gid, auto_create)
	
var download_speed:
	get:
		return service_http.download_speed

var upload_speed:
	get:
		return service_http.upload_speed
		
var num_active:
	get:
		return service_http.num_active
		
		
var num_waiting:
	get:
		return service_http.num_waiting
		
var num_stopped:
	get:
		return service_http.num_stopped
