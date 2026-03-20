@tool
extends Node3D
## SVOBuilder
##
## Add this node anywhere in your scene. Configure the export vars in the
## Inspector, then click "Build SVO" to voxelize the scene and write the
## output files. Works in-editor via @tool.
##
## Output (written to output_dir):
##   svo_nodes.bin   — flat binary: 8 × int32 per node (children[0..7])
##   svo_meta.json   — root AABB + depth + node count

@export_group("Scope")
## Root node to voxelize. Leave empty to use the edited scene root.
@export var scan_root      : Node3D            = null
## Only voxelize nodes in these groups. Leave empty to include everything.
@export var include_groups : Array[StringName] = []
## Skip nodes in these groups entirely.
@export var exclude_groups : Array[StringName] = []

@export_group("SVO Settings")
## Octree depth. Voxel grid = 2^max_depth per axis.
## Depth 6 = 64³, depth 7 = 128³, depth 8 = 256³.
@export_range(1, 12) var max_depth : int = 7

@export_group("Output")
@export_dir var output_dir : String = "res://svo/"

@export_group("Build")
@export var build : bool = false :
	set(v):
		if v and Engine.is_editor_hint():
			build = false
			_run_build()


# ---------------------------------------------------------------------------
# Internal state — cleared before each build
# ---------------------------------------------------------------------------
var _nodes     : Array   = []
var _root_min  : Vector3 = Vector3.ZERO
var _root_size : float   = 1.0


# ---------------------------------------------------------------------------
# Build entry point
# ---------------------------------------------------------------------------
func _run_build() -> void:
	var root := scan_root if scan_root != null else get_tree().edited_scene_root as Node3D
	if root == null:
		push_error("SVOBuilder: no root node found.")
		return

	print("SVOBuilder: scanning from '%s'..." % root.name)

	var triangles : Array = []
	_collect_triangles(root, Transform3D.IDENTITY, triangles)

	if triangles.is_empty():
		push_error("SVOBuilder: no mesh geometry found under '%s'." % root.name)
		return

	print("SVOBuilder: %d triangles collected." % triangles.size())

	var scene_min := Vector3(INF, INF, INF)
	var scene_max := Vector3(-INF, -INF, -INF)
	for tri in triangles:
		for v : Vector3 in tri:
			scene_min = scene_min.min(v)
			scene_max = scene_max.max(v)

	var pad       := (scene_max - scene_min) * 0.005 + Vector3.ONE * 0.001
	scene_min     -= pad
	scene_max     += pad
	var extents   := scene_max - scene_min
	var cube_side := maxf(extents.x, maxf(extents.y, extents.z))
	_root_min  = scene_min
	_root_size = cube_side

	_nodes.clear()
	_new_node()  # node 0 = root

	var built := 0
	for tri in triangles:
		_insert_triangle(tri, 0, _root_min, _root_size, 0)
		built += 1
		if built % 500 == 0:
			print("  ...%d / %d triangles, %d nodes so far" \
				  % [built, triangles.size(), _nodes.size()])

	print("SVOBuilder: %d nodes (max_depth=%d, grid=%d³)." \
		  % [_nodes.size(), max_depth, 1 << max_depth])

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output_dir))
	_export_bin()
	_export_meta()

	EditorInterface.get_resource_filesystem().scan()
	print("SVOBuilder: done — %s" % output_dir)


# ---------------------------------------------------------------------------
# Geometry collection
# ---------------------------------------------------------------------------
func _should_include(node: Node) -> bool:
	for g in exclude_groups:
		if node.is_in_group(g): return false
	if not include_groups.is_empty():
		for g in include_groups:
			if node.is_in_group(g): return true
		return false
	return true


func _collect_triangles(node: Node, parent_xform: Transform3D, out: Array) -> void:
	var xform := parent_xform
	if node is Node3D:
		xform = parent_xform * (node as Node3D).transform

	if node is MeshInstance3D and _should_include(node):
		var mesh : Mesh = (node as MeshInstance3D).mesh
		if mesh:
			for s in range(mesh.get_surface_count()):
				var arrays := mesh.surface_get_arrays(s)
				if arrays.is_empty():
					continue
				var verts   : PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
				var indices                      = arrays[Mesh.ARRAY_INDEX]
				if indices == null or indices.is_empty():
					for i in range(0, verts.size() - 2, 3):
						out.append([xform * verts[i],
									xform * verts[i + 1],
									xform * verts[i + 2]])
				else:
					for i in range(0, indices.size() - 2, 3):
						out.append([xform * verts[indices[i]],
									xform * verts[indices[i + 1]],
									xform * verts[indices[i + 2]]])

	for child in node.get_children():
		_collect_triangles(child, xform, out)


