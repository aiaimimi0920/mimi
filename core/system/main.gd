extends Control
@export var conversation_message_tscn:PackedScene

func _on_chat_input_box_toggled_main_conversation_info(toggle_on):
	if toggle_on:
		%ConversationContainer.visible = true
		%Empty1.visible = false
		fit_global_position()
	else:
		%ConversationContainer.visible = false
		%Empty1.visible = true
	update_mouse_passthrough_flag = true


func _on_chat_input_box_toggled_plugin_conversation_info(toggle_on):
	if toggle_on:
		%PluginConversationContainer.visible = true
		%Empty2.visible = false
		fit_global_position()
	else:
		%PluginConversationContainer.visible = false
		%Empty2.visible = true
	update_mouse_passthrough_flag = true

func update_mouse_passthrough():
	var chat_input_box = %ChatInputBox.get_global_rect()
	var lsat_vector_array = []
	var last_box_polygons = get_polygons_from_rect(%Model.get_global_rect())
	if %ChatInputBox.visible == true:
		last_box_polygons = get_polygons_from_rect(%Model.get_global_rect().grow_side(SIDE_BOTTOM,10))
		var chat_rect = %ChatInputBox.get_global_rect().grow(45)
		last_box_polygons = Geometry2D.merge_polygons(last_box_polygons, get_polygons_from_rect(chat_rect))
		last_box_polygons = last_box_polygons[0]
		if %ConversationContainer.visible == true:
			last_box_polygons = Geometry2D.merge_polygons(last_box_polygons, get_polygons_from_rect(%ConversationContainer.get_global_rect()))[0]
		if %PluginConversationContainer.visible == true:
			last_box_polygons = Geometry2D.merge_polygons(last_box_polygons, get_polygons_from_rect(%PluginConversationContainer.get_global_rect()))[0]

	if %DialogMessageContainer.visible == true:
		var DialogMessageContainer_global_rect = %DialogMessageContainer.get_global_rect()
		if last_message_node!=null:
			DialogMessageContainer_global_rect = DialogMessageContainer_global_rect.merge(last_message_node.get_global_rect().grow_individual(
				%DialogMessageContainer.get_theme_constant("margin_left"),%DialogMessageContainer.get_theme_constant("margin_top"),
				%DialogMessageContainer.get_theme_constant("margin_right"),%DialogMessageContainer.get_theme_constant("margin_bottom")))
		last_box_polygons = Geometry2D.merge_polygons(last_box_polygons, get_polygons_from_rect(DialogMessageContainer_global_rect.grow_side(SIDE_BOTTOM,20)))[0]
	DisplayServer.window_set_mouse_passthrough(last_box_polygons)
	
	## By the way, update the settings interface of the sub window
	#%ConversationContainer.update_settings_dialog_position()
	#%PluginConversationContainer.update_settings_dialog_position()


func get_polygons_from_rect(cur_rect):
	var box_polygons = PackedVector2Array([cur_rect.position,cur_rect.position+Vector2(cur_rect.size.x,0),cur_rect.end,cur_rect.position+Vector2(0,cur_rect.size.y)])
	return box_polygons
	

var free_ai_bot

func _ready()->void:
	await get_tree().process_frame
	_initialize_window()
	## Wait for one frame to initialize all UI positions
	update_mouse_passthrough_flag = true
	## Check if updates are needed after startup
	if not Engine.is_editor_hint():
		pass
	else:
		await UpdateManager.check_update()
	
	if await AuthorizeManager.is_token_valid():
		pass
	else:
		## Waiting for login
		await AuthorizeManager.token_recieved
	await PluginManager.reload_plugins()
	test_funcs()
	free_ai_bot = await PluginManager.get_plugin_instance_by_script_name("free_ai_bot")
	
	
	
