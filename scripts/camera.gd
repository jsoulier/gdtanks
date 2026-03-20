extends Camera3D

@export var speed: float = 10.0
@export var sensitivity: float = 0.001

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _input(event: InputEvent) -> void:
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseMotion:
			rotate_y(-event.relative.x * sensitivity)
			rotate_object_local(Vector3.RIGHT, -event.relative.y * sensitivity)
	if event is InputEventMouseButton:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed(&"unfocus"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _process(delta: float) -> void:
	if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
		return
	var direction := Vector3.ZERO
	direction.x += float(Input.is_action_pressed(&"right"))
	direction.x -= float(Input.is_action_pressed(&"left"))
	direction.z += float(Input.is_action_pressed(&"backwards"))
	direction.z -= float(Input.is_action_pressed(&"forwards"))
	direction.y += float(Input.is_action_pressed(&"up"))
	direction.y -= float(Input.is_action_pressed(&"down"))
	direction = (global_transform.basis * direction).normalized()
	position += direction * speed * delta
