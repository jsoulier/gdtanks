extends Camera3D

@export var walk_speed   : float = 10.0
@export var sprint_speed : float = 100.0
@export var rotate_speed : float = 0.001

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * rotate_speed)
			rotate_object_local(Vector3.RIGHT, -event.relative.y * rotate_speed)

	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if event.is_action_pressed(&"unfocus"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return

	var direction := Vector3.ZERO
	if Input.is_action_pressed(&"right"):   direction.x += 1
	if Input.is_action_pressed(&"left"):    direction.x -= 1
	if Input.is_action_pressed(&"back"):    direction.z += 1
	if Input.is_action_pressed(&"forward"): direction.z -= 1
	if Input.is_action_pressed(&"up"):    direction.y += 1
	if Input.is_action_pressed(&"down"):  direction.y -= 1

	var speed := sprint_speed if Input.is_action_pressed(&"sprint") else walk_speed
	direction = (global_transform.basis * direction).normalized()
	position += direction * speed * delta
