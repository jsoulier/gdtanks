@tool class_name CustomNode3DGizmo extends EditorNode3DGizmoPlugin

static var RADIUS: float = 0.1

func _init() -> void:
    create_material("default", Color.RED)

func _get_gizmo_name() -> String:
    return "Node3D"

func _has_gizmo(node: Node3D) -> bool:
    # Don't paint subclasses of Node3D
    return node.get_class() == "Node3D"

func _redraw(gizmo: EditorNode3DGizmo) -> void:
    gizmo.clear()
    var sphere: SphereMesh = SphereMesh.new()
    sphere.radius = RADIUS
    sphere.height = RADIUS * 2.0
    gizmo.add_mesh(sphere, get_material("default", gizmo))
    gizmo.add_collision_triangles(sphere.generate_triangle_mesh())
