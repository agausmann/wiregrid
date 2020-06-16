extends Node2D

export var width := 1.0 setget _set_width, _get_width
export var color := Color.black setget _set_color, _get_color

func _set_width(w: float) -> void:
	width = w
	material.set_shader_param("width", w)

func _get_width() -> float:
	return material.get_shader_param("width")

func _set_color(c: Color) -> void:
	color = c
	material.set_shader_param("color", c)

func _get_color() -> Color:
	return material.get_shader_param("color")
