extends Node3D
signal change_relative_postion
signal active_model
signal inactive_model
@export var low_angle : float = -5.0
@export var high_angle : float = -50.0
@export var min_zoom : float = 1.5
@export var max_zoom : float = 5.0
const RAY_LENGTH = 1000.0
@onready var _camera = $Camera3D
var _left_is_grabbing = false
var _right_is_grabbing = false

func _ready():
	_set_bg_ratio()
	get_viewport().connect("size_changed", _set_bg_ratio)
	
	
func _set_bg_ratio():
	var background_plane : MeshInstance3D = $BackgroundPlane
	var frustum_height = tan(_camera.fov * PI / 180 * 0.5) * (_camera.position.z - background_plane.position.z) * 2
	var viewport_size = get_viewport().size
	var ratio = float(viewport_size.x) / float(viewport_size.y)

	background_plane.mesh.size.x = frustum_height * ratio
	background_plane.mesh.size.y = frustum_height
	background_plane.material_override.set_shader_parameter("ratio", Vector2(ratio, 1.0))

var ray_result = null
func check_ray():
	var space_state = get_world_3d().direct_space_state
	var cam = _camera
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true

	var result = space_state.intersect_ray(query)
	ray_result = result


func _physics_process(delta):
	check_ray()

func _unhandled_input(event):
	var wheel_direction = 0.0
	if (event is InputEventMouseButton): 
		if event.button_index == MOUSE_BUTTON_LEFT: _left_is_grabbing = (ray_result and event.pressed)
		if event.button_index == MOUSE_BUTTON_RIGHT: _right_is_grabbing = (ray_result and event.pressed)
		
		if ray_result and event.pressed:
			var wheel_up = event.button_index == MOUSE_BUTTON_WHEEL_UP
			var wheel_down = event.button_index == MOUSE_BUTTON_WHEEL_DOWN
			wheel_direction = float(wheel_down) - float(wheel_up)
		
		if _left_is_grabbing and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
			emit_signal("active_model")
		if _right_is_grabbing and event.double_click and event.button_index == MOUSE_BUTTON_RIGHT:
			emit_signal("inactive_model")
		
	if wheel_direction != 0:
		_camera.position.z += wheel_direction * 0.25
		_camera.position.z = clamp(_camera.position.z, min_zoom, max_zoom)
		_set_bg_ratio()
	
	if (event is InputEventMouseMotion):
		if _right_is_grabbing:
			rotation.y += -event.relative.x * 0.005
			rotation.x += -event.relative.y * 0.005
			rotation.x = clamp(rotation.x, deg_to_rad(high_angle), deg_to_rad(low_angle))
		if _left_is_grabbing:
			emit_signal("change_relative_postion",event.relative)
		
		
