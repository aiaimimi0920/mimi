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
	path_history = []
	path_history_index = 0
	await init_res()
	await init_ui()
	await init_signal()
	update_panel_visible()

var ok_texture = null
var fail_texture = null

func init_res():
	var cur_plugin_node = await get_plugin_node()
	ok_texture = load(cur_plugin_node.get_absolute_path("ui/assets/Check.svg"))
	fail_texture = load(cur_plugin_node.get_absolute_path("ui/assets/Fail.svg"))

func init_signal():
	var cur_plugin_node = await get_plugin_node()
	cur_plugin_node.connect("init_tree_ui",self.init_tree)
	

func init_ui():
	init_base_ui()
	pass

func init_base_ui():
	init_tree()
	pass

var search_list = []

func _on_search_config_update_search_config():
	update_search_config_option_list()

func update_search_config_option_list():
	var popup = %Option.get_popup()
	popup.clear()
	search_list = []
	var id = 0
	var cur_search_configs = await %SearchConfig.get_search_configs()
	for key in cur_search_configs.keys():
		var view_info = cur_search_configs[key]
		popup.add_item(view_info.name, id)
		if view_info.icon != "":
			popup.set_item_icon(id, load(view_info.icon))
		id += 1
		search_list.append(key)


func update_search_config_option_ui():
	var cur_search_config_info_key = search_list[%Option.get_selected_id()]
	var cur_search_configs = await %SearchConfig.get_search_configs()
	var cur_search_config_info = cur_search_configs[cur_search_config_info_key]
	%ApplyInclude.button_pressed = cur_search_config_info["apply_include"]
	%ApplyExclude.button_pressed = cur_search_config_info["apply_exclude"]


func _on_option_item_selected(index):
	update_search_config_option_ui()
	update_tree_ui_flag = true
	#update_tree()
	

func _on_apply_include_toggled(toggled_on):
	if toggled_on:
		%ApplyInclude.modulate = Color.CYAN
	else:
		%ApplyInclude.modulate = Color.WHITE
	
	update_tree_ui_flag = true
	#update_tree()


func _on_apply_exclude_toggled(toggled_on):
	if toggled_on:
		%ApplyExclude.modulate = Color.CYAN
	else:
		%ApplyExclude.modulate = Color.WHITE
	
	update_tree_ui_flag = true
	#update_tree()


func _on_hide_empty_toggled(toggled_on):
	if toggled_on:
		%HideEmpty.modulate = Color.CYAN
	else:
		%HideEmpty.modulate = Color.WHITE
	
	update_tree_ui_flag = true
	#update_tree()

func init_tree():
	var cur_plugin_node = await get_plugin_node()
	path_map_node_ui = {
		1:{},
		2:{},
		3:{},
	}
	
	for i in range(1,4):
		var tree_node = get_main_tree_node(i)
		tree_node.clear()
		tree_node.hide_folding = false
		tree_node.hide_root = true
		
		var cur_root = await get_main_tree_root_node(i)
		if i==1:
			create_node(tree_node, cur_root, cur_plugin_node.root_node, false, i)
		else:
			create_node(tree_node, cur_root, cur_plugin_node.root_node, true, i)
	
	update_tree_ui_flag = true



var path_map_node_ui = {
	1:{},
	2:{},
	3:{},
}

