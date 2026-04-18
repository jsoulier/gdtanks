class_name PlayerControllerFreeImpl extends PlayerControllerImpl

@export var move_speed: float = 10.0
@export var move_speed_min: float = 0.1
@export var move_speed_max: float = 500.0
@export var move_smoothing: float = 10.0
@export var move_sensitivity: float = 1.2
@export var sensitivity: float = 0.2
var _velocity: Vector3 = Vector3.ZERO
var _yaw: float = 0.0
var _pitch: float = 0.0

func input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * sensitivity
		_pitch -= event.relative.y * sensitivity
		_pitch = clamp(_pitch, -89.0, 89.0)
		controller.rotation_degrees = Vector3(_pitch, _yaw, 0.0)
	if event is InputEventMouseButton:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				move_speed = clamp(move_speed * move_sensitivity, move_speed_min, move_speed_max)
			MOUSE_BUTTON_WHEEL_DOWN:
				move_speed = clamp(move_speed / move_sensitivity, move_speed_min, move_speed_max)

func process(delta: float) -> void:
	var direction: Vector3 = Vector3.ZERO
	if Input.is_action_pressed(&"forwards"):
		direction -= controller.global_transform.basis.z
	if Input.is_action_pressed(&"backwards"):
		direction += controller.global_transform.basis.z
	if Input.is_action_pressed(&"left"):
		direction -= controller.global_transform.basis.x
	if Input.is_action_pressed(&"right"):
		direction += controller.global_transform.basis.x
	if Input.is_action_pressed(&"up"):
		direction += Vector3.UP
	if Input.is_action_pressed(&"down"):
		direction -= Vector3.UP
	if direction.length_squared() > 0.0:
		direction = direction.normalized()
	_velocity = _velocity.lerp(direction * move_speed, move_smoothing * delta)
	controller.global_position += _velocity * delta
	controller.camera_crosshair.visible = false
	controller.muzzle_crosshair.visible = false
