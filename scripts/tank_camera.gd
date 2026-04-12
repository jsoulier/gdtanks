class_name TankCamera extends CameraController

func input(_event: InputEvent) -> void:
	pass

func process(_delta: float) -> void:
	node.global_position = node.tank.camera.global_position
