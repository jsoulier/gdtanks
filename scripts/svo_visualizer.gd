extends Node3D
## SVOVisualizer
##
## Reads svo_nodes.bin + svo_meta.json at startup, walks the tree, and
## caches a flat list of line pairs to draw every frame with
## DebugDraw3D.draw_line calls. No per-frame tree traversal.

@export_file("*.json") var meta_path  : String = "res://svo/svo_meta.json"
@export_file("*.bin")  var nodes_path : String = "res://svo/svo_nodes.bin"

@export_group("Display")
@export_range(0, 12) var max_draw_depth : int = 99
@export var solid_color : Color = Color(0.2, 0.8, 0.4, 1.0)

# Each entry is [Vector3 a, Vector3 b, Color] — one per box edge.
var _lines : Array = []
var _nodes : PackedInt32Array


func _ready() -> void:
	_load_and_cache()

func _process(_delta: float) -> void:
	if visible:
		for i in range(_lines.size() / 2):
			DebugDraw3D.draw_line(_lines[i * 2 + 0], _lines[i * 2 + 1], solid_color)

# ---------------------------------------------------------------------------
# Load + walk the tree once, cache every edge as a line pair
# ---------------------------------------------------------------------------
func _load_and_cache() -> void:
	# --- meta ---
	var f := FileAccess.open(meta_path, FileAccess.READ)
	if f == null:
		push_error("SVOVisualizer: cannot open %s" % meta_path)
		return
	var meta : Dictionary = JSON.parse_string(f.get_as_text())
	f.close()

	var root_min  := Vector3(meta.root_min_x, meta.root_min_y, meta.root_min_z)
	var root_size := float(meta.root_size)
	var svo_depth := int(meta.max_depth)
	var node_count := int(meta.node_count)

	# --- binary node buffer ---
	var bf := FileAccess.open(nodes_path, FileAccess.READ)
	if bf == null:
		push_error("SVOVisualizer: cannot open %s" % nodes_path)
		return
	_nodes = PackedInt32Array()
	_nodes.resize(node_count * 8)
	for i in range(_nodes.size()):
		_nodes[i] = bf.get_32()
	bf.close()

	# --- DFS ---
	var draw_depth: int = min(max_draw_depth, svo_depth)
	var stack : Array = [[0, root_min, root_size, 0]]

	while not stack.is_empty():
		var e     : Array   = stack.pop_back()
		var ni    : int     = e[0]
		var nmin  : Vector3 = e[1]
		var nsize : float   = e[2]
		var depth : int     = e[3]

		if depth > draw_depth:
			continue

		var half : float = nsize * 0.5

		for slot in range(8):
			var child_val : int = _nodes[ni * 8 + slot]
			var cmin := nmin + Vector3(
				half if (slot & 1) else 0.0,
				half if (slot & 2) else 0.0,
				half if (slot & 4) else 0.0)

			if child_val == -2:
				_cache_box(cmin, cmin + Vector3(half, half, half))
			elif child_val >= 0 and depth + 1 <= draw_depth:
				stack.push_back([child_val, cmin, half, depth + 1])

	print("SVOVisualizer: %d lines cached." % _lines.size())


# ---------------------------------------------------------------------------
# Cache the 12 edges of a box
# ---------------------------------------------------------------------------
func _cache_box(bmin: Vector3, bmax: Vector3) -> void:
	var c := [
		Vector3(bmin.x, bmin.y, bmin.z),
		Vector3(bmax.x, bmin.y, bmin.z),
		Vector3(bmax.x, bmax.y, bmin.z),
		Vector3(bmin.x, bmax.y, bmin.z),
		Vector3(bmin.x, bmin.y, bmax.z),
		Vector3(bmax.x, bmin.y, bmax.z),
		Vector3(bmax.x, bmax.y, bmax.z),
		Vector3(bmin.x, bmax.y, bmax.z),
	]
	const EDGES = [[0,1],[1,2],[2,3],[3,0],[4,5],[5,6],[6,7],[7,4],[0,4],[1,5],[2,6],[3,7]]
	for e in EDGES:
		_lines.append(c[e[0]])
		_lines.append(c[e[1]])
