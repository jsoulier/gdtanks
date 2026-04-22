# https://en.wikipedia.org/wiki/Projectile_motion
class_name ProjectileMotion extends Object

static func _gravity(node: Node3D) -> float:
	return PhysicsServer3D.area_get_param(node.get_world_3d().space, PhysicsServer3D.AREA_PARAM_GRAVITY)

static func displacement(node: Node3D, p: Vector3, v: Vector3, t: float) -> Vector3:
	return Vector3(p.x + v.x * t, p.y + v.y * t - 0.5 * _gravity(node) * t * t, p.z + v.z * t)

static func velocity(node: Node3D, v: Vector3, t: float) -> Vector3:
	return Vector3(v.x, v.y - _gravity(node) * t, v.z)

static func time_of_flight(node: Node3D, v: Vector3) -> float:
	return (2.0 * v.y) / _gravity(node)

static func time_of_apex(node: Node3D, v: Vector3) -> float:
	return v.y / _gravity(node)

static func max_height(node: Node3D, v: Vector3) -> float:
	return (v.y * v.y) / (2.0 * _gravity(node))
