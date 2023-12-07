extends Node

func get_absolute_path(file):
	return get_script().resource_path.get_base_dir().path_join(file)
	
	
var metadata = load(get_absolute_path("metadata.gd")).new()

var base_url = "https://download.aiaimimi.com"
var store_pck_dir_path = "user://pck"
var temp_store_pck_dir_path = "user://pck_temp"
var executable_path_dir_path = OS.get_executable_path().get_base_dir()
var temp_executable_path_dir_path = OS.get_executable_path().get_base_dir()+"_temp"
var bat_path = OS.get_executable_path().get_base_dir().path_join("update.bat")

func get_version_path(version):
	var url_path = ""
	if version==-1:
		url_path = base_url.path_join("last")
	else:
		url_path = base_url.path_join(String(version))
	return url_path

func get_version_metadata(version):
	var url = get_version_path(version).path_join("metadata.json")
	var result:HttpRequestResult = await HttpRequestManager.send_http_get_request(url,[],600)
	var dic:Dictionary = result.get_as_dic()
	return dic


func check_engine_md5(last_metadata, need_update_path):
	var file_path = OS.get_executable_path()
	if last_metadata["engine_info"]["md5"] == FileAccess.get_md5(file_path):
		## engine MD5 matching
		pass
	else:
		need_update_path[last_metadata["engine_info"]["path"]] = {
			"store_dir_path":executable_path_dir_path,
			"temp_store_dir_path":temp_executable_path_dir_path,
			"md5":last_metadata["engine_info"]["md5"],
			"type":"engine_file",
		}

func check_full_extra_files_md5(last_metadata, need_update_path):
	for cur_file_path_info in last_metadata["full_extra_files_info"]:
		var _unique_path = cur_file_path_info["path"].trim_prefix(base_url+"/")
		## Get the file name after the number
		_unique_path = _unique_path.split("/",true,1)[1]
		var file_path = executable_path_dir_path.path_join(_unique_path)
		var temp_file_path = temp_executable_path_dir_path.path_join(_unique_path)
		
		if cur_file_path_info["md5"] == FileAccess.get_md5(file_path):
			## MD5 matching
			pass
		else:
			need_update_path[cur_file_path_info["path"]] = {
				"store_dir_path":executable_path_dir_path,
				"temp_store_dir_path":temp_executable_path_dir_path,
				"md5":cur_file_path_info["md5"],
				"type":"extra_file",
			}

func check_pck_md5(last_metadata, need_update_path):
	## Determine the current version and check if all sub patch files are correct
	## Detect the full package of the main
	var _unique_path = last_metadata["full_pck_info"][str(metadata.version)]["path"].trim_prefix(base_url+"/")
	## Get the file name after the number
	_unique_path = _unique_path.split("/",true,1)[1]
	
	if last_metadata["full_pck_info"][str(metadata.version)]["md5"] == FileAccess.get_md5(executable_path_dir_path.path_join(_unique_path)):
		## Indicates that the MD5 of the main full package is the same
		pass
	else:
		need_update_path[last_metadata["full_pck_info"][str(metadata.version)]["path"]] = {
				"store_dir_path":executable_path_dir_path,
				"temp_store_dir_path":temp_executable_path_dir_path,
				"md5":last_metadata["full_pck_info"][str(metadata.version)]["md5"],
				"type":"main_pck",
			}
	
	## Detect sub packages from the main package to the current version
	for cur_version in range(metadata.version+1, last_metadata["version"]+1):
		if str(cur_version) in last_metadata["patch_info"]:
			_unique_path = last_metadata["patch_info"][str(cur_version)]["path"].trim_prefix(base_url+"/")
			## Get the file name after the number
			_unique_path = _unique_path.split("/",true,1)[1]
			if last_metadata["patch_info"][str(cur_version)]["md5"] == FileAccess.get_md5(store_pck_dir_path.path_join(_unique_path)):
				pass
			else:
				need_update_path[last_metadata["patch_info"][str(cur_version)]["path"]] = {
					"store_dir_path":store_pck_dir_path,
					"temp_store_dir_path":temp_store_pck_dir_path,
					"md5":last_metadata["patch_info"][str(cur_version)]["md5"],
					"type":"sub_pck",
				}

