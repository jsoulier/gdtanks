class_name Tank extends CharacterBody3D

@export var controller: PackedScene = null
@onready var _turret: Node3D = $Turret
@onready var _barrel: Node3D = $Turret/Barrel
@onready var _muzzle: Node3D = $Turret/Barrel/Muzzle
@onready var camera: Node3D = $Camera
var _controller: Controller = null

func _ready() -> void:
	if controller:
		_controller = controller.instantiate()
		add_child(_controller)
