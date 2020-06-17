enum { RIGHT, UP, LEFT, DOWN }
enum Relative { SAME, LEFT, OPPOSITE, RIGHT }

static func rotate(direction: int, amount: int) -> int:
	return (direction + amount) % 4

static func left(direction: int) -> int:
	return rotate(direction, Relative.LEFT)

static func opposite(direction: int) -> int:
	return rotate(direction, Relative.OPPOSITE)

static func right(direction: int) -> int:
	return rotate(direction, Relative.RIGHT)