func create_node(tree_node, cur_node, cur_node_data, hide_file_node=false, show_type = 1):
	match cur_node_data.get_type_name():
		"FileMergeNode":
			for uid in cur_node_data.merge_file_node:
				var cur_file_node = cur_node_data.merge_file_node[uid]
				if cur_file_node.file_path not in path_map_node_ui[show_type]:
					path_map_node_ui[show_type][cur_file_node.file_path]={}
				
				var child1 = tree_node.create_item(cur_node)
				child1.set_text(0, cur_file_node.file_name)
				#child1.set_icon(0, cur_node_data.dir_name)
				child1.set_metadata(0, cur_file_node)
				child1.set_expand_right(0, true)
				
				if FileAccess.file_exists(cur_file_node.save_path):
					child1.set_icon(1, ok_texture)
					child1.set_metadata(1, true)
				else:
					child1.set_icon(1, fail_texture)
					child1.set_metadata(1, false)
					
				if hide_file_node:
					child1.visible = false
				path_map_node_ui[show_type][cur_file_node.file_path][cur_file_node] = child1
				
		"FileNode":
			pass
		"DirMergeNode":
			var child1
			if cur_node_data.parent_node == null:
				# not create root node
				child1 = cur_node
			else:
				if cur_node_data.dir_path not in path_map_node_ui[show_type]:
					path_map_node_ui[show_type][cur_node_data.dir_path]={}
				
				child1 = tree_node.create_item(cur_node)
				child1.set_text(0, cur_node_data.dir_name)
				#child1.set_icon(0, cur_node_data.dir_name)
				child1.set_metadata(0, cur_node_data)
				child1.set_expand_right(0, true)
				
				#if DirAccess.dir_exists_absolute(cur_node_data.save_path):
					#child1.set_icon(1, ok_texture)
				#else:
					#child1.set_icon(1, fail_texture)
				
				path_map_node_ui[show_type][cur_node_data.dir_path][cur_node_data] = child1
			
			for uid in cur_node_data.dirs:
				var cur_dir_node = cur_node_data.dirs[uid]
				create_node(tree_node, child1, cur_dir_node, hide_file_node, show_type)
			
			for uid in cur_node_data.files:
				var cur_file_node = cur_node_data.files[uid]
				create_node(tree_node, child1, cur_file_node, hide_file_node, show_type)
		"DirNode":
			pass
	

