class_name Projectile extends RigidBody3D

func shoot(muzzle_velocity: float) -> void:
	linear_velocity = -global_basis.z * muzzle_velocity
