extends Node

@export var model_data : ModelData

@onready var turner = %Turner
@onready var model_holder = %ModelHolder
signal change_relative_postion
signal active_model
signal inactive_model
var current_model : Node3D = null

func _ready():
	model_data.scene = load(model_data.scene_path)
	set_model(model_data)
	
func set_model(model_data : ModelData):
	# Check if a model is already displayed
	if current_model != null:
		# Purge Model Holder
		for child in model_holder.get_children():
			child.queue_free()
		await get_tree().process_frame
		
	# Set the new current model node
	current_model = model_data.scene.instantiate()
	# Set a model wrapper and put the model in it
	var base_scale = Vector3.ONE * model_data.scale_compensation
	var wrapper = Node3D.new()
	wrapper.position.y = model_data.y_offset
	wrapper.scale = base_scale * 0.8
	wrapper.add_child(current_model)
	model_holder.add_child(wrapper)
	
	var t = create_tween().set_parallel(true)
	t.tween_property(turner, "position:y", model_data.camera_offset_y, 0.2)
	t.tween_property(wrapper, "scale", base_scale, 0.2)
	# Set animations
	idle()
	
func idle():
	if current_model:
		current_model.idle()

func walk():
	if current_model:
		current_model.walk()
		
func jump():
	if current_model:
		current_model.jump()

func fall():
	if current_model:
		current_model.fall()

func set_face(face_name):
	if current_model:
		current_model.set_face(face_name)
		
func set_walk_run_blending(value:float):
	if current_model:
		current_model.walk_run_blending = value


func _on_turner_change_relative_postion(relative_postion):
	emit_signal("change_relative_postion",relative_postion)


func _on_turner_active_model():
	emit_signal("active_model")
	pass # Replace with function body.


func _on_turner_inactive_model():
	emit_signal("inactive_model")