func update_tree(_arg1=null,_arg2=null):
	cache_collapsed()
	var selected_id = %Option.get_selected_id()
	var include_array = []
	var exclude_array = []
	var hide_empty = %HideEmpty.button_pressed
	if selected_id!=-1:
		var cur_search_config_info_key = search_list[%Option.get_selected_id()]
		var cur_search_configs = await %SearchConfig.get_search_configs()
		var cur_search_config_info = cur_search_configs[cur_search_config_info_key]
	
		var include = ""
		var exclude = ""
		
		
		if %ApplyInclude.button_pressed:
			include = cur_search_config_info["include"]
			pass
		
		if %ApplyExclude.button_pressed:
			exclude = cur_search_config_info["exclude"]
	
		include_array = include.split(",",false)
		exclude_array = exclude.split(",",false)
	
	var cur_root = await get_main_tree_root_node()
	
	if now_show_panel_split_type == 1:
		var cur_include = %LineEdit1.text
		if cur_include!="":
			include_array.append(cur_include)
		
		pass
	elif now_show_panel_split_type == 2:
		var cur_include = %LineEdit2.text
		if cur_include!="":
			include_array.append(cur_root.get_metadata(0).dir_path.path_join(cur_include))
	elif now_show_panel_split_type == 3:
		var cur_include = %LineEdit3.text
		if cur_include!="":
			include_array.append(cur_root.get_metadata(0).dir_path.path_join(cur_include))
	
	
	var all_path = path_map_node_ui[now_show_panel_split_type].keys()

	if include_array.size()==0:
		pass
	else:
		var new_all_path = []
		for one_include_filter in include_array:
			var result_cur_result_regex = ""
			var j = 0
			while true:
				if j>len(one_include_filter)-1:
					break
				if one_include_filter[j] == r"\\":
					result_cur_result_regex = result_cur_result_regex + "\\\\"
				else:
					result_cur_result_regex = result_cur_result_regex + one_include_filter[j]
					
				j += 1
			var regex = RegEx.new()
			regex.compile(result_cur_result_regex)
			var cur_new_load_files_path = []
			
			for file_path in all_path:
				var result = regex.search(file_path)
				if result:
					new_all_path.append(file_path)
		var cur_dict = {}
		for key in new_all_path:
			cur_dict[key] = true
		
		all_path = cur_dict.keys()

	if exclude_array.size()==0:
		pass
	else:
		var new_all_path = []
		for one_exclude_filter in exclude_array:
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
			
			for file_path in all_path:
				var result = regex.search(file_path)
				if result:
					pass
				else:
					new_all_path.append(file_path)
		var cur_dict = {}
		for key in new_all_path:
			cur_dict[key] = true
		
		all_path = cur_dict.keys()

	var ret_all_path = {}
	for cur_path in all_path:

		if cur_path=="":
			continue
		ret_all_path[cur_path] = true
		var cur_dir_path = cur_path.get_base_dir()
		while cur_dir_path!="" and cur_dir_path!="/":
			ret_all_path[cur_dir_path] = true
			cur_dir_path = cur_dir_path.get_base_dir()
	
	all_path = ret_all_path.keys()
	
	for file_path in path_map_node_ui[now_show_panel_split_type]:
		var need_show = (file_path in all_path)
		for cur_file_node in path_map_node_ui[now_show_panel_split_type][file_path]:
			path_map_node_ui[now_show_panel_split_type][file_path][cur_file_node].set_meta("need_show",need_show) 
			path_map_node_ui[now_show_panel_split_type][file_path][cur_file_node].visible = need_show
			if hide_empty:
				if cur_file_node.get_type_name() == "DirMergeNode":
					if cur_file_node.files.is_empty() and cur_file_node.dirs.is_empty():
						path_map_node_ui[now_show_panel_split_type][file_path][cur_file_node].set_meta("need_show",false) 
						path_map_node_ui[now_show_panel_split_type][file_path][cur_file_node].visible = false
						
			if now_show_panel_split_type != 1:
				if cur_file_node.get_type_name() == "FileNode":
					path_map_node_ui[now_show_panel_split_type][file_path][cur_file_node].visible = false
	
	var all_dir_node = {}
	for key in path_map_node_ui[now_show_panel_split_type]:
		var cur_map_data = path_map_node_ui[now_show_panel_split_type][key]
		for cur_node_data in cur_map_data:
			var cur_node_item = cur_map_data[cur_node_data]
			if all_dir_node.get(cur_node_item,true)==false:
				continue
				
			if cur_node_data.get_type_name() ==  "FileNode":
				if cur_node_item.get_metadata(1) == false:
					var cur_parent = cur_node_item.get_parent()
					while cur_parent!=null and not (cur_parent is Tree):
						all_dir_node[cur_parent] = false
						cur_parent = cur_parent.get_parent()
			else:
				if cur_node_item not in all_dir_node:
					all_dir_node[cur_node_item] = true
	
	for key in all_dir_node:
		if all_dir_node[key]:
			key.set_icon(1, ok_texture)
			key.set_metadata(1, true)
		else:
			key.set_icon(1, fail_texture)
			key.set_metadata(1, false)

	if %MainPath.text == "":
		var tree_node = get_main_tree_node()
		tree_node.set_selected(cur_root,0)
		tree_node.scroll_to_item(cur_root)
		cur_root.select(0)
	else:
		var tree_node = get_main_tree_node()
		var cur_main_node_map = path_map_node_ui[now_show_panel_split_type][%MainPath.text]
		for cur_main_node_data in cur_main_node_map:
			var is_dir = false
			if cur_main_node_data:
				if cur_main_node_data.get_type_name() == "DirMergeNode":
					is_dir = true
				else:
					is_dir = false
			if is_dir or now_show_panel_split_type == 1:
				tree_node.set_selected(cur_main_node_map[cur_main_node_data],0)
				tree_node.scroll_to_item(cur_main_node_map[cur_main_node_data])
				cur_main_node_map[cur_main_node_data].select(0)
				update_sub_tree()
			else:
				tree_node.set_selected(cur_main_node_map[cur_main_node_data].get_parent(),0)
				tree_node.scroll_to_item(cur_main_node_map[cur_main_node_data].get_parent())
				cur_main_node_map[cur_main_node_data].get_parent().select(0)
				%MainPath.text = cur_main_node_data.file_path
				update_sub_tree()
	

