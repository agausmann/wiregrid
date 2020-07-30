extends Sprite

func _init() -> void:
	# N.B. Can't accurately set 1/16 (0.0625) in Godot editor
	scale = Vector2.ONE * (1.0 / 16.0)

func _process(_delta: float) -> void:
	var viewport_transform = get_viewport_transform().affine_inverse()
	var local_transform = get_transform().affine_inverse()
	region_rect = local_transform.xform(viewport_transform.xform(get_viewport_rect()))
	position = region_rect.position
