extends PluginAPI

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

func _on_init()->void:
	super._on_init()
	set_plugin_info(plugin_name,"knowledge_library","mimi",plugin_version,
		"Provide knowledge base functionality","plugin",{"free_vector_adapter":["v1_0_0"]})
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

## Loading files
var now_load_files_path:
	get:
		return service_config_manager.load_files_path
	set(val):
		service_config_manager.load_files_path = val

## Matching included
var include_filter_map = {}
## Matching exclude
var exclude_filter_map = {}

func add_filter(include="",exclude="")->void:
	var include_array = include.split(",")
	var exclude_array = exclude.split(",")
	for key in include_array:
		if key!="":
			include_filter_map[key] = true
	
	for key in exclude_array:
		if key!="":
			exclude_filter_map[key] = true
	
	update_load_files()

	
func remove_filter(include="",exclude="")->void:
	var include_array = include.split(",")
	var exclude_array = exclude.split(",")
	for key in include_array:
		include_filter_map.erase(key)
	
	for key in exclude_array:
		exclude_filter_map.erase(key)
	
	update_load_files()

func set_filter(include="",exclude="")->void:
	include_filter_map = {}
	exclude_filter_map = {}
	add_filter(include, exclude)

func update_load_files()->void:
	## Generate a new file list based on matching
	var new_load_files_path = []
	for one_include_filter in include_filter_map.keys():
		new_load_files_path.append_array(FileManager.scan(one_include_filter))

	for one_exclude_filter in exclude_filter_map.keys():
		var result_cur_result_regex = ""
		var j = 0
		while true:
			if j>len(one_exclude_filter)-1:
				break
			if one_exclude_filter[j] == r"\\":
				result_cur_result_regex = result_cur_result_regex + "\\\\"
			else:
				result_cur_result_regex = result_cur_result_regex + one_exclude_filter[j]
				
			j += 1
		var regex = RegEx.new()
		regex.compile(result_cur_result_regex)
		var cur_new_load_files_path = []
		for file_path in new_load_files_path:
			var result = regex.search(file_path)
			if result:
				pass
			else:
				cur_new_load_files_path.append(file_path)
		new_load_files_path = cur_new_load_files_path
		
	var unload_files_path = []
	var load_files_path = []
	for file_path in now_load_files_path:
		if file_path in new_load_files_path:
			continue
		else:
			unload_files_path.append(file_path)

	for file_path in new_load_files_path:
		if file_path in now_load_files_path:
			continue
		else:
			load_files_path.append(file_path)

	now_load_files_path = new_load_files_path
	service_config_manager.include_filter = ",".join(include_filter_map.keys())
	service_config_manager.exclude_filter = ",".join(exclude_filter_map.keys())
	
	var free_vector_adapter = await PluginManager.get_plugin_instance_by_script_name("free_vector_adapter")
	if len(unload_files_path)>0:
		await free_vector_adapter.unload_files(unload_files_path,"static",true,"main")
	if len(load_files_path)>0:
		await free_vector_adapter.load_files(load_files_path,"static",true,"main")

