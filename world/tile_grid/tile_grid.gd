class_name TileGrid
extends TileMap

enum TileType { NONE, COMPONENT_INPUT, COMPONENT_OUTPUT, COMPONENT_BODY, WIRE }
enum ComponentType { NONE, BUFFER, INVERTER, SWITCH, BUTTON, LAMP }
enum WireType { NONE, WIRE0, WIRE1, WIRE2A, WIRE2B, WIRE3, WIRE4, WIRE_CROSS }
enum State { OFF, ON }

const Direction := preload('res://direction.gd')

export(TileType) var default_tile_type := TileType.NONE

onready var _component_input_tiles = [
	[-1, -1],
	_get_tiles("input_side", 1),
	_get_tiles("input_top", 1),
	_get_tiles("switch", 1),
	_get_tiles("button", 1),
	_get_tiles("lamp", 1),
]
onready var _component_output_tiles = [
	[-1, -1],
	_get_tiles("output", 1),
	_get_tiles("output", 1),
	_get_tiles("output", 1),
	_get_tiles("output", 1),
	[-1, -1],
]
onready var _component_body_tiles = [
	-1,
	_get_tiles("component_body"),
	_get_tiles("component_body"),
	_get_tiles("component_body"),
	_get_tiles("component_body"),
	-1,
]
onready var _wire_tiles := [
	-1,
	_get_tiles("wire0", 1),
	_get_tiles("wire1", 1),
	_get_tiles("wire2a", 1),
	_get_tiles("wire2b", 1),
	_get_tiles("wire3", 1),
	_get_tiles("wire4", 1),
	_get_tiles("wire_cross", 2),
]
onready var _tile_types := [
	[],
	_component_input_tiles,
	_component_output_tiles,
	_component_body_tiles,
	_wire_tiles,
]

func set_tile(loc: Vector2, index: int, direction: int, states: Array) -> void:
	var _default_tiles = _tile_types[default_tile_type]
	var tile = _deep_index(_default_tiles[index], states)
	_set_inner(loc, tile, direction)


func set_component_input(loc: Vector2, component: int, direction: int, states: Array) -> void:
	var tile = _deep_index(_component_input_tiles[component], states)
	_set_inner(loc, tile, direction)


func set_component_output(loc: Vector2, component: int, direction: int, states: Array) -> void:
	var tile = _deep_index(_component_output_tiles[component], states)
	_set_inner(loc, tile, direction)


func set_component_body(loc: Vector2, component: int, direction: int, states: Array) -> void:
	var tile = _deep_index(_component_body_tiles[component], states)
	_set_inner(loc, tile, direction)


func set_wire(loc: Vector2, wire: int, direction: int, states: Array) -> void:
	var tile = _deep_index(_wire_tiles[wire], states)
	_set_inner(loc, tile, direction)


func _get_tiles(name: String, depth: int=0):
	if depth == 0:
		return tile_set.find_tile_by_name(name)
	else:
		return [
			_get_tiles(name + "_off", depth - 1),
			_get_tiles(name + "_on", depth - 1),
		]


func _deep_index(obj, idx: Array):
	for i in idx:
		obj = obj[i]
	return obj


func _set_inner(loc: Vector2, tile: int, direction: int) -> void:
	var flip_x := [Direction.LEFT, Direction.UP].has(direction)
	var flip_y := [Direction.LEFT, Direction.DOWN].has(direction)
	var transpose := [Direction.UP, Direction.DOWN].has(direction)
	set_cellv(loc, tile, flip_x, flip_y, transpose)
