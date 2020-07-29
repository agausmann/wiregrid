enum { RIGHT, UP, LEFT, DOWN }
enum Relative { SAME, LEFT, OPPOSITE, RIGHT }


static func as_string(dir: int) -> String:
	return [
		"Right",
		"Up",
		"Left",
		"Down",
	][dir]


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
