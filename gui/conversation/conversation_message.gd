extends VBoxContainer
@export var use_modulate:Color
@export var not_use_modulate:Color


var button_like_state = 0 ## 0 : unknown, 1 : dislike, 2 : liking

signal yes_or_no

func _on_dislike_button_toggled(toggled_on):
	if toggled_on:
		button_like_state = 1
		%like_button.set_pressed_no_signal(not toggled_on)
		%like_button.modulate = null
		%dislike_button.modulate = use_modulate
	else:
		%dislike_button.modulate = null
		button_like_state = 0
	update_message_array_like_state()
		

func _on_like_button_toggled(toggled_on):
	if toggled_on:
		button_like_state = 2
		%dislike_button.set_pressed_no_signal(not toggled_on)
		%like_button.modulate = use_modulate
		%dislike_button.modulate = null
	else:
		%like_button.modulate = null
		button_like_state = 0
	update_message_array_like_state()
	
func update_message_array_like_state():
	for cur_message in message_array:
		cur_message.like_state = button_like_state

var message_array =[]
	
func update_button_ui(is_last):
	%no_button.visible = false
	%yes_button.visible = false
	%dislike_button.visible = false
	%like_button.visible = false
	if is_last:
		var cur_have_trigger_message = false
		for cur_message in message_array:
			if cur_message.trigger_counts != 0:
				cur_have_trigger_message = true
				break
		if cur_have_trigger_message:
			%no_button.visible = true
			%yes_button.visible = true
		
		## Only the last message from a robot will display a button
		if message_array[-1].is_bot:
			%dislike_button.visible = true
			%like_button.visible = true

	if message_array[-1].like_state == 0:
		%dislike_button.set_pressed(false)
		%like_button.set_pressed(false)
	elif message_array[-1].like_state == 1:
		%dislike_button.set_pressed(true)
		%like_button.set_pressed(false)
	elif message_array[-1].like_state == 2:
		%dislike_button.set_pressed(false)
		%like_button.set_pressed(true)

## Music audio message usage
@export var audio_template:PackedScene
## Voice audio message usage
@export var voice_audio_template:PackedScene
## File message usage
@export var file_template:PackedScene
## Image message usage
@export var image_template:PackedScene
## Input form message usage
@export var input_form_template:PackedScene
## Json message usage
@export var json_template:PackedScene
## quote message usage
@export var quote_template:PackedScene
## source message usage
@export var source_template:PackedScene
## text message usage
@export var text_template:PackedScene
## stream text message usage
@export var stream_text_template:PackedScene
## video message usage
@export var video_template:PackedScene
## xml message usage
@export var xml_template:PackedScene

var show_animation = true

func _ready():

	if show_animation:
		showing()
	else:
		scale = Vector2(1.0,1.0)
	

func showing():
	%AnimationPlayer.play("Showing")
	update_message_array_ui()


func update_message_array_ui():
	for node in %content_container.get_children():
		%content_container.remove_child(node)

	for cur_message in message_array:
		var cur_node = null
		match cur_message.conversation_message_type:
			"Audio":
				cur_node = audio_template.instantiate()
			"VoiceAudio":
				cur_node = voice_audio_template.instantiate()
			"File":
				cur_node = file_template.instantiate()
			"Image":
				cur_node = image_template.instantiate()
			"InputForm":
				cur_node = input_form_template.instantiate()
			"Json":
				cur_node = json_template.instantiate()
			"Quote":
				cur_node = quote_template.instantiate()
			"Source":
				cur_node = source_template.instantiate()
			"Plain":
				cur_node = text_template.instantiate()
			"StreamPlain":
				cur_node = stream_text_template.instantiate()
			"Video":
				cur_node = video_template.instantiate()
			"Xml":
				cur_node = xml_template.instantiate()
			_:
				cur_node = text_template.instantiate()
		%content_container.add_child(cur_node)
		cur_node.set_message(cur_message)
		

func _on_no_button_pressed():
	msg_call(message_array[-1], false)
	emit_signal("yes_or_no", message_array[-1], false)


func _on_yes_button_pressed():
	msg_call(message_array[-1], true)
	emit_signal("yes_or_no", message_array[-1], false)


func msg_call(input_message=null,result=true):
	for cur_message in message_array:
		if cur_message.trigger_counts > 0:
			cur_message.reduce_trigger_counts()
			var cur_callback = cur_message.plugin_callback
			if cur_callback==null or cur_callback.size()<=0:
				pass
			else:
				PluginManager.call_from_dict(cur_callback[0], cur_callback[1], cur_callback[2], input_message, result)
				
			var object_callback = cur_message.object_callback
			if object_callback:
				object_callback.call(input_message, result)
				
			cur_message.emit_signal("call_finished")
			
