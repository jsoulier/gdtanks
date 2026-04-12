@abstract class_name CameraController extends RefCounted

var node: Camera = null

@abstract func input(event: InputEvent) -> void
@abstract func process(delta: float) -> void
