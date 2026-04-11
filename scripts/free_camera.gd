class_name FreeCamera extends Controller

@export var move_speed: float = 10.0
@export var move_speed_min: float = 0.1
@export var move_speed_max: float = 500.0
@export var move_smoothing: float = 10.0
@export var move_sensitivity: float = 1.2
@export var sensitivity: float = 0.2
@onready var _camera: Camera3D = $Camera3D
var _velocity: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _pitch: float = 0.0
var _captured: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and _captured:
		_yaw -= event.relative.x * sensitivity
		_pitch -= event.relative.y * sensitivity
		_pitch = clamp(_pitch, -89.0, 89.0)
		rotation_degrees = Vector3(_pitch, _yaw, 0.0)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_capture_mouse()
			MOUSE_BUTTON_WHEEL_UP:
				if _captured:
					move_speed = clamp(move_speed * move_sensitivity, move_speed_min, move_speed_max)
			MOUSE_BUTTON_WHEEL_DOWN:
				if _captured:
					move_speed = clamp(move_speed / move_sensitivity, move_speed_min, move_speed_max)
	if event is InputEventKey:
		if event.keycode == KEY_ESCAPE and event.pressed:
			_release_mouse()

func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_captured = true

func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_captured = false

func _process(delta: float) -> void:
	var direction: Vector3 = Vector3.ZERO
	if Input.is_action_pressed(&"forwards"):
		direction -= global_transform.basis.z
	if Input.is_action_pressed(&"backwards"):
		direction += global_transform.basis.z
	if Input.is_action_pressed(&"left"):
		direction -= global_transform.basis.x
	if Input.is_action_pressed(&"right"):
		direction += global_transform.basis.x
	if Input.is_action_pressed(&"up"):
		direction += Vector3.UP
	if Input.is_action_pressed(&"down"):
		direction -= Vector3.UP
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
	_velocity = _velocity.lerp(direction * move_speed, move_smoothing * delta)
	global_position += _velocity * delta

func _get_buffer(proj: Projection) -> PackedFloat32Array:
	var buffer: PackedFloat32Array = PackedFloat32Array()
	buffer.resize(16)
	var columns: Array[Vector4] = [proj.x, proj.y, proj.z, proj.w]
	for column in 4:
		buffer[column * 4 + 0] = columns[column].x
		buffer[column * 4 + 1] = columns[column].y
		buffer[column * 4 + 2] = columns[column].z
		buffer[column * 4 + 3] = columns[column].w
	return buffer

func get_view_matrix() -> Projection:
	return Projection(global_transform.inverse())

func get_proj_matrix() -> Projection:
	return _camera.get_camera_projection()

func get_view_proj_matrix() -> Projection:
	return get_proj_matrix() * get_view_matrix()

func get_inv_view_matrix() -> Projection:
	return Projection(global_transform)

func get_inv_proj_matrix() -> Projection:
	return _camera.get_camera_projection().inverse()

func get_view_buffer() -> PackedFloat32Array:
	return _get_buffer(get_view_matrix())

func get_proj_buffer() -> PackedFloat32Array:
	return _get_buffer(get_proj_matrix())

func get_view_proj_buffer() -> PackedFloat32Array:
	return _get_buffer(get_view_proj_matrix())

func get_inv_view_buffer() -> PackedFloat32Array:
	return _get_buffer(get_inv_view_matrix())

func get_inv_proj_buffer() -> PackedFloat32Array:
	return _get_buffer(get_inv_proj_matrix())
