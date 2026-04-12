class_name Camera extends Controller

static var CONTROLLERS: Array[GDScript] = [
	preload("res://scripts/free_camera.gd"),
	preload("res://scripts/tank_camera.gd"),
]

@onready var _camera: Camera3D = $Camera3D
var _controller: CameraController = null
var _controller_index: int = 0
var _captured: bool = false

func _ready() -> void:
	_change_camera()

func _change_camera():
	_controller = CONTROLLERS[_controller_index].new()
	_controller.node = self
	_controller_index = (_controller_index + 1) % CONTROLLERS.size()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_LEFT:
				if event.pressed:
					_capture_mouse()
	if event is InputEventKey:
		if event.is_action_pressed(&"unfocus"):
			_release_mouse()
		if event.is_action_pressed(&"change_camera"):
			_change_camera()
	if _captured and _controller:
		_controller.input(event)

func _process(delta: float) -> void:
	if _captured and _controller:
		_controller.process(delta)

func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_captured = true

func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_captured = false

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
