@tool class_name SVO extends Node3D

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		var palette = EditorInterface.get_command_palette()
		palette.add_command("SVO: build", "svo/build", _write)

func _exit_tree() -> void:
	if Engine.is_editor_hint():
		var palette = EditorInterface.get_command_palette()
		palette.remove_command("svo/build")

# https://fileadmin.cs.lth.se/cs/Personal/Tomas_Akenine-Moller/code/tribox_tam.pdf
class Triangle:
	var v0: Vector3
	var v1: Vector3
	var v2: Vector3
	var aabb: AABB

	func _init(in_v0: Vector3, in_v1: Vector3, in_v2: Vector3):
		v0 = in_v0
		v1 = in_v1
		v2 = in_v2
		var min_position = v0.min(v1).min(v2)
		var max_position = v0.max(v1).max(v2)
		aabb = AABB(min_position, max_position - min_position)

	func intersects(_aabb: AABB) -> bool:
		if not aabb.intersects(_aabb):
			return false
		var half = _aabb.size * 0.5
		var center = _aabb.get_center()
		var a = v0 - center
		var b = v1 - center
		var c = v2 - center
		var e0 = b - a
		var e1 = c - b
		var e2 = a - c
		if !_separates(a, b, c, half, Vector3(1, 0, 0)):
			return false
		if !_separates(a, b, c, half, Vector3(0, 1, 0)):
			return false
		if !_separates(a, b, c, half, Vector3(0, 0, 1)):
			return false
		if !_separates(a, b, c, half, Vector3(0, -e0.z, e0.y)):
			return false
		if !_separates(a, b, c, half, Vector3(0, -e1.z, e1.y)):
			return false
		if !_separates(a, b, c, half, Vector3(0, -e2.z, e2.y)):
			return false
		if !_separates(a, b, c, half, Vector3(e0.z, 0, -e0.x)):
			return false
		if !_separates(a, b, c, half, Vector3(e1.z, 0, -e1.x)):
			return false
		if !_separates(a, b, c, half, Vector3(e2.z, 0, -e2.x)):
			return false
		if !_separates(a, b, c, half, Vector3(-e0.y, e0.x, 0)):
			return false
		if !_separates(a, b, c, half, Vector3(-e1.y, e1.x, 0)):
			return false
		if !_separates(a, b, c, half, Vector3(-e2.y, e2.x, 0)):
			return false
		if !_separates(a, b, c, half, e0.cross(c - a)):
			return false
		return true

	func _separates(in_v0: Vector3, in_v1: Vector3, in_v2: Vector3, half: Vector3, axis: Vector3) -> bool:
		if is_zero_approx(axis.length_squared()):
			return true
		var p0 = in_v0.dot(axis)
		var p1 = in_v1.dot(axis)
		var p2 = in_v2.dot(axis)
		var radius = half.x * abs(axis.x) + half.y * abs(axis.y) + half.z * abs(axis.z)
		var min_projection = min(p0, min(p1, p2))
		var max_projection = max(p0, max(p1, p2))
		return min_projection <= radius and max_projection >= -radius

const EMPTY: int = -1
const SOLID: int = -2

func _new_node(nodes: Array) -> int:
	var index: int = nodes.size()
	nodes.append([EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY])
	return index

@export var scene: Node3D = null
@export var excludes: Array[PackedScene] = []
@export_range(1, 10) var max_depth: int = 5
@export_range(1, 10) var debug_depth: int = max_depth
@export_range(0.0, 60.0) var debug_duration: float = 20.0
@export var debug_draw_nodes: bool = false
@export var debug_draw_queries: bool = false
@export_dir var out_directory: String = "res://data/"

var _nodes: PackedInt64Array
var _node_count: int = 0
var _position: Vector3 = Vector3.ZERO
var _size: float = 0.0
var _min_voxel_size: float = 0.0
var _max_depth: int = 0
var _debug_lines: Array = []
var _debug_depths: Array = []

func _ready() -> void:
	_read()

func _process(_delta: float) -> void:
	if not debug_draw_nodes:
		return
	for i in range(_debug_depths.size()):
		var _depth: int = _debug_depths[i]
		if _depth == debug_depth - 1:
			DebugDraw3D.draw_lines(_debug_lines[i], Color.YELLOW)

