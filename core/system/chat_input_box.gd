extends PanelContainer

@export var text_edit_min_y = 80

signal toggled_main_conversation_info
signal toggled_plugin_conversation_info
signal toggled_main_conversation_info_change_ui
signal toggled_plugin_conversation_info_change_ui

signal ask_something

@export var use_modulate:Color
@export var not_use_modulate:Color


func _ready():
	%TextEdit.custom_minimum_size.y = text_edit_min_y
	_on_search_internet_button_toggled(%search_internet_button.button_pressed)
	_on_search_plugin_button_toggled(%search_plugin_button.button_pressed)
	_on_search_document_button_toggled(%search_document_button.button_pressed)
	_on_lock_input_button_toggled(%lock_input_button.button_pressed)

func _on_text_edit_resized():
	if %TextEdit.size.y>=text_edit_min_y*3:
		%TextEdit.custom_minimum_size.y = text_edit_min_y*3
		%TextEdit.scroll_fit_content_height = false
	else:
		%TextEdit.custom_minimum_size.y = text_edit_min_y
		%TextEdit.scroll_fit_content_height = true
	pass # Replace with function body.


func _on_expand_main_conversation_info_button_toggled(toggled_on):
	emit_signal("toggled_main_conversation_info",toggled_on)


func _on_expand_plugin_conversation_info_button_toggled(toggled_on):
	emit_signal("toggled_plugin_conversation_info",toggled_on)


func auto_free():
	%AnimationPlayer.stop(true)
	if %lock_input_button.button_pressed:
		## 锁定状态不计算时间
		modulate.a = 1
		visible = true
	else:
		%AnimationPlayer.play("auto_free")

func now_free():
	%AnimationPlayer.stop(true)
	modulate.a = 0
	visible = false
	


func _on_search_internet_button_toggled(toggled_on):
	if toggled_on:
		%search_internet_button.modulate = use_modulate
	else:
		%search_internet_button.modulate = not_use_modulate


func _on_search_plugin_button_toggled(toggled_on):
	if toggled_on:
		%search_plugin_button.modulate = use_modulate
	else:
		%search_plugin_button.modulate = not_use_modulate


func _on_search_document_button_toggled(toggled_on):
	if toggled_on:
		%search_document_button.modulate = use_modulate
		PluginManager.get_plugin_instance_by_script_name("knowledge_library")
	else:
		%search_document_button.modulate = not_use_modulate



func _on_lock_input_button_toggled(toggled_on):
	if toggled_on:
		%lock_input_button.modulate = use_modulate
	else:
		%lock_input_button.modulate = not_use_modulate
	auto_free()

func is_lock():
	return %lock_input_button.button_pressed == false

func active_self(_agr1=null,_agr2=null,_agr3=null,_agr4=null):
	auto_free()
	pass

func _on_send_button_pressed():
	emit_signal("ask_something", %TextEdit.text.strip_edges(),
		%search_internet_button.button_pressed,
		%search_document_button.button_pressed,
		%search_plugin_button.button_pressed)
	%TextEdit.text = ""


func _input(event):
	if %TextEdit.has_focus():
		if event.is_action_pressed("ui_send"):
			_on_send_button_pressed()
			get_viewport().set_input_as_handled()


