extends ConversationContainer

func _on_menubar_conversation_closed(conversation_id):
	var cur_conversation = ConversationManager.get_conversation(conversation_id)
	if cur_conversation:
		%Menubar.remove_tab(cur_conversation)
	var cur_new_conversation = ConversationManager.create_plugin_conversation(cur_conversation.conversation_name)
	%Conversation.conversation = cur_new_conversation

func _on_menubar_conversation_selected(conversation_id):
	var cur_conversation = ConversationManager.get_conversation(conversation_id)
	%Conversation.conversation = cur_conversation
	if cur_conversation:
		%Menubar.set_tab_active(cur_conversation)

func _ready():
	var last_cur_conversation_id = null
	for cur_conversation_id in ConversationManager.conversation_plugin_map:
		var cur_conversation = ConversationManager.get_conversation(cur_conversation_id)
		%Menubar.make_tab(cur_conversation)
		last_cur_conversation_id = cur_conversation_id
	
	if last_cur_conversation_id:
		_on_menubar_conversation_selected(last_cur_conversation_id)
	
	ConversationManager.connect("add_new_plugin_conversation_finished",%Menubar.make_tab)

## TODO:Do not enable export for now
func _on_conversation_main_menu_export_md():
	if %Conversation.conversation == null:
		return 
	var cur_file = await %Conversation.conversation.export_md()
	OS.shell_show_in_file_manager(cur_file)

func _on_conversation_main_menu_open_about_dialog():
	if %Conversation.conversation == null:
		return 
	var target_rect = Rect2()
	target_rect.position = self.get_screen_position()+ Vector2(self.size/2) - Vector2(%ConversationAboutDialog.size/2)
	target_rect.size = Vector2(%ConversationAboutDialog.size)
	%ConversationAboutDialog.popup_on_parent(target_rect)
	
	var cur_plugin_name = %Conversation.conversation.conversation_name
	var cur_plugin = await PluginManager.get_plugin_instance_by_script_name(cur_plugin_name)
	var cur_data = {}
	cur_data["name"] = cur_plugin.plugin_info["name"]
	cur_data["version"] = cur_plugin.plugin_info["version"]
	cur_data["author"] = cur_plugin.plugin_info["author"]
	cur_data["description"] = cur_plugin.plugin_info["description"]
	cur_data["dependency"] = cur_plugin.plugin_info["dependency"]
	cur_data["use_dependency_version"] = {}
	for use_dependency in cur_data["dependency"]:
		var use_dependency_plugin = await PluginManager.get_plugin_instance_by_script_name(use_dependency)
		cur_data["use_dependency_version"][use_dependency] = use_dependency_plugin.plugin_info["version"]
	%ConversationAboutDialog.data = cur_data
	
func _on_conversation_main_menu_open_settings_dialog():
	if %Conversation.conversation == null:
		return 
	var target_rect = Rect2()
	target_rect.position = self.get_screen_position()+ Vector2(self.size/2) - Vector2(%SettingsDialog.size/2)
	target_rect.size = Vector2(%SettingsDialog.size)
	%SettingsDialog.popup_on_parent(target_rect)

	var cur_plugin_name = %Conversation.conversation.conversation_name
	var cur_plugin = await PluginManager.get_plugin_instance_by_script_name(cur_plugin_name)
	%SettingsDialog.setup(cur_plugin.service_config_manager)

	
func _on_conversation_main_menu_open_manual_url():
	if %Conversation.conversation == null:
		return 
	var cur_plugin_name = %Conversation.conversation.conversation_name
	var cur_plugin = await PluginManager.get_plugin_instance_by_script_name(cur_plugin_name)
	var cur_main_url = cur_plugin.plugin_info.get("manual",null)
	if cur_main_url:
		OS.shell_open(cur_main_url)


func _on_conversation_main_menu_open_bug_tracker_url():
	if %Conversation.conversation == null:
		return 
	var cur_plugin_name = %Conversation.conversation.conversation_name
	var cur_plugin = await PluginManager.get_plugin_instance_by_script_name(cur_plugin_name)
	var cur_bug_tracker_url = cur_plugin.plugin_info.get("bug_tracker",null)
	if cur_bug_tracker_url:
		OS.shell_open(cur_bug_tracker_url)


func _on_conversation_child_entered_tree(node):
	await get_tree().process_frame
	%ScrollContainer.ensure_control_visible(node)
	%ScrollContainer.scroll_vertical+=40

func update_settings_dialog_position():
	%SettingsDialog.position = self.get_screen_position()+ Vector2(self.size/2) - Vector2(%SettingsDialog.size/2)
