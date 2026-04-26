class_name Tank extends CharacterBody3D

static var PROJECTILE: PackedScene = preload("res://scenes/projectile.tscn")

@export var controller: PackedScene = null
@export var turn_speed: float = 1.0
@export var aim_speed: float = 25.0
@export var max_force: float = 100.0
@export var drag_coefficient: float = 10.0
@export var mass: float = 1.0
@export var shoot_cooldown: float = 1.0
@onready var _front_mesh_instance: MeshInstance3D = $FrontMeshInstance3D
@onready var _back_mesh_instance: MeshInstance3D = $BackMeshInstance3D
@onready var _turret_mesh_instance: MeshInstance3D = $Turret/TurretMeshInstance3D
@onready var _barrel_mesh_instance: MeshInstance3D = $Turret/BarrelMeshInstance3D
@onready var _muzzle_particles: GPUParticles3D = $Turret/Muzzle/GPUParticles3D
@onready var turret: Node3D = $Turret
@onready var muzzle: Node3D = $Turret/Muzzle
@onready var _target: Basis = basis
@onready var _turret_target: Basis = turret.basis
var _level: Level = null
var _controller: Controller = null
var _throttle: float = 0.0
var _shoot_delay: float = 0.0

func _ready() -> void:
	assert(controller)
	_controller = controller.instantiate()
	add_child(_controller)
	for level in get_tree().get_nodes_in_group(&"levels"):
		assert(not _level)
		_level = level
	var color: Vector3 = _controller.get_color()
	_front_mesh_instance.set_instance_shader_parameter("color", color)
	_back_mesh_instance.set_instance_shader_parameter("color", color)
	_turret_mesh_instance.set_instance_shader_parameter("color", color)
	_barrel_mesh_instance.set_instance_shader_parameter("color", color)
	_muzzle_particles.set_instance_shader_parameter("color", color)
	
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
	global_basis = global_basis.slerp(_target, turn_speed * delta)
	turret.global_basis = turret.global_basis.slerp(_turret_target, aim_speed * delta)
	velocity += -global_basis.z * (max_force * _throttle) / mass * delta
	move_and_slide()
	velocity *= 1.0 - drag_coefficient * delta
	_throttle = 0.0

func shoot(muzzle_velocity: float) -> void:
	var seconds: float = Time.get_ticks_msec() / 1000
	if _shoot_delay > seconds:
		return
	_shoot_delay = seconds + shoot_cooldown
	var projectile: Projectile = PROJECTILE.instantiate()
	_level.add_child(projectile)
	projectile.global_transform = muzzle.global_transform
	projectile.shoot(muzzle_velocity, _controller.get_color())
	_muzzle_particles.restart()
	_level.svo.compute_reachability(projectile.global_position, projectile.linear_velocity)
