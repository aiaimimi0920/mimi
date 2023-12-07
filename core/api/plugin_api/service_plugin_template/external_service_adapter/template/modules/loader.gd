extends Node

var _plugin_result = PluginManager.get_plugin_name(get_script())
var plugin_name = _plugin_result[0]
var plugin_version = _plugin_result[1]
var plugin_node = PluginManager.get_plugin(plugin_name, plugin_version)

var neek_kill_pids = []

signal service_started
signal service_ready
signal service_closed

enum TEST_MODE {
	TEST_SCRIPT = 0,
	TEST_EXE = 1,
}

var test_mode = TEST_MODE.TEST_EXE
var editor_pid = null

var working_directory:
	get:
		if OS.has_feature("editor"):
			return PluginManager.get_globalize_res_external_service_path(plugin_name,plugin_version)
		else:
			return PluginManager.get_globalize_external_service_dir_path(plugin_name,plugin_version)

var service_process_path:
	get:
		if OS.has_feature("editor"):
			if test_mode == TEST_MODE.TEST_SCRIPT:
				return "python"
			elif test_mode == TEST_MODE.TEST_EXE:
				return "main.exe"
		else:
			return "main.exe"


var service_process_arguments:
	get:
		var cur_arguments = []

		if OS.has_feature("editor") and test_mode == TEST_MODE.TEST_SCRIPT:
			cur_arguments = [working_directory.path_join("main.py")]
		
		cur_arguments.append_array(['-p','%s'%[plugin_node.service_config_manager.service_port],'-f', 
				'%s'%[plugin_node.service_config_manager.data_format],
				])

		var cur_http_proxy = plugin_node.service_config_manager.proxy_address_port
		var cur_https_proxy = plugin_node.service_config_manager.proxy_address_port

		if cur_http_proxy!="" and cur_http_proxy!=null:
			cur_arguments.append("--http=%s"%cur_http_proxy)

		if cur_https_proxy!="" and cur_https_proxy!=null:
			cur_arguments.append("--https=%s"%cur_https_proxy)
		return cur_arguments

var service_process:Process = null

func _process(delta: float) -> void:
	if is_instance_valid(service_process):
		var out_count:int = service_process.get_available_stdout_lines()
		var err_count:int = service_process.get_available_stderr_lines()
		## It seems that only standard error streams can output normally
		for i in out_count:
			var _line = service_process.get_stdout_line().replacen("\r","")
			Logger.info(_line)
			update_service_state(_line)
		for i in err_count:
			var _line = service_process.get_stderr_line().replacen("\r","")
			Logger.error(_line)
			update_service_state(_line)

		if service_process.get_exit_status() != -1:
			Logger.info("The current running %s process has exited with the following exit status:%s"%[plugin_name,service_process.get_exit_status()])
			service_process = null
			service_closed.emit()

## Detect versions of dependent programs
func check_dependent_program_version()->bool:
	return true

func load_service()->int:
	await kill_service()
	var format_data = {"plugin_name":plugin_name}
	Logger.info("Start executing the backend startup process for the {plugin_name} protocol".format(format_data))
	
	if check_dependent_program_version():
		Logger.info("Environment detection passed, generating internal configuration file for {plugin_name}".format(format_data))
		Logger.info("The internal configuration file for {plugin_name} has been generated! Starting {plugin_name} process".format(format_data))
		
		if OS.has_feature("editor") and test_mode == TEST_MODE.TEST_SCRIPT:
			var cur_args = ["/C", service_process_path]
			cur_args.append_array(service_process_arguments)
			## Note that you cannot detect the process status when running in this way, 
			## so you cannot obtain the corresponding printout (although you can try to obtain it by writing a file, ignore it for now)
			## So please manage the status yourself, such as ensuring that the port status does not change, 
			## such as adding a certain delay after startup to default readiness
			editor_pid = OS.create_process("CMD.exe", cur_args, true)
		else:
			service_process = Process.create(working_directory.path_join(service_process_path), service_process_arguments, working_directory)

		if OS.has_feature("editor") and test_mode == TEST_MODE.TEST_SCRIPT:
			if editor_pid==null:
				return ERR_CANT_CREATE
		else:
			if !is_instance_valid(service_process):
				return ERR_CANT_CREATE
		
		service_started.emit()
		Logger.info("The {plugin_name} process has started successfully and is waiting for a connection to be established with it".format(format_data))
		return OK
	else:
		return ERR_FILE_NOT_FOUND
		
		
func kill_service()->int:
	if is_running():
		for kill_id in neek_kill_pids:
			OS.kill(kill_id)
		if OS.has_feature("editor") and test_mode == TEST_MODE.TEST_SCRIPT:
			editor_pid = null
		else:
			service_process.kill(true)
		await service_closed
		return OK
	else:
		return ERR_DOES_NOT_EXIST
	
	
func is_running()->bool:
	if OS.has_feature("editor") and test_mode == TEST_MODE.TEST_SCRIPT:
		return editor_pid!=null
	else:
		return is_instance_valid(service_process) and service_process.get_exit_status() == -1


func update_service_state(line:String):
	var format_data = {"plugin_name":plugin_name,"ws_url":plugin_node.get_ws_url()}
	if line.begins_with("port is used, use new port "):
		var new_port = line.trim_prefix("port is used, use new port ").to_int()
		Logger.error("Unable to initialize the listening port for the {plugin_name} process: {ws_url}".format(format_data)+", Please use the new port %d"%new_port)
		plugin_node.service_config_manager.service_port = new_port
		pass
	elif line.begins_with("ai port use "):
		var new_port = line.trim_prefix("ai port use ").to_int()
		plugin_node.service_config_manager.service_ai_port = new_port
		format_data["ws_url"] = plugin_node.get_ai_url()
		Logger.error("Initialize the AI listening port for the {plugin_name} process: {ws_url}".format(format_data))
	elif line.begins_with("service_ready"):
		service_ready.emit()
	elif line.begins_with("need_kill_pid "):
		var neek_kill_pid = line.trim_prefix("need_kill_pid ").to_int()
		neek_kill_pids.append(neek_kill_pid)
