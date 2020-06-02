extends Line2D

export var rect := Rect2(Vector2.ZERO, Vector2.ZERO)

func _process(_delta: float) -> void:
	points = [
		rect.position,
		Vector2(rect.position.x, rect.end.y),
		rect.end,
		Vector2(rect.end.x, rect.position.y),
		rect.position,
	]
