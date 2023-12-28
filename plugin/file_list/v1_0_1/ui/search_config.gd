extends ConfirmationDialog

signal update_search_config

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
	await init_ui()
	await init_signal()

func init_signal():
	var cur_plugin_node = await get_plugin_node()

func init_ui():
	update_view_list()
	if search_list.size() > 0:
		load_view(0)

var search_config = null
var search_list = []

func get_search_configs():
	if search_config == null:
		var cur_plugin_node = await get_plugin_node()
		var cur_search_configs = cur_plugin_node.service_config_manager.search_configs
		cur_search_configs = JSON.parse_string(cur_search_configs) 
		if cur_search_configs == null:
			cur_search_configs = {}
		search_config = cur_search_configs
	return search_config

func save_search_configs(cur_search_configs):
	var cur_plugin_node = await get_plugin_node()
	var json_string = JSON.stringify(cur_search_configs)
	cur_plugin_node.service_config_manager.search_configs = json_string
	search_config = cur_search_configs
	
func update_view_list():
	var popup = %Option.get_popup()
	popup.clear()
	search_list = []
	var id = 0
	var cur_search_configs = await get_search_configs()
	
	for key in cur_search_configs.keys():
		var view_info = cur_search_configs[key]
		popup.add_item(view_info.name, id)
		if view_info.icon != "":
			popup.set_item_icon(id, load(view_info.icon))
		id += 1
		search_list.append(key)
	
	emit_signal("update_search_config")


var current_view_info = null

func load_view(idx: int):
	%Option.select(idx)
	var cur_search_configs = await get_search_configs()
	var view_info = cur_search_configs[search_list[idx]]
	
	%Name.text				= view_info.name
	%Icon.text				= view_info.icon
	%ApplyInclude.set_pressed(view_info.apply_include)
	%Include.text			= view_info.include
	%ApplyExclude.set_pressed(view_info.apply_exclude)
	%Exclude.text			= view_info.exclude
	%HideFolder.set_pressed(view_info.hide_empty_dirs)
	
	_on_Icon_text_changed(view_info.icon)
	current_view_info = view_info


func save_temp_config():
	current_view_info.name = %Name.text
	current_view_info.icon = %Icon.text
	current_view_info.apply_include = %ApplyInclude.button_pressed
	current_view_info.include = %Include.text
	current_view_info.apply_exclude = %ApplyExclude.button_pressed
	current_view_info.exclude = %Name.text
	current_view_info.hide_empty_dirs = %HideFolder.button_pressed


func _on_Icon_text_changed(new_text):
	%Icon.right_icon = load(new_text)


func _on_canceled():
	_on_closed()


func _on_confirmed():
	_on_closed()

signal closed

func _on_closed():
	save_temp_config()
	save_search_configs(search_config)
	update_view_list()
	closed.emit()

func _on_Add_pressed():
	var cur_search_configs = await get_search_configs()
	save_search_configs(search_config)
	var cur_plugin_node = await get_plugin_node()
	var view_info = {
		"apply_exclude":false,"apply_include":false,
		"exclude":"","hide_empty_dirs":true,
		"icon":cur_plugin_node.get_absolute_path("ui/assets/folder.svg"),"include":"","name":"(Default)"
	}
	
	var target_name = "defaultView"
	var i = 1
	while true:
		var cur_target_name = target_name+"%d"%i
		if cur_target_name not in cur_search_configs:
			cur_search_configs[cur_target_name] = view_info
			break
		else:
			i+=1

	update_view_list()
	var id = search_list.size() - 1
	load_view(id)


func _on_Delete_pressed():
	var id = %Option.selected
	var cur_search_configs = await get_search_configs()
	cur_search_configs.erase(search_list[id])
	save_search_configs(cur_search_configs)

	update_view_list()
	if search_list.size() <= id:
		id -= 1
	load_view(id)

func _on_Option_item_selected(id):
	var cur_search_configs = await get_search_configs()
	save_search_configs(cur_search_configs)

	update_view_list()
	load_view(id)

#func _ready():
	#if not plugin:
		#return
	#
	