func _on_chat_input_box_ask_something(ask_text,use_http_library=false,use_knowledge_library=false,use_plugin_library=false):
	## It's a command
	if ask_text.begins_with("/"):
		ask_text = ask_text.trim_prefix("/")
		#for i in ask_text.size():
			#pass
		var ask_data = ask_text.split(" ", false)
		if len(ask_data)<2:
			return 
		var plugin_name = ask_data[0]
		var plugin_method = ask_data[1]
		var plugin_data = ask_data.slice(2)
		var cur_plugin_data = []
		for i in range(len(plugin_data)):
			var cur_data = str_to_var(plugin_data[i])
			if cur_data==null:
				cur_data = plugin_data[i]
			cur_plugin_data.append(cur_data)
		var plugin_node = await PluginManager.get_plugin_instance_by_script_name(plugin_name)
		if not plugin_node.has_method(plugin_method):
			return 
		plugin_node.callv(plugin_method, cur_plugin_data)
		pass
	else:
		free_ai_bot = await PluginManager.get_plugin_instance_by_script_name("free_ai_bot")
		free_ai_bot.create_chat_completion(true, ask_text, true,use_http_library,use_knowledge_library,use_plugin_library)
	pass


func fit_global_position():
	# Make certain coordinate updates
	if %ChatInputBox.visible and min_begin and max_begin:
		var last_min_begin = min_begin
		last_min_begin.x = max(last_min_begin.x,min_chat_begin.x)
		last_min_begin.y = max(last_min_begin.y,min_chat_begin.y)
		if %ConversationContainer.visible:
			last_min_begin.x = max(last_min_begin.x,min_main_begin.x)
			last_min_begin.y = max(last_min_begin.y,min_main_begin.y)
			
		if %PluginConversationContainer.visible:
			last_min_begin.x = max(last_min_begin.x,min_plugin_begin.x)
			last_min_begin.y = max(last_min_begin.y,min_plugin_begin.y)

		if %DialogMessageContainer.visible:
			last_min_begin.x = max(last_min_begin.x,min_dialog_begin.x)
			last_min_begin.y = max(last_min_begin.y,min_dialog_begin.y)

		var last_max_begin = max_begin
		last_max_begin.x = min(last_max_begin.x,max_chat_begin.x)
		last_max_begin.y = min(last_max_begin.y,max_chat_begin.y)
		if %ConversationContainer.visible:
			last_max_begin.x = min(last_max_begin.x,max_main_begin.x)
			last_max_begin.y = min(last_max_begin.y,max_main_begin.y)
		if %PluginConversationContainer.visible:
			last_max_begin.x = min(last_max_begin.x,max_plugin_begin.x)
			last_max_begin.y = min(last_max_begin.y,max_plugin_begin.y)

		if %DialogMessageContainer.visible:
			last_max_begin.x = min(last_max_begin.x,max_dialog_begin.x)
			last_max_begin.y = min(last_max_begin.y,max_dialog_begin.y)
		global_position = global_position.clamp(last_min_begin,last_max_begin)

func _on_chat_input_box_visibility_changed():
	%Empty3.visible = not %ChatInputBox.visible
	fit_global_position()
	update_mouse_passthrough_flag = true



func _on_main_change_relative_postion(change_relative_postion):
	global_position = (global_position+change_relative_postion).clamp(min_begin,max_begin)
	fit_global_position()
	if not change_relative_postion.is_equal_approx(Vector2.ZERO):
		if %ChatInputBox.visible == true and %ChatInputBox.is_lock():
			%ChatInputBox.now_free()
	update_mouse_passthrough_flag = true


var min_begin
var max_begin
var min_chat_begin
var max_chat_begin

var min_main_begin
var max_main_begin

var min_plugin_begin
var max_plugin_begin

var min_dialog_begin
var max_dialog_begin