# ---------------------------------------------------------------------------
# SVO construction
# ---------------------------------------------------------------------------
func _new_node() -> int:
	var idx := _nodes.size()
	_nodes.append([-1, -1, -1, -1, -1, -1, -1, -1])
	return idx


func _insert_triangle(tri: Array, node_idx: int,
					  node_min: Vector3, node_size: float, depth: int) -> void:
	var half := node_size * 0.5

	if depth == max_depth - 1:
		for ci in range(8):
			var cmin := node_min + Vector3(
				half if (ci & 1) else 0.0,
				half if (ci & 2) else 0.0,
				half if (ci & 4) else 0.0)
			if _tri_overlaps_aabb(tri, cmin, cmin + Vector3(half, half, half)):
				_nodes[node_idx][ci] = -2
		return

	for ci in range(8):
		var cmin := node_min + Vector3(
			half if (ci & 1) else 0.0,
			half if (ci & 2) else 0.0,
			half if (ci & 4) else 0.0)
		var cmax := cmin + Vector3(half, half, half)

		if not _tri_overlaps_aabb(tri, cmin, cmax):
			continue

		var child_val : int = _nodes[node_idx][ci]
		if child_val == -2:
			continue
		if child_val == -1:
			child_val = _new_node()
			_nodes[node_idx][ci] = child_val

		_insert_triangle(tri, child_val, cmin, half, depth + 1)

		if _all_children_solid(child_val):
			_nodes[node_idx][ci] = -2


func _all_children_solid(node_idx: int) -> bool:
	for v in _nodes[node_idx]:
		if v != -2: return false
	return true


func _tri_overlaps_aabb(tri: Array, box_min: Vector3, box_max: Vector3) -> bool:
	var v0 : Vector3 = tri[0]
	var v1 : Vector3 = tri[1]
	var v2 : Vector3 = tri[2]

	var tmin := v0.min(v1).min(v2)
	var tmax := v0.max(v1).max(v2)
	if tmin.x > box_max.x or tmax.x < box_min.x: return false
	if tmin.y > box_max.y or tmax.y < box_min.y: return false
	if tmin.z > box_max.z or tmax.z < box_min.z: return false

	var center := (box_min + box_max) * 0.5
	var half   := (box_max - box_min) * 0.5
	var normal := (v1 - v0).cross(v2 - v0)
	var d      := normal.dot(v0)
	var r      := half.x * absf(normal.x) + half.y * absf(normal.y) + half.z * absf(normal.z)
	if absf(normal.dot(center) - d) > r: return false

	var edges     := [v1 - v0, v2 - v1, v0 - v2]
	var aabb_axes := [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
	for te : Vector3 in edges:
		for ae : Vector3 in aabb_axes:
			var axis := te.cross(ae)
			if axis.length_squared() < 1e-10:
				continue
			var p0   := axis.dot(v0); var p1 := axis.dot(v1); var p2 := axis.dot(v2)
			var pmin := minf(p0, minf(p1, p2))
			var pmax := maxf(p0, maxf(p1, p2))
			var pr   := half.x * absf(axis.x) + half.y * absf(axis.y) + half.z * absf(axis.z)
			var pc   := axis.dot(center)
			if pmin > pc + pr or pmax < pc - pr: return false

	return true


# ---------------------------------------------------------------------------
# Export
# ---------------------------------------------------------------------------
func _export_bin() -> void:
	var path := ProjectSettings.globalize_path(output_dir.path_join("svo_nodes.bin"))
	var f    := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("SVOBuilder: could not write %s" % path)
		return

	# 8 × int32 per node, little-endian
	for node in _nodes:
		for child_val in node:
			f.store_32(child_val)

	f.close()
	print("  svo_nodes.bin  —  %d nodes, %d bytes" \
		  % [_nodes.size(), _nodes.size() * 8 * 4])


func _export_meta() -> void:
	var meta := {
		"root_min_x" : _root_min.x,
		"root_min_y" : _root_min.y,
		"root_min_z" : _root_min.z,
		"root_size"  : _root_size,
		"max_depth"  : max_depth,
		"node_count" : _nodes.size(),
	}
	var path := ProjectSettings.globalize_path(output_dir.path_join("svo_meta.json"))
	var f    := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(meta, "\t"))
		f.close()
	print("  svo_meta.json written")
