extends Window

@export var category_container_tscn:PackedScene

var last_config_mgr_node

func setup(config_mgr_node):
	last_config_mgr_node = config_mgr_node
	var priority_list = config_mgr_node.priority_list
	var all_cilldren = %TabContainer.get_children()
	for cur_node in all_cilldren:
		cur_node.queue_free()
	
	## Note that the actual configuration storage file may not necessarily store all the information
	var all_category = config_mgr_node.config_file.get_sections()
	var all_settings_tres = config_mgr_node.load_all_settings_tres()
	for cur_setting_tres in all_settings_tres.values():
		if cur_setting_tres.category not in all_category:
			all_category.append(cur_setting_tres.category)
	
	var cur_all_category = []
	var category_map = {}
	for cur_category in priority_list:
		cur_all_category.append(cur_category["category_name"])
		category_map[cur_category["category_name"]] = cur_category["category_priority_list"]
	
	var result_all_category = []
	for category_name in cur_all_category:
		if category_name in all_category:
			result_all_category.append(category_name)
			var category_name_index = all_category.find(category_name)
			if category_name_index!=-1:
				all_category.remove_at(category_name_index)
		else:
			pass
	all_category.sort()
	for category_name in all_category:
		result_all_category.append(category_name)
	
	for category_name in result_all_category:
		var all_group = []
		var group_map = {}
		var section_keys = PackedStringArray()
		if config_mgr_node.config_file.has_section(category_name):
			section_keys = config_mgr_node.config_file.get_section_keys(category_name)
		for cur_setting_tres in all_settings_tres.values():
			if cur_setting_tres.category == category_name:
				if cur_setting_tres.name not in section_keys:
					section_keys.append(cur_setting_tres.name)
		for section_key in section_keys:
			var split_section_keys = section_key.split("_",true,1)
			if len(split_section_keys)==1:
				all_group.append(split_section_keys[0])
				pass
			elif len(split_section_keys)==2:
				if split_section_keys[0] in group_map:
					group_map[split_section_keys[0]]["group_data"].append(split_section_keys[1])
				else:
					var cur_group_data = {"group_name":split_section_keys[0],"group_data":[split_section_keys[1]]}
					group_map[split_section_keys[0]] = cur_group_data
					all_group.append(cur_group_data)
		## all_group refers to all categories and elements within them, as well as elements that are not in the category
		var result_all_main_group = []
		var result_all_group = []
		for cur_group_data in all_group:
			if cur_group_data is String:
				result_all_main_group.append(cur_group_data)
				result_all_main_group.sort()
			elif cur_group_data is Dictionary:
				cur_group_data["group_data"].sort()
				result_all_group.append(cur_group_data)
		
		result_all_group.sort_custom(func(a, b): return a["group_name"] < b["group_name"])
		
		var result_all_group_data = []
		if category_name in category_map:
			## Description requires custom sorting
			var cur_category_priority_list = category_map[category_name]
			## First, it is necessary to set all the main to the front, even if the priority order passed in is mixed
			for cur_category_priority in cur_category_priority_list:
				if cur_category_priority is String:
					if cur_category_priority in result_all_main_group:
						result_all_group_data.append(cur_category_priority)
						result_all_main_group.erase(cur_category_priority)
					pass
				else:
					continue
			## Add all priorities to
			result_all_group_data.append_array(result_all_main_group)
			
			for cur_category_priority in cur_category_priority_list:
				if cur_category_priority is Dictionary:
					for cur_data in result_all_group:
						## Find the same group
						if cur_data.group_name == cur_category_priority.group_name:
							var cur_group_data = []
							for cur_group_name in  cur_category_priority["group_priority_list"]:
								if cur_group_name in cur_data.group_data:
									cur_group_data.append(cur_group_name)
									cur_data.group_data.erase(cur_group_name)
							
							cur_group_data.append_array(cur_data.group_data)
							
							cur_data.group_data = cur_group_data
							
							result_all_group_data.append(cur_data)
							result_all_group.erase(cur_data)
							break
			## Add all priorities to
			result_all_group_data.append_array(result_all_group)
		else:
			result_all_group_data.append_array(result_all_main_group)
			result_all_group_data.append_array(result_all_group)
	
		## result_all_group_data It is already the final sorted display sequence，Convert the data from string to ggsSetting format
		var last_result_all_group_data = []
		var have_ond_data = false
		for i in range(len(result_all_group_data)):
			if result_all_group_data[i] is String:
				if result_all_group_data[i] in all_settings_tres:
					if all_settings_tres[result_all_group_data[i]].show_visible:
						last_result_all_group_data.append(all_settings_tres[result_all_group_data[i]])
						have_ond_data = true
			elif result_all_group_data[i] is Dictionary:
				var cur_group_data = []
				for cur_group_name in result_all_group_data[i]["group_data"]:
					var cur_name = result_all_group_data[i]["group_name"]+"_"+cur_group_name
					if cur_name in all_settings_tres:
						if all_settings_tres[cur_name].show_visible:
							cur_group_data.append(all_settings_tres[cur_name])
				if cur_group_data.size()==0:
					pass
				else:
					result_all_group_data[i]["group_data"] = cur_group_data
					last_result_all_group_data.append(result_all_group_data[i])
					have_ond_data = true
				
		## last_result_all_group_data is the final list containing resources
		if have_ond_data == false:
			continue
		var cur_node = category_container_tscn.instantiate()
		%TabContainer.add_child(cur_node)
		cur_node.name = category_name
		cur_node.icw_node = %InputConfirmWindow
		cur_node.data = last_result_all_group_data


func _on_confirm_button_pressed():
	var all_cilldren = %TabContainer.get_children()
	for cur_node in all_cilldren:
		cur_node.apply_setting()
		
	last_config_mgr_node.reload_config_file()
	last_config_mgr_node.apply_all()



func _on_reset_button_pressed():
	if last_config_mgr_node:
		setup(last_config_mgr_node)