func _on_backward_pressed():
	apply_backward_path_info_node_from_history()
	
func _on_forward_pressed():
	apply_forward_path_info_node_from_history()

func _on_upward_pressed():
	var tree_node = get_main_tree_node()
	var item = tree_node.get_selected()
	var cur_node_data = item.get_metadata(0)
	if cur_node_data.parent_node == null:
		return true
	
	var cur_path_info_node = null
	if cur_node_data.parent_node.get_type_name() == "DirNode":
		cur_path_info_node = cur_node_data.parent_node.merge_node
	else:
		cur_path_info_node = cur_node_data.parent_node
	add_path_info_node_to_history(cur_path_info_node)

func _on_refresh_pressed():
	var tree_node = get_main_tree_node()
	var item = tree_node.get_selected()
	var cur_node_data = item.get_metadata(0)
	var cur_plugin_node = await get_plugin_node()
	
	if cur_node_data.get_type_name() == "FileNode":
		cur_plugin_node.sync_path(cur_node_data.used_file_sync_uid,"")
	else:
		for key in cur_node_data.merge_dir_node:
			cur_plugin_node.sync_path(key,"")


var now_show_panel_split_type = 1
func _on_panel_split_pressed():
	now_show_panel_split_type += 1
	now_show_panel_split_type = (now_show_panel_split_type-1)%3+1
	update_panel_visible()
	update_tree_ui_flag = true
	#update_tree()

func update_panel_visible():
	%Show1.visible = false
	%Show2.visible = false
	%Show3.visible = false
	match now_show_panel_split_type:
		1:
			%Show1.visible = true
		2:
			%Show2.visible = true
		3:
			%Show3.visible = true
	var cur_plugin_node = await get_plugin_node()
	%PanelSplit.texture_normal = load(cur_plugin_node.get_absolute_path("ui/assets/Panels%d.svg"%now_show_panel_split_type))
	
func _on_config_pressed():
	%SearchConfig.popup(
			Rect2i(Vector2i(global_position)+Vector2i(size/2)-Vector2i(%SearchConfig.size/2),Vector2i(%SearchConfig.size))
		)


func _on_collapse_pressed():
	collapse_tree()
	pass # Replace with function body.


func _on_unfold_pressed():
	unfold_tree()

func collapse_tree():
	var root = await get_main_tree_root_node()
	collapse_node(root)
	cache_collapsed()
	pass
	
func collapse_node(parent: TreeItem):
	var items: Array[TreeItem] = parent.get_children()
	for item in items:
		var cur_node_data = item.get_metadata(0)
		if cur_node_data.get_type_name() == "DirMergeNode":
			collapse_node(item)
			item.collapsed = true

func unfold_tree():
	var root = await get_main_tree_root_node()
	unfold_node(root)
	cache_collapsed()

func unfold_node(parent: TreeItem):
	var items: Array[TreeItem] = parent.get_children()
	for item in items:
		var cur_node_data = item.get_metadata(0)
		if cur_node_data.get_type_name() == "DirMergeNode":
			unfold_node(item)
			item.collapsed = false



func get_main_tree_root_node(cur_now_show_panel_split_type=0):
	
	var tree_node = get_main_tree_node(cur_now_show_panel_split_type)
	var root = tree_node.get_root()
	if root == null:
		root = tree_node.create_item()
		var cur_plugin_node = await get_plugin_node()
		root.set_metadata(0, cur_plugin_node.root_node)
		root.set_expand_right(0, true)
		
		#root.set_icon(1, ok_texture)
		
	return root

