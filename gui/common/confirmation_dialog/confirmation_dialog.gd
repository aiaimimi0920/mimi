extends Control

signal click_yes
signal click_no

var message:
	set = set_message
@export var message_list_item_template:PackedScene

func _ready():
	showing()

func showing():
	$AnimationPlayer.play("Showing")

func show_message(show_list=false):
	%message_label.visible = not show_list
	%message_container.visible = show_list

func set_message(val):
	message = val
	match typeof(val):
		TYPE_STRING:
			show_message(false)
			%message_label.text = message
		TYPE_PACKED_STRING_ARRAY:
			show_message(true)
			for node in %message_container.get_children():
				%message_container.remove_child(node)
			for message_str in message:
				var item_template = message_list_item_template.instance()
				item_template.get_node("MessageLabel").text = message_str
				%message_container.add_child(item_template)

func _on_YesButton_pressed():
	emit_signal("click_yes")
	queue_free()


func _on_NoButton_pressed():
	emit_signal("click_no")
	queue_free()
