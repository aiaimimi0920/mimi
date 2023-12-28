extends ConfirmationDialog

var plugin_node = null

func get_plugin_node():
	if plugin_node and is_instance_valid(plugin_node):
		return plugin_node
	var _plugin_result = PluginManager.get_plugin_name(get_script())
	plugin_node = await PluginManager.get_plugin_instance_by_script_name(_plugin_result[0])
	return plugin_node


func _ready():
	await init_ui()

func init_ui():
	update_option_list()

func update_option_list():
	var popup = %Option.get_popup()
	popup.clear()
	
	var plugin_node = await get_plugin_node()
	var id = 0
	for key in plugin_node.file_adapter_name_list:
		popup.add_item(key, id)
		id += 1


var used_ui_map = {}
var other_used_ui_map = {}

func _on_option_item_selected(index):
	used_ui_map = {}
	other_used_ui_map = {}
	var cur_adapter_name = %Option.get_item_text(index)
	var plugin_node = await get_plugin_node()
	var cur_need_args = await plugin_node.get_fs_download_need_args(cur_adapter_name)
	var all_children = %Grid.get_children()
	for node in all_children:
		%Grid.remove_child(node)
	
	for key in cur_need_args:
		var label = Label.new()
		label.text = key
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		%Grid.add_child(label)
		
		var line_edit = LineEdit.new()
		line_edit.text = ""
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		%Grid.add_child(line_edit)
		used_ui_map[key] = line_edit

	for key in ["mapping_path","include","exclude"]:
		var label = Label.new()
		label.text = key
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		%Grid.add_child(label)
		
		var line_edit = LineEdit.new()
		line_edit.text = ""
		line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if key == "mapping_path":
			var path_info = get_parent().get_now_path_info_node_from_history()
			var cur_path = ""
			match path_info.get_type_name():
				"FileNode":
					cur_path = path_info.file_path
				"DirMergeNode":
					cur_path = path_info.dir_path
			line_edit.text = cur_path
		%Grid.add_child(line_edit)
		other_used_ui_map[key] = line_edit

func _on_canceled():
	pass

func _on_confirmed():
	if %Option.selected == -1:
		return 
	var plugin_node = await get_plugin_node()
	var cur_adapter_name = %Option.get_item_text(%Option.selected)
	var cur_data = {}
	for key in used_ui_map:
		cur_data[key] = used_ui_map[key].text
		if key == "path":
			cur_data[key] = used_ui_map[key].text.simplify_path()
		
	await plugin_node.add_file_sync_info(
		cur_data, cur_adapter_name,other_used_ui_map["mapping_path"].text.simplify_path(),
		other_used_ui_map["include"].text,other_used_ui_map["exclude"].text,"","",true,true)

