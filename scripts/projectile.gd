class_name Projectile extends RigidBody3D

@onready var _explosion_particles: GPUParticles3D = $ExplosionGPUParticles3D
var _level: Level = null

func _ready() -> void:
	for level in get_tree().get_nodes_in_group(&"levels"):
		assert(not _level)
		_level = level

func shoot(muzzle_velocity: float) -> void:
	linear_velocity = -global_basis.z * muzzle_velocity

func _on_body_entered(_body: Node) -> void:
	remove_child(_explosion_particles)
	_level.add_child(_explosion_particles)
	_explosion_particles.global_position = global_position
	_explosion_particles.restart()
	visible = false
	freeze = true
	await get_tree().create_timer(_explosion_particles.lifetime).timeout
	queue_free()
	_explosion_particles.queue_free()

func _physics_process(_delta: float) -> void:
	if not linear_velocity.is_zero_approx():
		look_at(global_position + linear_velocity)
