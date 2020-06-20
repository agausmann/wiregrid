enum { RIGHT, UP, LEFT, DOWN }
enum Rotation { SAME, LEFT, OPPOSITE, RIGHT }

static func to_str(direction: int) -> Vector2:
	return [
		"Right",
		"Up",
		"Left",
		"Down",
	][direction]

static func to_vector(direction: int) -> Vector2:
	return [
		Vector2.RIGHT,
		Vector2.UP,
		Vector2.LEFT,
		Vector2.DOWN,
	][direction]

static func nearest(v: Vector2) -> int:
	if abs(v.x) > abs(v.y):
		if v.x < 0:
			return LEFT
		else:
			return RIGHT
	else:
		if v.y < 0:
			return UP
		else:
			return DOWN

static func rotate(direction: int, amount: int) -> int:
	return (direction + amount) % 4

static func rotation(src: int, dst: int) -> int:
	return (dst - src + 4) % 4

static func left(direction: int) -> int:
	return rotate(direction, Rotation.LEFT)

static func opposite(direction: int) -> int:
	return rotate(direction, Rotation.OPPOSITE)

static func right(direction: int) -> int:
	return rotate(direction, Rotation.RIGHT)