var DialogMessageContainer_custom_size
var DialogMessageContainer_custom_position
func _initialize_window() -> void:
	var window: Window = get_window()
	window.size = Vector2i(DisplayServer.screen_get_size() + Vector2i(1, 1))
	window.position = DisplayServer.screen_get_position()
	await get_tree().process_frame
	var cur_global_rect = %Model.get_global_rect()
	min_begin = Vector2(global_position) - Vector2(cur_global_rect.position) - Vector2(cur_global_rect.size.x*0.3,cur_global_rect.size.y*0.2)
	max_begin = Vector2(window.size)- Vector2(cur_global_rect.size) - Vector2(cur_global_rect.position)+Vector2(global_position)+ Vector2(cur_global_rect.size.x*0.3,cur_global_rect.size.y*0.1)
	
	var cur_chat_global_rect = %ChatInputBox.get_global_rect()
	min_chat_begin = Vector2(global_position) - Vector2(cur_chat_global_rect.position) + Vector2(40,40)
	max_chat_begin = Vector2(window.size)- Vector2(cur_chat_global_rect.size) - Vector2(cur_chat_global_rect.position)+Vector2(global_position)- Vector2(40,40)

	var cur_main_global_rect
	if %ConversationContainer.visible:
		cur_main_global_rect = %ConversationContainer.get_global_rect()
	else:
		cur_main_global_rect = %Empty1.get_global_rect()
	min_main_begin = Vector2(global_position) - Vector2(cur_main_global_rect.position)
	max_main_begin = Vector2(window.size)- Vector2(cur_main_global_rect.size) - Vector2(cur_main_global_rect.position)+Vector2(global_position)
	
	var cur_plugin_global_rect
	if %PluginConversationContainer.visible:
		cur_plugin_global_rect = %PluginConversationContainer.get_global_rect()
	else:
		cur_plugin_global_rect = %Empty2.get_global_rect()
	min_plugin_begin = Vector2(global_position) - Vector2(cur_plugin_global_rect.position)
	max_plugin_begin = Vector2(window.size)- Vector2(cur_plugin_global_rect.size) - Vector2(cur_plugin_global_rect.position)+Vector2(global_position)
	
	var cur_dialog_global_rect
	if %DialogMessageContainer.visible:
		cur_dialog_global_rect = %DialogMessageContainer.get_global_rect()
		min_dialog_begin = Vector2(global_position) - Vector2(cur_dialog_global_rect.position)
		max_dialog_begin = Vector2(window.size)- Vector2(cur_dialog_global_rect.size) - Vector2(cur_dialog_global_rect.position)+Vector2(global_position)

	DialogMessageContainer_custom_size = %DialogMessageContainer.size
	#DialogMessageContainer_custom_size.y=0
	DialogMessageContainer_custom_position = %DialogMessageContainer.position
	%DialogMessageContainer.visible = false
	
	
		
func _on_model_main_active_model():
	## Display dialog box information
	%ChatInputBox.auto_free()


func _on_model_main_inactive_model():
	## Hide all information
	%ChatInputBox.now_free()


func _on_dialog_message_container_visibility_changed():
	#await get_tree().process_frame
	fit_global_position()
	update_mouse_passthrough_flag = true


func _on_dialog_message_container_resized():
	#await get_tree().process_frame
	fit_global_position()
	update_mouse_passthrough_flag = true

func _on_dialog_message_container_inactive_dialog():
	%DialogMessageContainer.visible = false

var last_message_node

func add_dialog_message(cur_message):
	if cur_message.is_bot == false:
		return 
	if cur_message.show_message_type == 0:
		append_message_array = []
		append_message_array.append(cur_message)
	elif cur_message.show_message_type == 1:
		append_message_array = []
		append_message_array.append(cur_message)
	elif cur_message.show_message_type == 2:
		append_message_array.append(cur_message)
	elif cur_message.show_message_type == 3:
		append_message_array.append(cur_message)
	
	if cur_message.show_message_type == 0 or cur_message.show_message_type == 3:
		for node in %DialogMessageContainer.get_children():
			%DialogMessageContainer.remove_child(node)
		var cur_ins = conversation_message_tscn.instantiate()
		cur_ins.show_animation = false
		last_message_node = cur_ins
		cur_ins.size_flags_vertical = SIZE_SHRINK_END
		%DialogMessageContainer.add_child(cur_ins)
		cur_ins.connect("item_rect_changed",_on_dialog_message_container_resized)
		cur_ins.message_array = append_message_array
		cur_ins.update_message_array_ui()
		%DialogMessageContainer.visible = true

var append_message_array = []
func _on_conversation_container_change_conversation(last_conversation, now_conversation):
	if last_conversation!=now_conversation or last_conversation==null:
		if last_conversation and last_conversation.is_connected("append_one_message",add_dialog_message):
			last_conversation.disconnect("append_one_message", add_dialog_message)
		if now_conversation:
			now_conversation.connect("append_one_message", add_dialog_message)
		append_message_array = []


var update_mouse_passthrough_flag = false
func _process(delta):
	if update_mouse_passthrough_flag == true:
		update_mouse_passthrough()
		update_mouse_passthrough_flag = false

func test_funcs():
	pass
