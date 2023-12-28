extends PanelContainer
class_name ConversationContainer

signal change_conversation

func _on_menubar_create_new_conversation():
	var cur_conversation = ConversationManager.create_main_conversation()
	if cur_conversation:
		%Menubar.make_tab(cur_conversation)
	
	_on_menubar_conversation_selected(cur_conversation.conversation_id)
	set_conversation_visible(true)

func _on_menubar_conversation_closed(conversation_id):
	var cur_conversation = ConversationManager.get_conversation(conversation_id)
	if cur_conversation:
		%Menubar.remove_tab(cur_conversation)
	
	if cur_conversation == ConversationManager.now_use_main_conversation:
		ConversationManager.now_use_main_conversation = null
	
	var first_conversation_id = %Menubar.get_first_conversation_id()
	if first_conversation_id=="":
		_on_menubar_create_new_conversation()
	else:
		_on_menubar_conversation_selected(first_conversation_id)
	
	set_conversation_visible(true)

func _on_menubar_conversation_selected(conversation_id):
	var cur_conversation = ConversationManager.get_conversation(conversation_id)
	%Conversation.conversation = cur_conversation
	var last_cur_conversation = ConversationManager.now_use_main_conversation
	ConversationManager.now_use_main_conversation = cur_conversation
	if cur_conversation:
		%Menubar.set_tab_active(cur_conversation)
		ConfigManager.last_conversation_id = conversation_id
	emit_signal("change_conversation", last_cur_conversation, ConversationManager.now_use_main_conversation)
	
	set_conversation_visible(true)

func _ready():
	var last_cur_conversation_id = null
	for cur_conversation_id in ConversationManager.conversation_main_map:
		var cur_conversation = ConversationManager.get_conversation(cur_conversation_id)
		%Menubar.make_tab(cur_conversation)
		last_cur_conversation_id = cur_conversation_id
	
	if ConfigManager.last_conversation_id != "" and ConfigManager.last_conversation_id in ConversationManager.conversation_main_map:
		_on_menubar_conversation_selected(ConfigManager.last_conversation_id)
	else:
		_on_menubar_conversation_selected(last_cur_conversation_id)
	
	if ConversationManager.conversation_main_map.size()==0:
		_on_menubar_create_new_conversation()
		
	ConversationManager.connect("add_new_main_conversation_finished", %Menubar.make_tab)
	

## TODO:Do not enable export for now
func _on_conversation_main_menu_export_md():
	var cur_file = await ConversationManager.now_use_main_conversation.export_md()
	OS.shell_show_in_file_manager(cur_file)


func _on_conversation_main_menu_open_about_dialog():
	var target_rect = Rect2()
	target_rect.position = self.get_screen_position()+ Vector2(self.size/2) - Vector2(%ConversationAboutDialog.size/2)
	target_rect.size = Vector2(%ConversationAboutDialog.size)
	%ConversationAboutDialog.popup_on_parent(target_rect)
	var cur_data = {}
	cur_data["name"] = "mimi"
	cur_data["version"] = "v1_0_0"
	cur_data["author"] = "aiaimimi0920"
	cur_data["description"] = "Mimi is a private AI that can do many things for you, free of charge, completely yours. In summary, having fun"
	cur_data["dependency"] = {"free_ai_bot":["v1_0_0"], "update_bot":["v1_0_1"]}
	cur_data["use_dependency_version"] = {"free_ai_bot":"v1_0_0", "update_bot":"v1_0_1"}
	%ConversationAboutDialog.data = cur_data


func _on_conversation_main_menu_open_settings_dialog():
	var target_rect = Rect2()
	target_rect.position = self.get_screen_position()+ Vector2(self.size/2) - Vector2(%SettingsDialog.size/2)
	target_rect.size = Vector2(%SettingsDialog.size)
	%SettingsDialog.popup_on_parent(target_rect)
	%SettingsDialog.setup(ConfigManager)


func _on_conversation_main_menu_open_manual_url():
	var cur_main_url = "https://github.com/aiaimimi0920/mimi"
	OS.shell_open(cur_main_url)


func _on_conversation_main_menu_open_bug_tracker_url():
	var cur_main_url = "https://github.com/aiaimimi0920/mimi/issues"
	OS.shell_open(cur_main_url)


func _on_conversation_child_entered_tree(node):
	await get_tree().process_frame
	%ScrollContainer.ensure_control_visible(node)
	%ScrollContainer.scroll_vertical+=40


func update_settings_dialog_position():
	%SettingsDialog.position = self.get_screen_position()+ Vector2(self.size/2) - Vector2(%SettingsDialog.size/2)

func set_conversation_visible(bvisible):
	%Conversation.visible = bvisible
	%UIContainer.visible = not bvisible

func _on_conversation_main_menu_open_message_dialog():
	set_conversation_visible(true)

func _on_conversation_main_menu_open_ui_dialog():
	if %Conversation.conversation == null:
		return false
	var cur_name = %Conversation.conversation.conversation_type
	var cur_node = %UIContainer.get_node_or_null(cur_name)
	if cur_node == null:
		cur_node = ConfigManager.get_ui_instance()
		if cur_node == null:
			return false
		%UIContainer.add_child(cur_node)
		cur_node.add_to_group(cur_name)
		cur_node.name = cur_name
	set_conversation_visible(false)
	%Timer.start()


var last_global_position = Vector2(0,0)
func _process(delta):
	if last_global_position!=global_position:
		%SettingsDialog.position = self.get_screen_position()+ Vector2(self.size/2) - Vector2(%SettingsDialog.size/2)
		%ConversationAboutDialog.position = self.get_screen_position()+ Vector2(self.size/2) - Vector2(%ConversationAboutDialog.size/2)