func check_update():
	var last_metadata = await get_version_metadata(-1)
	var need_update_path = {}
	check_engine_md5(last_metadata,need_update_path)
	check_full_extra_files_md5(last_metadata,need_update_path)
	check_pck_md5(last_metadata,need_update_path)
	if need_update_path.size()==0:
		FileManager.remove_file(bat_path)
		FileManager.remove_directory_recursively(temp_store_pck_dir_path)
		FileManager.remove_directory_recursively(temp_executable_path_dir_path)
		## If there are no files that need to be updated, then load the PCK file
		for cur_version in range(metadata.version+1, last_metadata["version"]+1):
			if str(cur_version) not in last_metadata["patch_info"]:
				continue
			var _unique_path = last_metadata["patch_info"][str(cur_version)]["path"].trim_prefix(base_url+"/")
			## Get the file name after the number
			_unique_path = _unique_path.split("/",true,1)[1]
			var sub_pck_file_path = store_pck_dir_path.path_join(_unique_path)
			ProjectSettings.load_resource_pack(sub_pck_file_path)
		return true
	
	if last_metadata["version"] - metadata.version>10:
		## If the version difference is greater than 10, download the full package
		for key in need_update_path.keys():
			if need_update_path[key]["type"] in ["sub_pck","main_pck"]:
				need_update_path.erase(key)
		
		need_update_path[last_metadata["full_pck_info"][str(last_metadata["version"])]["path"]] = {
				"store_dir_path":executable_path_dir_path,
				"temp_store_dir_path":temp_executable_path_dir_path,
				"md5":last_metadata["full_pck_info"][str(last_metadata["version"])]["md5"],
				"type":"main_pck",
			}
	else:
		pass
	
	FileManager.remove_directory_recursively(temp_store_pck_dir_path)
	var ok_times = 0
	var error_times = 0
	for key in need_update_path:
		var result = await download_file(key, need_update_path[key]["md5"],
			need_update_path[key]["store_dir_path"], need_update_path[key]["temp_store_dir_path"])
		if result!=OK:
			error_times+=1
		else:
			ok_times+=1

	create_bat_file()
	var pid = OS.create_process(bat_path, [])
	get_tree().quit()


func create_bat_file():
	FileManager.remove_file(bat_path)
	var file = FileAccess.open(bat_path,FileAccess.WRITE_READ)
	## Wait for 2 seconds first to prevent the engine from not shutting down
	file.store_line("timeout /t 2")
	## Copy all contents in the folder
	file.store_line("xcopy /s /e /y \"{temp_store_pck_dir_path}\" \"{store_pck_dir_path}\"".format(
		{
			"temp_store_pck_dir_path":ProjectSettings.globalize_path(temp_store_pck_dir_path),
			"store_pck_dir_path":ProjectSettings.globalize_path(store_pck_dir_path),
		}))
	file.store_line("xcopy /s /e /y \"{temp_executable_path_dir_path}\" \"{executable_path_dir_path}\"".format(
		{
			"temp_executable_path_dir_path":ProjectSettings.globalize_path(temp_executable_path_dir_path),
			"executable_path_dir_path":ProjectSettings.globalize_path(executable_path_dir_path),
		}))
	var godot_run_string_array =[OS.get_executable_path()]

	for argument in OS.get_cmdline_args():
		godot_run_string_array.append(argument)
	
	var user_args = OS.get_cmdline_user_args()
	if len(user_args)>0:
		godot_run_string_array.append("++")
		for argument in user_args:
			godot_run_string_array.append(argument)
	
	var godot_run_string = " ".join(godot_run_string_array)
	## Recall the startup command to start the engine
	file.store_line(godot_run_string)

func download_file(url_path,md5,base_dir,base_temp_dir):
	var _unique_path = url_path.trim_prefix(base_url+"/")
	## Get the file name after the number
	_unique_path = _unique_path.split("/",true,1)[1]
	var file_path = base_dir.path_join(_unique_path)
	var temp_file_path = base_temp_dir.path_join(_unique_path)
	if !DirAccess.dir_exists_absolute(base_dir):
		DirAccess.make_dir_recursive_absolute(base_dir)
	if !DirAccess.dir_exists_absolute(base_temp_dir):
		DirAccess.make_dir_recursive_absolute(base_temp_dir)

	var base_md5 = FileAccess.get_md5(file_path)
	if base_md5 != "":
		if base_md5 == md5:
			return OK
		else:
			## Download new file
			pass
	var result:HttpRequestResult = await HttpRequestManager.send_http_get_request(url_path,[],600)
	var err:int = result.save_to_file(temp_file_path)
	var download_md5:String = FileAccess.get_md5(temp_file_path)
	if !err and md5 == download_md5:
		return OK
	return ERR_INVALID_DATA
