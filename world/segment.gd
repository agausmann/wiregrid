class_name WireSegment
extends Polygon2D

const Direction := preload("res://util/direction.gd")

const RADIUS := 0.0625
const DIAG_OFFSET := RADIUS * (sqrt(0.5) - 0.5)


func _init(start: Vector2, start_dir: int, diag: int, length: int):
	if length != 0:
		start += Vector2(0.5, 0.5)
		var end := (
			start
			+ ceil(length / 2.0) * Direction.as_vector(start_dir)
			+ floor(length / 2.0) * Direction.as_vector(Direction.rotate(start_dir, diag))
		)
		var end_dir := Direction.rotate(Direction.opposite_of(start_dir), (length + 1) % 2 * diag)
		
		var array := PoolVector2Array()
		array.append_array(tail(start, start_dir, (diag + 2) % 4 - 2))
		array.append_array(tail(end, end_dir, ((diag + 2) % 4 - 2) * ((length % 2) * 2 - 1)))
		polygon = array


static func tail(pos: Vector2, dir: int, diag: int) -> PoolVector2Array:
	var angle := Direction.as_angle(Direction.relative(dir, Direction.RIGHT))
	
	return PoolVector2Array([
		pos + Vector2(0.5 - DIAG_OFFSET * diag, -RADIUS).rotated(angle),
		pos + Vector2(-RADIUS, -RADIUS).rotated(angle),
		pos + Vector2(-RADIUS, RADIUS).rotated(angle),
		pos + Vector2(0.5 + DIAG_OFFSET * diag, RADIUS).rotated(angle),
	])