func get_main_tree_node(cur_now_show_panel_split_type=0):
	if cur_now_show_panel_split_type==0:
		cur_now_show_panel_split_type = now_show_panel_split_type
	match cur_now_show_panel_split_type:
		1:
			return %MainTree1
		2:
			return %MainTree2
		3:
			return %MainTree3

var _cache_collapsed = []

func cache_collapsed():
	var root = await get_main_tree_root_node()
	var list = []
	_cache_collapsed_list(root, list)
	_cache_collapsed = list


func _cache_collapsed_list(parent: TreeItem, list: Array):
	var items: Array[TreeItem] = parent.get_children()
	for item in items:
		var cur_node_data = item.get_metadata(0)
		if cur_node_data.get_type_name() == "DirMergeNode":
			_cache_collapsed_list(item, list)
			if item.collapsed:
				list.append(cur_node_data.dir_path)



func _on_main_tree_item_activated():
	update_main_path()
	var tree_node = get_main_tree_node()
	var item = tree_node.get_selected()
	item.collapsed = not item.collapsed

func _on_main_tree_item_mouse_selected(position, mouse_button_index):
	update_main_path()
	pass # Replace with function body.

func _on_main_tree_item_selected():
	update_main_path()

func _on_main_tree_multi_selected(item, column, selected):
	update_main_path()
	pass # Replace with function body.

func update_main_path():
	var tree_node = get_main_tree_node()
	var item = tree_node.get_selected()
	var cur_node_data = item.get_metadata(0)
	if cur_node_data:
		if cur_node_data.get_type_name() == "DirMergeNode":
			%MainPath.text = cur_node_data.dir_path
		else:
			%MainPath.text = cur_node_data.file_path
	else:
		%MainPath.text = ""
	
	add_path_info_node_to_history(cur_node_data)
	
	#update_sub_tree()

func get_sub_tree_node(cur_now_show_panel_split_type=0):
	if cur_now_show_panel_split_type==0:
		cur_now_show_panel_split_type = now_show_panel_split_type
	match cur_now_show_panel_split_type:
		1:
			return null
		2:
			return %SubTree2
		3:
			return %SubTree3

func get_sub_tree_root_node(cur_now_show_panel_split_type=0):
	var tree_node = get_sub_tree_node(cur_now_show_panel_split_type)
	var root = tree_node.get_root()
	if root == null:
		root = tree_node.create_item()
		
	return root

