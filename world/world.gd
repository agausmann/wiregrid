extends Node2D

enum Component { NONE, BUFFER, INVERTER, SWITCH, BUTTON, LAMP }
enum Wire { NONE, WIRE0, WIRE1, WIRE2A, WIRE2B, WIRE3, WIRE4, WIRE_CROSS }
enum Direction { RIGHT, UP, LEFT, DOWN }

const Simulation := preload('res://simulation/simulation.gdns')

var _simulation := Simulation.new()

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

func _get_tiles(name: String, depth: int=0):
	if depth == 0:
		return $ComponentBody.tile_set.find_tile_by_name(name)
	else:
		return [
			_get_tiles(name + "_off", depth - 1),
			_get_tiles(name + "_on", depth - 1),
		]
