@tool extends EditorPlugin

var custom_node3d_gizmo = CustomNode3DGizmo.new()

func _enter_tree() -> void:
	add_node_3d_gizmo_plugin(custom_node3d_gizmo)

func _exit_tree() -> void:
	remove_node_3d_gizmo_plugin(custom_node3d_gizmo)
