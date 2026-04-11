class_name Tank extends CharacterBody3D

@export var controller: PackedScene = null
var _controller: Controller = null

func _ready() -> void:
	assert(controller)
	_controller = controller.instantiate()
	add_child(_controller)
