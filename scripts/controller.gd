class_name Controller extends Node3D

@onready var tank: Tank = $".."

func get_controller_color() -> Color:
	return Color.MAGENTA

func get_color() -> Vector3:
	var color: Color = get_controller_color()
	return Vector3(color.r, color.g, color.b)
