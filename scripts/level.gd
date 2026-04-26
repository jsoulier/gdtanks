class_name Level extends Node3D

@onready var svo: SVO = $SVO
@onready var _collision: CollisionShape3D = $NavigationRegion3D/Level/CSGBakedCollisionShape3D

func _ready() -> void:
	var shape: ConcavePolygonShape3D = _collision.shape
	assert(shape.backface_collision)