func update_sub_tree():
	var main_path = %MainPath.text
	for i in range(2,4):
		var tree_node = get_sub_tree_node(i)
		if tree_node == null:
			continue
		tree_node.clear()
		tree_node.hide_folding = false
		tree_node.hide_root = true
		
		var cur_root = get_sub_tree_root_node(i)
		var cur_main_root = await get_main_tree_root_node(i)
		var cur_add_node = {}
		
		for cur_node_data in [cur_main_root.get_metadata(0)] if main_path=="" else path_map_node_ui[now_show_panel_split_type][main_path]:
			var child1
			if cur_node_data.get_type_name() == "FileNode":
				cur_node_data = cur_node_data.merge_node.parent_node
				if cur_add_node.get(cur_node_data,false):
					continue
				cur_add_node[cur_node_data] = true
			
			if main_path != "":
				child1 = tree_node.create_item(cur_root)
				child1.set_text(0, "..")
				#child1.set_icon(0, cur_node_data.dir_name)
				if cur_node_data.get_type_name() == "FileNode":
					child1.set_metadata(0, cur_node_data.merge_node.parent_node)
				else:
					child1.set_metadata(0, cur_node_data.parent_node)

				child1.set_expand_right(0, true)

			match cur_node_data.get_type_name():
				"DirMergeNode":
					for uid in cur_node_data.dirs:
						var cur_dir_node = cur_node_data.dirs[uid]
						child1 = tree_node.create_item(cur_root)
						child1.set_text(0, cur_dir_node.dir_name)
						#child1.set_icon(0, cur_node_data.dir_name)
						child1.set_metadata(0, cur_dir_node)
						child1.set_expand_right(0, true)
						
						#child1.set_icon(1, ok_texture)
						var is_ok = path_map_node_ui[now_show_panel_split_type][cur_dir_node.dir_path][cur_dir_node].get_metadata(1) 
						if is_ok:
							child1.set_icon(1, ok_texture)
							child1.set_metadata(1, true)
						else:
							child1.set_icon(1, fail_texture)
							child1.set_metadata(1, false)
						
						child1.visible = path_map_node_ui[now_show_panel_split_type][cur_dir_node.dir_path][cur_dir_node].get_meta("need_show",true) 
					
				
					for uid in cur_node_data.files:
						var cur_merge_file_node = cur_node_data.files[uid]
						for file_uid in cur_merge_file_node.merge_file_node:
							var cur_file_node = cur_merge_file_node.merge_file_node[file_uid]
							child1 = tree_node.create_item(cur_root)
							child1.set_text(0, cur_file_node.file_name)
							#child1.set_icon(0, cur_node_data.dir_name)
							child1.set_metadata(0, cur_file_node)
							
							child1.set_expand_right(0, true)

							if FileAccess.file_exists(cur_file_node.save_path):
								child1.set_icon(1, ok_texture)
								child1.set_metadata(1, true)
							else:
								child1.set_icon(1, fail_texture)
								child1.set_metadata(1, false)

							child1.visible = path_map_node_ui[now_show_panel_split_type][cur_file_node.file_path][cur_file_node].get_meta("need_show",true) 
							
							if cur_file_node.file_path == main_path:
								tree_node.set_selected(child1,0)
								tree_node.scroll_to_item(child1)
								child1.select(0)

func _on_sub_tree_item_activated():
	update_sub_tree_path()
	var tree_node = get_main_tree_node()
	var item = tree_node.get_selected()
	var cur_node_data = item.get_metadata(0)
	
	var sub_tree_node = get_sub_tree_node()
	if sub_tree_node == null:
		return ""
	var sub_item = sub_tree_node.get_selected()
	var cur_sub_node_data = sub_item.get_metadata(0)
	
	var is_dir = false
	if cur_sub_node_data:
		if cur_sub_node_data.get_type_name() == "DirMergeNode":
			is_dir = true
		else:
			is_dir = false
	
	
	if cur_node_data:
		if cur_node_data.get_type_name() == "DirMergeNode":
			if cur_node_data.dir_path != sub_tree_path:
				if is_dir:
					if sub_tree_path=="":
						var root_node = await get_main_tree_root_node()
						tree_node.set_selected(root_node,0)
						tree_node.scroll_to_item(root_node)
						root_node.select(0)
						#tree_node.edit_selected(true)
						#
						#root_node.grab_click_focus()
					else:
						var cur_main_node_map = path_map_node_ui[now_show_panel_split_type][sub_tree_path]
						for cur_main_node_data in cur_main_node_map:
							tree_node.set_selected(cur_main_node_map[cur_main_node_data],0)
							tree_node.scroll_to_item(cur_main_node_map[cur_main_node_data])
							
							cur_main_node_map[cur_main_node_data].select(0)
							#tree_node.edit_selected(true)
							#cur_main_node_map[cur_main_node_data]
					sub_tree_path = ""
					update_main_path()

	

func _on_sub_tree_item_mouse_selected(position, mouse_button_index):
	update_sub_tree_path()

func _on_sub_tree_item_selected():
	update_sub_tree_path()

func _on_sub_tree_multi_selected(item, column, selected):
	update_sub_tree_path()

var sub_tree_path = ""

