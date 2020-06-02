extends Node2D

const Simulation = preload("Simulation.gdns")

enum State { OFF, ON }
enum Component {
	SWITCH, BUTTON, BLOTTER, INVERTER, LAMP, WIRE1, WIRE2A, WIRE2B, WIRE3,
	WIRE4, WIRE_CROSS,
}
enum Direction { NORTH, EAST, SOUTH, WEST }

class Mode:
	var world
	
	func _init(w) -> void:
		self.world = w
	
	func process(_delta: float) -> void: pass
	func input(_event: InputEvent) -> void: pass
	func finish() -> void: pass
	func cancel() -> void: pass
	
class Normal extends Mode:
	func _init(w).(w) -> void: pass
	
	func process(_delta: float) -> void:
		world.get_node("EditorGhost").clear()
		world.set_tile(world.get_node("EditorGhost"), world.selected_tile, world.selected_component, State.OFF, world.selected_direction)

class Pan extends Mode:
	func _init(w).(w) -> void: pass
	
	func process(_delta: float) -> void:
		world.get_node("EditorGhost").clear()
	
	func input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			var zoom_v := Vector2(world.current_zoom, world.current_zoom)
			world.current_pan += event.relative / zoom_v

class PaintMode extends Mode:
	var painted := {}
	var previous_tile: Vector2
	
	func _init(w).(w) -> void:
		painted[world.selected_tile] = null
		previous_tile = world.selected_tile
	
	func process(_delta: float) -> void:
		if world.selected_tile != previous_tile:
			for tile in bresenham(previous_tile, world.selected_tile):
				if not painted.has(tile):
					painted[tile] = null
			previous_tile = world.selected_tile
	
	func bresenham(src: Vector2, dst: Vector2) -> Array:
		if dst.x < src.x:
			return bresenham(dst, src)
			
		var delta := dst - src
		var delta_error := abs(delta.y / delta.x) if delta.x != 0 else INF
		if delta_error > 1:
			var transposed := bresenham(Vector2(src.y, src.x), Vector2(dst.y, dst.x))
			var result := []
			for v in transposed:
				result.append(Vector2(v.y, v.x))
			return result
		
		var result := []
		var error := 0.0
		var x := int(round(src.x))
		var y := int(round(src.y))
		while x <= dst.x:
			result.append(Vector2(x, y))
			error = error + delta_error
			if error >= 0.5:
				y += int(sign(delta.y) * 1)
				error -= 1.0
			x += 1
		
		return result

class PlaceComponent extends PaintMode:
	func _init(w).(w) -> void:
		world.get_node("EditorGhost").clear()
	
	func process(delta: float) -> void:
		.process(delta)
		var ghost = world.get_node("EditorGhost")
		for tile in painted:
			if ghost.get_cellv(tile) == TileMap.INVALID_CELL:
				world.set_tile(ghost, tile, world.selected_component, State.OFF, world.selected_direction)
	
	func finish() -> void:
		for tile in painted:
			world.place_component(tile, world.selected_component, world.selected_direction)

class RemoveComponent extends PaintMode:
	func _init(w).(w) -> void:
		world.get_node("EditorGhost").clear()
	
	func process(delta: float) -> void:
		.process(delta)
		var ghost = world.get_node("EditorGhost")
		var components = world.get_node("Components")
		for tile in painted:
			if components.get_cellv(tile) != TileMap.INVALID_CELL:
				world.copy_tile(components, ghost, tile)
				components.set_cellv(tile, -1)
	
	func finish() -> void:
		.finish()
		for tile in painted:
			world.remove_component(tile)
	
	func cancel() -> void:
		.cancel()
		var ghost = world.get_node("EditorGhost")
		var components = world.get_node("Components")
		for tile in painted:
			world.copy_tile(ghost, components, tile)

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
var painted := {}
var previous_tile = null
var pan_input := Vector2.ZERO
var zoom_input := 0.0
var mode: Mode = Normal.new(self)

func rotate_right(direction: int) -> int:
	return (direction + 1) % 4

func rotate_left(direction: int) -> int:
	return (direction + 3) % 4

func load_tiles(name: String) -> Array:
	return [
		$Components.tile_set.find_tile_by_name(name + "_off"),
		$Components.tile_set.find_tile_by_name(name + "_on"),
	]

func change_mode(new_mode: Mode) -> void:
	mode.cancel()
	mode = new_mode

func finish_mode() -> void:
	mode.finish()
	mode = Normal.new(self)

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
	
func place_component(cell: Vector2, component: int, direction: int) -> void:
	set_tile($Components, cell, component, State.OFF, direction)

func remove_component(cell: Vector2) -> void:
	$Components.set_cellv(cell, -1)

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
	mode.process(delta)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		selected_tile = $Components.world_to_map($Components.get_local_mouse_position())
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
		if mode is Normal:
			change_mode(Pan.new(self))
	elif event.is_action_released("pan"):
		if mode is Pan:
			finish_mode()
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
		if mode is Normal:
			change_mode(PlaceComponent.new(self))
	elif event.is_action_released("primary"):
		if mode is PlaceComponent:
			finish_mode()
	elif event.is_action_pressed("secondary"):
		if mode is Normal:
			change_mode(RemoveComponent.new(self))
	elif event.is_action_released("secondary"):
		if mode is RemoveComponent:
			finish_mode()
	
	mode.input(event)
