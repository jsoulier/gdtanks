class_name PlayerControllerTankImpl extends PlayerControllerImpl

@export var sensitivity: float = 0.2
var _yaw: float = 0.0
var _pitch: float = 0.0

func input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_yaw -= event.relative.x * sensitivity
		_pitch -= event.relative.y * sensitivity
		_pitch = clamp(_pitch, -89.0, 89.0)
		controller.rotation_degrees = Vector3(_pitch, _yaw, 0.0)

func process(_delta: float) -> void:
	var throttle: float = 0.0
	var yaw: float = 0.0
	if Input.is_action_pressed(&"forwards"):
		throttle += 1
	if Input.is_action_pressed(&"backwards"):
		throttle -= 1
	if Input.is_action_pressed(&"left"):
		yaw -= 1
	if Input.is_action_pressed(&"right"):
		yaw += 1
	controller.global_position = controller.tank.global_position
	controller.muzzle_raycast.global_transform = controller.tank.muzzle.global_transform
	controller.tank.set_target(-controller.tank.global_basis.z.rotated(Vector3.UP, yaw))
	controller.tank.set_throttle(throttle)
	var camera_collision: bool = controller.camera_raycast.is_colliding()
	var muzzle_collision: bool = controller.muzzle_raycast.is_colliding()
	if camera_collision:
		var collision_point: Vector3 = controller.camera_raycast.get_collision_point()
		controller.tank.set_turret_target(collision_point)
	controller.camera_crosshair.visible = true
	var viewport_size = controller.get_viewport().get_visible_rect().size
	controller.camera_crosshair.position = viewport_size / 2.0 - controller.camera_crosshair.size / 2.0
	controller.muzzle_crosshair.visible = muzzle_collision
	if muzzle_collision:
		var collision_point: Vector3 = controller.muzzle_raycast.get_collision_point()
		var screen_position: Vector2 = controller.camera.unproject_position(collision_point)
		controller.muzzle_crosshair.position = screen_position - controller.muzzle_crosshair.size / 2.0
