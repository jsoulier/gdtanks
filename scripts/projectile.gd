class_name Projectile extends RigidBody3D

@onready var _body_mesh_instance: MeshInstance3D = $BodyMeshInstance3D
@onready var _tip_mesh_instance: MeshInstance3D = $TipMeshInstance3D
@onready var _explosion_particles: GPUParticles3D = $ExplosionGPUParticles3D
@onready var _trail_particles: GPUParticles3D = $TrailGPUParticles3D
var _level: Level = null

func _ready() -> void:
	for level in get_tree().get_nodes_in_group(&"levels"):
		assert(not _level)
		_level = level

func shoot(muzzle_velocity: float, color: Vector3) -> void:
	linear_velocity = -global_basis.z * muzzle_velocity
	_body_mesh_instance.set_instance_shader_parameter(&"color", color)
	_tip_mesh_instance.set_instance_shader_parameter(&"color", color)
	_explosion_particles.set_instance_shader_parameter(&"color", color)
	_trail_particles.set_instance_shader_parameter(&"color", color)

func _on_body_entered(_body: Node) -> void:
	remove_child(_explosion_particles)
	_level.add_child(_explosion_particles)
	_explosion_particles.global_position = global_position
	_explosion_particles.restart()
	visible = false
	freeze = true
	var lifetime: float = _explosion_particles.lifetime
	var time: float = 0.0
	while time < lifetime:
		time += get_process_delta_time()
		_explosion_particles.set_instance_shader_parameter("lifetime", time / lifetime)
		await get_tree().process_frame
	queue_free()
	_explosion_particles.queue_free()

func _physics_process(_delta: float) -> void:
	if not linear_velocity.is_zero_approx():
		look_at(global_position + linear_velocity.normalized())
