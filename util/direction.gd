enum { RIGHT, UP, LEFT, DOWN }
enum Relative { SAME, LEFT, OPPOSITE, RIGHT }


static func as_string(dir: int) -> String:
	return [
		"Right",
		"Up",
		"Left",
		"Down",
	][dir]


static func as_vector(dir: int) -> Vector2:
	return [
		Vector2.RIGHT,
		Vector2.UP,
		Vector2.LEFT,
		Vector2.DOWN,
	][dir]


static func as_angle(relative: int) -> float:
	return PI * [
		0.0,
		0.5,
		1.0,
		1.5,
	][relative]


static func relative(a: int, b: int) -> int:
	return (b - a + 4) % 4


static func rotate(direction: int, relative: int) -> int:
	return (direction + relative) % 4


static func left_of(direction: int) -> int:
	return rotate(direction, Relative.LEFT)


static func right_of(direction: int) -> int:
	return rotate(direction, Relative.RIGHT)


static func opposite_of(direction: int) -> int:
	return rotate(direction, Relative.OPPOSITE)
