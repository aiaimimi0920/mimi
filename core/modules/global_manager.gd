extends Node


var global_timer:Timer = Timer.new()
var global_run_time:int = 0

var last_log_text:String = ""
var last_errors:PackedStringArray = []

var loading_resources:Dictionary = {}

var user_path:String = OS.get_user_data_dir()
var globalize_user_path:String = ProjectSettings.globalize_path(user_path)

var main_name:String = "main" ## All configurations, caches, data, and file logs are stored in the user://main

var user_main_path = user_path.path_join(main_name)

var config_name:String = "config"
var config_path:String = user_main_path.path_join(config_name)+".json"
var globalize_config_path:String = ProjectSettings.globalize_path(config_path)


var data_name:String = "data"
var data_path:String = user_main_path.path_join(data_name)+".rdb"
var globalize_data_path:String = ProjectSettings.globalize_path(data_path)


var file_name:String = "file"
var file_path:String = user_main_path.path_join(file_name)
var globalize_file_path:String = ProjectSettings.globalize_path(file_path)

var conversation_name:String = "conversation"
var conversation_path:String = user_main_path.path_join(conversation_name)
var globalize_conversation_path:String = ProjectSettings.globalize_path(conversation_path)

var cache_name:String = "cache"
var cache_path:String = user_main_path.path_join(cache_name)+".rca"
var globalize_cache_path:String = ProjectSettings.globalize_path(cache_path)

var log_name:String = "log"
var log_path:String = user_main_path.path_join(log_name)+".log"
var globalize_log_path:String = ProjectSettings.globalize_path(log_path)


var init_main_path:Array = [
	config_path,
	data_path,
	file_path,
	conversation_path.path_join("active"),
	conversation_path.path_join("inactive"),
	cache_path,
	log_path,
]
func _init_dir()->void:
	for p in init_main_path:
		if p.get_extension() == "":
			if !DirAccess.dir_exists_absolute(p):
				DirAccess.make_dir_recursive_absolute(p)
		else:	
			if !DirAccess.dir_exists_absolute(p.get_base_dir()):
				DirAccess.make_dir_recursive_absolute(p.get_base_dir())
		FileAccess.open(p, FileAccess.WRITE)

func _ready()->void:
	global_timer.connect("timeout",_on_global_timer_timeout)
	add_child(global_timer)
	global_timer.start(1.0)
	_init_dir()


func _physics_process(_delta:float)->void:
	_check_load_status()
	check_error()

func _on_global_timer_timeout()->void:
	global_run_time += 1


func _check_load_status()->void:
	for path in loading_resources:
		if ResourceLoader.load_threaded_get_status(path) != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			var helper:ResourceLoadHelper = loading_resources[path]
			loading_resources.erase(path)
			helper.emit_signal("finished")


func check_error()->void:
	return 

func load_threaded(path:String,type_hint:String="",use_sub_threads:bool=false)->Resource:
	if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
		Logger.info("This resource was previously loaded and is now returning the loaded resource: "+path)
		return ResourceLoader.load_threaded_get(path)
	else:
		Logger.info("Requesting asynchronous loading of resources for the following path: "+path)
		var err:int = ResourceLoader.load_threaded_request(path,type_hint,use_sub_threads)
		if !err:
			var helper:ResourceLoadHelper = ResourceLoadHelper.new()
			loading_resources[path]=helper
			Logger.info("The asynchronous resource loading request was successful, and we are waiting for the resource loading at the following path to complete:"+path)
			await helper.finished
			if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED:
				Logger.info("Successfully asynchronously loaded resources for the following path:"+path)
				return ResourceLoader.load_threaded_get(path)
			else:
				Logger.error("An error occurred while asynchronously loading resources for the following path. Please check if the file path or status is correct:"+path)
				return null
		else:
			Logger.error("An error occurred while asynchronously loading resources for the following path. Please check if the file path or status is correct:"+path)
			return null

func _notification(what:int)->void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		await PluginManager.unload_plugins()
		await get_tree().create_timer(0.5).timeout
		if restarting:
			OS.create_instance([])
		get_tree().quit()
	elif what == NOTIFICATION_CRASH:
		PluginManager.unload_plugins()
		OS.create_instance([])
		get_tree().quit()

var restarting = false
func restart()->void:
	restarting = true
	Logger.info("begin restarting")
	notification(NOTIFICATION_WM_CLOSE_REQUEST)

class ResourceLoadHelper:
	extends RefCounted
	signal finished
