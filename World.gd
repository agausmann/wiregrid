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
var selected_component: int
var selected_direction: int = Direction.NORTH

func set_component(tilemap: TileMap, cell: Vector2, component: int, state: int, direction: int) -> void:
	var flip_x = direction in [Direction.EAST, Direction.SOUTH]
	var flip_y = direction in [Direction.WEST, Direction.SOUTH]
	var transpose = direction in [Direction.EAST, Direction.WEST]
	tilemap.set_cellv(cell, tiles[component][state], flip_x, flip_y, transpose)

func update_ghost() -> void:
	$EditorGhost.clear()
	set_component($EditorGhost, selected_tile, selected_component, State.OFF, selected_direction)
	
func select_tile(tile: Vector2) -> void:
	selected_tile = tile
	update_ghost()
	
func select_component(component: int) -> void:
	selected_component = component
	update_ghost()
	
func select_direction(direction: int) -> void:
	selected_direction = direction
	update_ghost()

func _input(event):
	print(event)
	if event is InputEventMouseMotion:
		select_tile($Components.world_to_map($Components.get_local_mouse_position()))
	elif event.is_action_pressed("ui_left"):
		select_tile(selected_tile + Vector2(-1, 0))
	elif event.is_action_pressed("ui_right"):
		select_tile(selected_tile + Vector2(1, 0))
	elif event.is_action_pressed("ui_up"):
		select_tile(selected_tile + Vector2(0, -1))
	elif event.is_action_pressed("ui_down"):
		select_tile(selected_tile + Vector2(0, 1))
	elif event.is_action_pressed("ui_rotate_right"):
		select_direction(rotate_right(selected_direction))
	elif event.is_action_pressed("ui_rotate_left"):
		select_direction(rotate_left(selected_direction))
