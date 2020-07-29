class_name WiregridWorld
extends Sprite

func _process(_delta: float) -> void:
	var viewport_transform = get_viewport_transform().affine_inverse()
	region_rect = viewport_transform.xform(get_viewport_rect())
	position = region_rect.position
