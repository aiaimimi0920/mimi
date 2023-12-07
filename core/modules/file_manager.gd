extends Node


static func copy_directory_recursively(p_from : String, p_to : String, remove_all_to: bool=true) -> void:
	## Delete all files in the target folder first
	if remove_all_to:
		remove_directory_recursively(p_to)


	var directory = DirAccess.open(p_from)
	if not directory.dir_exists(p_to):
		directory.make_dir_recursive(p_to)
		
	if directory:
		directory.list_dir_begin()
		var file_name = directory.get_next()
		while file_name != "":
			if directory.current_is_dir():
				copy_directory_recursively(p_from + "/" + file_name, p_to + "/" + file_name)
			else:
				if file_name.get_extension() != "import":
					directory.copy(p_from + "/" + file_name, p_to + "/" + file_name)
				
			file_name = directory.get_next()
	else:
		print("An error occurred while attempting to access the path.")


static func remove_directory_recursively(p_dir : String) -> void:
	var directory = DirAccess.open(p_dir)
	if directory:
		var all_files = directory.get_files()
		for file in all_files:
			directory.remove(file)
			
		var all_directories = directory.get_directories()
		for dir in all_directories:
			remove_directory_recursively(p_dir.path_join(dir))
		DirAccess.remove_absolute(p_dir)

static func remove_file(p_file : String) -> void:
	var directory = DirAccess.open(p_file.get_base_dir())
	if directory:
		directory.remove(p_file)

static func scan(path:String, need_dir=false, convert_path=false) -> Array:
	var files := []

	var base_path_array = []
	var base_regex_path = ""
	if path.begins_with("res://"):
		path.trim_prefix("res://")
		base_path_array.append("res:/")
		base_regex_path = path
	elif path.begins_with("user://"):
		path.trim_prefix("user://")
		base_path_array.append("user:/")
		base_regex_path = path
	else:
		var cur_path_array = path.split("/",true,1)
		base_path_array.append(cur_path_array[0]+"")
		base_regex_path = cur_path_array[1]
	
	var base_regex_path_array = base_regex_path.split("/")
	var file_or_dir_path = ""
	var result_regex_array = []
	for i in range(len(base_regex_path_array)):
		var cur_base_regex_path = base_regex_path_array[i]
		file_or_dir_path = "/".join(base_path_array)
		if DirAccess.dir_exists_absolute(file_or_dir_path.path_join(cur_base_regex_path)) or FileAccess.file_exists(file_or_dir_path.path_join(cur_base_regex_path)):
			base_path_array.append(cur_base_regex_path)
		else:
			result_regex_array = base_regex_path_array.slice(i)
			break
	
	path = "/".join(base_path_array)
	
	var result_regex_path_array = []
	for i in range(len(result_regex_array)):
		var cur_result_regex = result_regex_array[i]
		var result_cur_result_regex = ""
		var j = 0
		while true:
			if j>len(cur_result_regex)-1:
				break
			if cur_result_regex[j] == r"\\":
				result_cur_result_regex = result_cur_result_regex + "\\\\"
			else:
				result_cur_result_regex = result_cur_result_regex + cur_result_regex[j]
				
			j += 1
		result_regex_path_array.append(result_cur_result_regex)
	
	var regex_path = path.path_join("/".join(result_regex_path_array))

	
	var directory = DirAccess.open(path)
	if directory:
		var all_files = directory.get_files()
		for file in all_files:
			var cur_path := path.path_join(file).simplify_path()
			files.push_back(cur_path)
		
		var all_directories = directory.get_directories()
		for dir in all_directories:
			var cur_path := path.path_join(dir).simplify_path()
			files += scan(cur_path,need_dir)

	if need_dir:
		files.push_back(path)
	

	var regex = RegEx.new()
	regex.compile(regex_path)

	var regex_result_files = []
	for file_path in files:
		var result = regex.search(file_path)
		if result:
			regex_result_files.append(file_path)

	files = regex_result_files
	
	if convert_path:
		var result_files = []
		for file_path in files:
			if file_path.begins_with("res://"):
				file_path.trim_prefix("res://")
				if OS.has_feature("editor"):
					file_path = ProjectSettings.globalize_path("res://").path_join(file_path)
					result_files.append(file_path)
			elif file_path.begins_with("user://"):
				file_path.trim_prefix("user://")
				file_path = ProjectSettings.globalize_path("user://").path_join(file_path)
				result_files.append(file_path)
			else:
				result_files.append(file_path)
		files = result_files
	return files

