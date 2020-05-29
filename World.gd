extends Node2D

const Simulation = preload("Simulation.gdns")

enum State { OFF, ON }
enum Component {
	SWITCH, BUTTON, BLOTTER, INVERTER, LAMP, WIRE1, WIRE2A, WIRE2B, WIRE3,
	WIRE4, WIRE_CROSS,
}
enum Direction {
	NORTH,
	EAST,
	SOUTH,
	WEST,
}

func rotate_right(direction: int) -> int:
	return (direction + 1) % 4
	
func rotate_left(direction: int) -> int:
	return (direction + 3) % 4

func load_tiles(name: String) -> Array:
	return [
		$Components.tile_set.find_tile_by_name(name + "_off"),
		$Components.tile_set.find_tile_by_name(name + "_on"),
	]
	
onready var tiles := [
	load_tiles("switch"),
	load_tiles("button"),
	load_tiles("blotter"),
	load_tiles("inverter"),
	load_tiles("lamp"),
	load_tiles("wire1"),
	load_tiles("wire2a"),
	load_tiles("wire2b"),
	load_tiles("wire3"),
	load_tiles("wire4"),
	[
		[
			$Components.tile_set.find_tile_by_name("wire_cross_off"),
			$Components.tile_set.find_tile_by_name("wire_cross_h"),
		],
		[
			$Components.tile_set.find_tile_by_name("wire_cross_v"),
			$Components.tile_set.find_tile_by_name("wire_cross_on"),
		],
	],
]

var selected_tile: Vector2
var selected_component: int = Component.INVERTER
var selected_direction: int = Direction.NORTH
var pan_speed := 800.0
var zoom_speed := 2.0
var zoom_step := 0.2
var current_pan := Vector2(0, 0)
var current_zoom := 0.0

func set_component(tilemap: TileMap, cell: Vector2, component: int, state: int, direction: int) -> void:
	var flip_x = direction in [Direction.EAST, Direction.SOUTH]
	var flip_y = direction in [Direction.WEST, Direction.SOUTH]
	var transpose = direction in [Direction.EAST, Direction.WEST]
	tilemap.set_cellv(cell, tiles[component][state], flip_x, flip_y, transpose)
	
func _process(delta: float) -> void:
	$Camera.offset += (delta * pan_speed) * (current_pan * $Camera.zoom)
	$Camera.zoom *= 1.0 + delta * zoom_speed * current_zoom
	$EditorGhost.clear()
	set_component($EditorGhost, selected_tile, selected_component, State.OFF, selected_direction)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		selected_tile = $Components.world_to_map($Components.get_local_mouse_position())
	elif event.is_action_pressed("ui_left"):
		selected_tile += Vector2.LEFT
	elif event.is_action_pressed("ui_right"):
		selected_tile += Vector2.RIGHT
	elif event.is_action_pressed("ui_up"):
		selected_tile += Vector2.UP
	elif event.is_action_pressed("ui_down"):
		selected_tile += Vector2.DOWN
	elif event.is_action_pressed("ui_rotate_right"):
		selected_direction = rotate_right(selected_direction)
	elif event.is_action_pressed("ui_rotate_left"):
		selected_direction = rotate_left(selected_direction)
	elif event.is_action_pressed("ui_pan"):
		pass #TODO mouse drag panning
	elif event.is_action_pressed("ui_zoom_in"):
		$Camera.zoom *= 1.0 / (1.0 + zoom_step)
	elif event.is_action_pressed("ui_zoom_out"):
		$Camera.zoom *= 1.0 + zoom_step
	elif event.is_action("ui_pan_left") or event.is_action("ui_pan_right"):
		current_pan.x = Input.get_action_strength("ui_pan_right") - Input.get_action_strength("ui_pan_left")
	elif event.is_action("ui_pan_up") or event.is_action("ui_pan_down"):
		current_pan.y = Input.get_action_strength("ui_pan_down") - Input.get_action_strength("ui_pan_up")
	elif event.is_action("ui_zoom_in_axis") or event.is_action("ui_zoom_out_axis"):
		current_zoom = Input.get_action_strength("ui_zoom_out_axis") - Input.get_action_strength("ui_zoom_in_axis")
