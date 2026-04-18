class_name Tank extends CharacterBody3D

@export var controller: PackedScene = null
@export var turn_speed_degrees: float = 1.0
@export var aim_speed_degrees: float = 20.0
@export var max_force_newtons: float = 10.0
@export var drag_coefficient: float = 1.0
@export var mass_kg: float = 1.0
@onready var turret: Node3D = $Turret
@onready var muzzle: Node3D = $Turret/Muzzle
@onready var _target: Basis = basis
@onready var _turret_target: Basis = turret.basis
var _controller: Controller = null
var _throttle: float = 0.0

func _ready() -> void:
	if controller:
		_controller = controller.instantiate()
		add_child(_controller)

func set_target(direction: Vector3) -> void:
	assert(not direction.is_zero_approx() and direction.is_normalized())
	_target = Basis.looking_at(direction, Vector3.UP)

func set_turret_target(target_position: Vector3) -> void:
	var direction: Vector3 = target_position - turret.global_position
	if direction.is_zero_approx():
		return
	direction = direction.normalized()
	_turret_target = Basis.looking_at(direction, Vector3.UP)

func set_throttle(throttle: float) -> void:
	assert(throttle >= -1 and throttle <= 1)
	_throttle = throttle

func _physics_process(delta: float) -> void:
	global_basis = global_basis.slerp(_target, turn_speed_degrees * delta)
	turret.global_basis = turret.global_basis.slerp(_turret_target, aim_speed_degrees * delta)
	velocity += -global_basis.z * (max_force_newtons * _throttle) / mass_kg * delta
	move_and_slide()
	velocity *= 1.0 - drag_coefficient * delta
	_throttle = 0.0