func _write() -> void:
	print("Building SVO for %s" % scene.name)
	var triangles: Array[Triangle] = []
	_get_triangles(scene, triangles)
	if triangles.is_empty():
		push_error("No triangles found in scene")
		return
	print("Got %d triangles" % triangles.size())
	var scene_min: Vector3 = Vector3(INF, INF, INF)
	var scene_max: Vector3 = Vector3(-INF, -INF, -INF)
	for triangle in triangles:
		scene_min = scene_min.min(triangle.aabb.position)
		scene_max = scene_max.max(triangle.aabb.end)
	# Technically correct but outer surface collisions aren't required anyways
	# var offsets: Vector3 = Vector3(1.0, 1.0, 1.0)
	# scene_min -= offsets
	# scene_max += offsets
	var extents = scene_max - scene_min
	_size = maxf(extents.x, maxf(extents.y, extents.z))
	_position = scene_min
	var nodes: Array = []
	_new_node(nodes)
	_subdivide(nodes, triangles, 0, _position, _size, 0)
	print("Got %d nodes" % nodes.size())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_directory))
	_write_nodes(nodes)
	_write_metadata(nodes)
	if Engine.is_editor_hint():
		EditorInterface.get_resource_filesystem().scan()
	print("Built SVO for %s" % scene.name)
	_read()

func _read() -> void:
	_nodes = read_nodes()
	var metadata: Dictionary = _read_metadata()
	_node_count = metadata.node_count
	_position = Vector3(metadata.position_x, metadata.position_y, metadata.position_z)
	_size = metadata.size
	_min_voxel_size = _size / pow(2.0, max_depth)
	_max_depth = metadata.max_depth
	_get_debug_lines()

func _get_triangles(node: Node, out: Array[Triangle]) -> void:
	for exclude: PackedScene in excludes:
		if exclude.resource_path == node.scene_file_path:
			return
	if node is MeshInstance3D and node.mesh:
		var xform: Transform3D = node.global_transform
		for i in range(node.mesh.get_surface_count()):
			var arrays = node.mesh.surface_get_arrays(i)
			var vertices = arrays[Mesh.ARRAY_VERTEX]
			var indices = arrays[Mesh.ARRAY_INDEX]
			if indices:
				for j in range(0, indices.size(), 3):
					var v0: Vector3 = vertices[indices[j + 0]]
					var v1: Vector3 = vertices[indices[j + 1]]
					var v2: Vector3 = vertices[indices[j + 2]]
					out.append(Triangle.new(xform * v0, xform * v1, xform * v2))
			else:
				for j in range(0, vertices.size(), 3):
					var v0: Vector3 = vertices[j + 0]
					var v1: Vector3 = vertices[j + 1]
					var v2: Vector3 = vertices[j + 2]
					out.append(Triangle.new(xform * v0, xform * v1, xform * v2))
	for child in node.get_children():
		_get_triangles(child, out)

func _get_child_position(in_position: Vector3, size: float, slot: int) -> Vector3:
	var x: float = in_position.x
	var y: float = in_position.y
	var z: float = in_position.z
	if slot & 1:
		x += size
	if slot & 2:
		y += size
	if slot & 4:
		z += size
	return Vector3(x, y, z)

func _subdivide(nodes: Array, in_triangles: Array[Triangle], in_index: int, in_position: Vector3, size: float, depth: int) -> void:
	var half_size: float = size * 0.5
	for child_slot in range(8):
		var child_position: Vector3 = _get_child_position(in_position, half_size, child_slot)
		var aabb: AABB = AABB(child_position, Vector3.ONE * half_size)
		var triangles: Array[Triangle] = []
		for triangle in in_triangles:
			if triangle.intersects(aabb):
				triangles.append(triangle)
		# Empty leaf
		if triangles.is_empty():
			continue
		# Solid leaf at max depth
		if depth == max_depth - 1:
			nodes[in_index][child_slot] = SOLID
			continue
		var old_node_count: int = nodes.size()
		var new_index: int = _new_node(nodes)
		nodes[in_index][child_slot] = new_index
		_subdivide(nodes, triangles, new_index, child_position, half_size, depth + 1)
		var is_solid: bool = true
		for index in nodes[new_index]:
			if index != SOLID:
				is_solid = false
				break
		# Solid leaf
		if is_solid:
			nodes[in_index][child_slot] = SOLID
			nodes.resize(old_node_count)
	
func _get_debug_lines() -> void:
	_debug_lines.clear()
	_debug_depths.clear()
	var stack: Array = [[0, _position, _size, 0]]
	while not stack.is_empty():
		var element: Array = stack.pop_back()
		var index: int = element[0]
		var location: Vector3 = element[1]
		var size: float = element[2]
		var depth: int = element[3]
		var half_size: float = size * 0.5
		for child_slot in range(8):
			var child_index: int = _nodes[index * 8 + child_slot]
			var child_position: Vector3 = _get_child_position(location, half_size, child_slot)
			if child_index == EMPTY:
				continue
			_add_debug_box(child_position, child_position + Vector3(half_size, half_size, half_size), depth)
			if child_index >= 0:
				stack.push_back([child_index, child_position, half_size, depth + 1])

