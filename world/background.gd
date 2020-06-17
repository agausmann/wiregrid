extends Sprite

func _process(_delta: float) -> void:
	region_rect = get_viewport_transform().affine_inverse().xform(get_viewport_rect())
	position = region_rect.position