func update_sub_tree_path():
	if now_show_panel_split_type!=1:
		var tree_node = get_sub_tree_node()
		var item = tree_node.get_selected()
		var cur_node_data = item.get_metadata(0)
		if cur_node_data:
			if cur_node_data.get_type_name() == "DirMergeNode":
				%MainPath.text = cur_node_data.dir_path
			else:
				%MainPath.text = cur_node_data.file_path
		else:
			%MainPath.text = ""
		add_path_info_node_to_history(cur_node_data)


var path_history = []
var path_history_index = 0

func get_now_path_info_node_from_history():
	if path_history.size()==0:
		return null
	return path_history[path_history_index]

func get_backward_path_info_node_from_history():
	if path_history_index == 0:
		return null
	return path_history[path_history_index-1]
	
func get_forward_path_info_node_from_history():
	if path_history_index >= len(path_history)-1:
		return null
	return path_history[path_history_index+1]
	
func apply_backward_path_info_node_from_history():
	var path_info_node = get_backward_path_info_node_from_history()
	if path_info_node == null:
		return 
	path_history_index= path_history_index-1
	apply_path_info_node(path_info_node)
	

func apply_forward_path_info_node_from_history():
	var path_info_node = get_forward_path_info_node_from_history()
	if path_info_node == null:
		return 
	path_history_index= path_history_index+1
	apply_path_info_node(path_info_node)
	

func add_path_info_node_to_history(path_info_node):
	if path_history.size()!=0:
		if get_now_path_info_node_from_history() == path_info_node:
			return 
		path_history = path_history.slice(0, path_history_index+1)
	path_history.append(path_info_node)
	path_history_index = path_history.size()-1
	apply_path_info_node(path_info_node)

func apply_path_info_node(path_info_node):
	var cur_path = ""
	match path_info_node.get_type_name():
		"FileNode":
			cur_path = path_info_node.file_path
		"DirMergeNode":
			cur_path = path_info_node.dir_path
	
	%MainPath.text = cur_path
	var tree_node = get_main_tree_node()
	
	var cur_item_node
	if cur_path == "":
		cur_item_node = await get_main_tree_root_node()
		pass
	else:
		cur_item_node = path_map_node_ui[now_show_panel_split_type][cur_path][path_info_node]

	tree_node.set_selected(cur_item_node,0)
	tree_node.scroll_to_item(cur_item_node)
	cur_item_node.select(0)
	
	update_tree_ui_flag = true
	#update_tree()
	
var update_tree_ui_flag = false


var last_global_position = Vector2(0,0)

func _process(delta):
	if update_tree_ui_flag:
		update_tree_ui()
		update_tree_ui_flag = false
	
	if last_global_position!=global_position:
		%AddPointUI.position = Vector2i(global_position)+Vector2i(size/2)-Vector2i(%AddPointUI.size/2)
		%SearchConfig.position = Vector2i(global_position)+Vector2i(size/2)-Vector2i(%SearchConfig.size/2)
		
		
func update_tree_ui():
	update_tree()
	pass


func _on_add_point_pressed():
	%AddPointUI.popup(
			Rect2i(Vector2i(global_position)+Vector2i(size/2)-Vector2i(%AddPointUI.size/2),Vector2i(%AddPointUI.size))
		)


func _on_download_point_pressed():
	download_now_path(false)


func _on_force_download_point_pressed():
	download_now_path(true)

func download_now_path(force_download=false):
	var path_info_node = get_now_path_info_node_from_history()
	
	var tree_node = get_main_tree_node()
	var item = tree_node.get_selected()
	var cur_node_data = item.get_metadata(0)
	
	var cur_plugin_node = await get_plugin_node()
	
	if cur_node_data.get_type_name() == "FileNode":
		cur_plugin_node.download_path(cur_node_data.used_file_sync_uid,cur_node_data.sub_path,force_download)
	else:
		for key in cur_node_data.merge_dir_node:
			cur_plugin_node.download_path(key, cur_node_data.merge_dir_node[key].sub_path,force_download)
