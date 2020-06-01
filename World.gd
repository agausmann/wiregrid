extends Node2D

const Simulation = preload("Simulation.gdns")

enum State { OFF, ON }
enum Component {
	SWITCH, BUTTON, BLOTTER, INVERTER, LAMP, WIRE1, WIRE2A, WIRE2B, WIRE3,
	WIRE4, WIRE_CROSS,
}
enum Direction { NORTH, EAST, SOUTH, WEST }
enum CursorMode {
	FREE, PAN, WIRE_PLACE, WIRE_DELETE, COMPONENT_PLACE, COMPONENT_DELETE,
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
var current_pan := Vector2.ZERO
var current_zoom := 1.0
var pan_input := Vector2.ZERO
var zoom_input := 0.0
var cursor_mode: int = CursorMode.FREE
var painted = {}

func set_tile(tilemap: TileMap, cell: Vector2, component: int, state: int, direction: int) -> void:
	var flip_x = direction in [Direction.EAST, Direction.SOUTH]
	var flip_y = direction in [Direction.WEST, Direction.SOUTH]
	var transpose = direction in [Direction.EAST, Direction.WEST]
	tilemap.set_cellv(cell, tiles[component][state], flip_x, flip_y, transpose)
	
func copy_tile(src: TileMap, dst: TileMap, cell: Vector2) -> void:
	var x := int(cell.x)
	var y := int(cell.y)
	dst.set_cellv(
		cell,
		src.get_cellv(cell),
		src.is_cell_x_flipped(x, y),
		src.is_cell_y_flipped(x, y),
		src.is_cell_transposed(x, y)
	)

func clear_tile(tilemap: TileMap, cell: Vector2) -> void:
	tilemap.set_cellv(cell, -1)
	
func _process(delta: float) -> void:
	current_pan += (delta * pan_speed) * (pan_input / current_zoom)
	current_zoom *= 1.0 + delta * zoom_speed * zoom_input
	
	var viewport = get_viewport()
	viewport.canvas_transform = Transform2D(
		Vector2(current_zoom, 0),
		Vector2(0, current_zoom),
		current_pan * Vector2(current_zoom, current_zoom)
			+ viewport.size / Vector2(2.0, 2.0)
	)
	
	if cursor_mode == CursorMode.FREE:
		$EditorGhost.clear()
		set_tile($EditorGhost, selected_tile, selected_component, State.OFF, selected_direction)
	elif cursor_mode == CursorMode.PAN:
		$EditorGhost.clear()
	elif cursor_mode == CursorMode.COMPONENT_PLACE:
		if not painted.has(selected_tile):
			painted[selected_tile] = null
			set_tile($EditorGhost, selected_tile, selected_component, State.OFF, selected_direction)
	elif cursor_mode == CursorMode.COMPONENT_DELETE:
		if not painted.has(selected_tile):
			painted[selected_tile] = null
			copy_tile($Components, $EditorGhost, selected_tile)
			clear_tile($Components, selected_tile)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		selected_tile = $Components.world_to_map($Components.get_local_mouse_position())
		if cursor_mode == CursorMode.PAN:
			current_pan += event.relative / Vector2(current_zoom, current_zoom)
	elif event.is_action_pressed("cursor_left"):
		selected_tile += Vector2.LEFT
	elif event.is_action_pressed("cursor_right"):
		selected_tile += Vector2.RIGHT
	elif event.is_action_pressed("cursor_up"):
		selected_tile += Vector2.UP
	elif event.is_action_pressed("cursor_down"):
		selected_tile += Vector2.DOWN
	elif event.is_action_pressed("rotate_right"):
		selected_direction = rotate_right(selected_direction)
	elif event.is_action_pressed("rotate_left"):
		selected_direction = rotate_left(selected_direction)
	elif event.is_action_pressed("pan"):
		if cursor_mode == CursorMode.FREE:
			cursor_mode = CursorMode.PAN
	elif event.is_action_released("pan"):
		if cursor_mode == CursorMode.PAN:
			cursor_mode = CursorMode.FREE
	elif event.is_action_pressed("zoom_in"):
		current_zoom *= 1.0 + zoom_step
	elif event.is_action_pressed("zoom_out"):
		current_zoom *= 1.0 / (1.0 + zoom_step)
	elif event.is_action("pan_left") or event.is_action("pan_right"):
		pan_input.x = Input.get_action_strength("pan_left") - Input.get_action_strength("pan_right")
	elif event.is_action("pan_up") or event.is_action("pan_down"):
		pan_input.y = Input.get_action_strength("pan_up") - Input.get_action_strength("pan_down")
	elif event.is_action("zoom_in_axis") or event.is_action("zoom_out_axis"):
		zoom_input = Input.get_action_strength("zoom_in_axis") - Input.get_action_strength("zoom_out_axis")
	elif event.is_action_pressed("primary"):
		if cursor_mode == CursorMode.FREE:
			cursor_mode = CursorMode.COMPONENT_PLACE
			painted.clear()
	elif event.is_action_released("primary"):
		if cursor_mode == CursorMode.COMPONENT_PLACE:
			cursor_mode = CursorMode.FREE
			for cell in painted.keys():
				set_tile($Components, cell, selected_component, State.OFF, selected_direction)
	elif event.is_action_pressed("secondary"):
		if cursor_mode == CursorMode.FREE:
			cursor_mode = CursorMode.COMPONENT_DELETE
			painted.clear()
	elif event.is_action_released("secondary"):
		if cursor_mode == CursorMode.COMPONENT_DELETE:
			cursor_mode = CursorMode.FREE
