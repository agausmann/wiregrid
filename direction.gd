enum { RIGHT, UP, LEFT, DOWN }

static func rotate_left(direction: int) -> int:
	return (direction + 1) % 4

static func opposite(direction: int) -> int:
	return (direction + 2) % 4

static func rotate_right(direction: int) -> int:
	return (direction + 3) % 4