func _add_debug_box(in_min: Vector3, in_max: Vector3, in_depth: int) -> void:
	var x0: float = in_min.x
	var y0: float = in_min.y
	var z0: float = in_min.z
	var x1: float = in_max.x
	var y1: float = in_max.y
	var z1: float = in_max.z
	var lines: PackedVector3Array = [
		Vector3(x0, y0, z0), Vector3(x1, y0, z0),
		Vector3(x1, y0, z0), Vector3(x1, y1, z0),
		Vector3(x1, y1, z0), Vector3(x0, y1, z0),
		Vector3(x0, y1, z0), Vector3(x0, y0, z0),
		Vector3(x0, y0, z1), Vector3(x1, y0, z1),
		Vector3(x1, y0, z1), Vector3(x1, y1, z1),
		Vector3(x1, y1, z1), Vector3(x0, y1, z1),
		Vector3(x0, y1, z1), Vector3(x0, y0, z1),
		Vector3(x0, y0, z0), Vector3(x0, y0, z1),
		Vector3(x1, y0, z0), Vector3(x1, y0, z1),
		Vector3(x1, y1, z0), Vector3(x1, y1, z1),
		Vector3(x0, y1, z0), Vector3(x0, y1, z1),
	]
	_debug_lines.append(lines)
	_debug_depths.append(in_depth)

func _write_nodes(nodes: Array) -> void:
	var path: String = ProjectSettings.globalize_path(out_directory.path_join("svo.bin"))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write to %s" % path)
		return
	for node in nodes:
		for child_index in node:
			file.store_64(child_index)
	file.close()

func read_nodes() -> PackedInt64Array:
	var path: String = out_directory.path_join("svo.bin")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open SVO nodes: %s" % path)
		return PackedInt64Array()
	var bytes: PackedByteArray = file.get_buffer(file.get_length())
	file.close()
	return bytes.to_int64_array()

func _write_metadata(nodes: Array) -> void:
	var metadata: Dictionary = {
		"node_count": nodes.size(),
		"position_x": _position.x,
		"position_y": _position.y,
		"position_z": _position.z,
		"size": _size,
		"max_depth": max_depth,
	}
	var path: String = ProjectSettings.globalize_path(out_directory.path_join("svo.json"))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write to %s" % path)
		return
	file.store_string(JSON.stringify(metadata, "\t"))
	file.close()

func _read_metadata() -> Dictionary:
	var path: String = out_directory.path_join("svo.json")
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Failed to open SVO metadata: %s" % path)
		return {}
	var metadata: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	return metadata

func compute_reachability(p: Vector3, v: Vector3) -> bool:
	var start: float = 0.0
	var midpoint: float = ProjectileMotion.time_of_apex(self, v)
	var end: float = ProjectileMotion.time_of_flight(self, v)
	return _bisect_segment(p, v, start, midpoint) and _bisect_segment(p, v, midpoint, end)

func _draw_debug_aabb(aabb: AABB, color: Color):
	if debug_draw_queries:
		DebugDraw3D.draw_aabb(aabb, color, debug_duration)

func _get_aabb(p: Vector3, v: Vector3, t0: float, t1: float) -> AABB:
	var point1: Vector3 = ProjectileMotion.displacement(self, p, v, t0)
	var point2: Vector3 = ProjectileMotion.displacement(self, p, v, t1)
	return AABB(point1.min(point2), point1.max(point2) - point1.min(point2))

func _bisect_segment(p: Vector3, v: Vector3, t0: float, t1: float) -> bool:
	var aabb: AABB = _get_aabb(p, v, t0, t1)
	if aabb.get_longest_axis_size() < _min_voxel_size:
		if debug_draw_queries:
			DebugDraw3D.draw_sphere(aabb.get_center(), 1.0, Color.RED, debug_duration)
		return false
	var hit: bool = not _check_aabb(aabb, 0, _position, _size)
	if not hit:
		return true
	elif debug_draw_queries:
		DebugDraw3D.draw_aabb(aabb, Color.ORANGE, debug_duration)
	var midpoint: float = (t0 + t1) * 0.5
	return _bisect_segment(p, v, t0, midpoint) and _bisect_segment(p, v, midpoint, t1)

func _check_aabb(curve_aabb: AABB, node_index: int, node_position: Vector3, node_size: float) -> bool:
	var node_aabb: AABB = AABB(node_position, Vector3.ONE * node_size)
	if not curve_aabb.intersects(node_aabb):
		return true
	var half_size: float = node_size * 0.5
	for child_slot in range(8):
		var child_index: int = _nodes[node_index * 8 + child_slot]
		if child_index == EMPTY:
			continue
		var child_position: Vector3 = _get_child_position(node_position, half_size, child_slot)
		var child_aabb: AABB = AABB(child_position, Vector3.ONE * half_size)
		if not curve_aabb.intersects(child_aabb):
			continue
		if child_index == SOLID:
			return false
		if not _check_aabb(curve_aabb, child_index, child_position, half_size):
			return false
	return true
