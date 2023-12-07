extends Panel
class_name ConversationMenubar

# -------------------------------------------------------------------------------------------------
const CONVERSATION_TAB = preload("res://gui/conversation/conversation_tab.tscn")

# -------------------------------------------------------------------------------------------------
signal conversation_selected(conversation_id)
signal conversation_closed(conversation_id)
signal create_new_conversation

# -------------------------------------------------------------------------------------------------
@export var _main_menu_path: NodePath
var _active_file_tab: ConversationTab
var _tabs_map: Dictionary # Dictonary<project_id, ProjectTab>

# -------------------------------------------------------------------------------------------------
func make_tab(cur_conversation: ConversationAPI) -> void:
	var tab: ConversationTab = CONVERSATION_TAB.instantiate()
	tab.title = cur_conversation.conversation_id
	tab.title_tooltip_text = cur_conversation.conversation_id
	tab.conversation_id = cur_conversation.conversation_id
	tab.connect("close_requested", Callable(self, "_on_tab_close_requested"))
	tab.connect("selected", Callable(self, "_on_tab_selected"))
	%Tabs.add_child(tab)
	_tabs_map[tab.conversation_id] = tab

# ------------------------------------------------------------------------------------------------
func has_tab(cur_conversation: ConversationAPI) -> bool:
	return _tabs_map.has(cur_conversation.conversation_id)

# ------------------------------------------------------------------------------------------------
func remove_tab(cur_conversation: ConversationAPI) -> void:
	if _tabs_map.has(cur_conversation.conversation_id):
		var tab = _tabs_map[cur_conversation.conversation_id]
		tab.disconnect("close_requested", Callable(self, "_on_tab_close_requested"))
		tab.disconnect("selected", Callable(self, "_on_tab_selected"))
		%Tabs.remove_child(tab)
		_tabs_map.erase(cur_conversation.conversation_id)
		tab.call_deferred("free")
		## Please note that the file needs to be deleted, but for file recovery, 
		## do not delete the file and move it to the delete log folder
		ConversationManager.remove_conversation(cur_conversation.conversation_id)
# ------------------------------------------------------------------------------------------------
func remove_all_tabs() -> void:
	for conversation_id in _tabs_map.keys():
		var cur_conversation: ConversationAPI = ConversationManager.get_conversation(conversation_id)
		remove_tab(cur_conversation)
	_tabs_map.clear()
	_active_file_tab = null

# ------------------------------------------------------------------------------------------------
func update_tab_title(cur_conversation: ConversationAPI) -> void:
	if _tabs_map.has(cur_conversation.conversation_id):
		_tabs_map[cur_conversation.conversation_id].title = cur_conversation.conversation_id
		_tabs_map[cur_conversation.conversation_id].title_tooltip_text = cur_conversation.conversation_id

# ------------------------------------------------------------------------------------------------
func set_tab_active(cur_conversation: ConversationAPI) -> void:
	if _tabs_map.has(cur_conversation.conversation_id):
		var tab: ConversationTab = _tabs_map[cur_conversation.conversation_id]
		_active_file_tab = tab
		for c in %Tabs.get_children():
			c.set_active(false)
		tab.set_active(true)
	else:
		print_debug("Project tab not found")

# -------------------------------------------------------------------------------------------------
func _on_tab_close_requested(tab: ConversationTab) -> void:
	emit_signal("conversation_closed", tab.conversation_id)

# -------------------------------------------------------------------------------------------------
func _on_tab_selected(tab: ConversationTab) -> void:
	emit_signal("conversation_selected", tab.conversation_id)

# -------------------------------------------------------------------------------------------------
func _on_NewFileButton_pressed():
	emit_signal("create_new_conversation")

# -------------------------------------------------------------------------------------------------
func _on_MenuButton_pressed():
	var target_rect = Rect2()
	target_rect.position = self.get_screen_position()+Vector2(0,self.size.y)
	target_rect.size = Vector2(get_node(_main_menu_path).size)
	get_node(_main_menu_path).popup_on_parent(target_rect)

# -------------------------------------------------------------------------------------------------
func get_first_conversation_id():
	if %Tabs.get_child_count() == 0:
		return ""
	return %Tabs.get_child(0).conversation_id
