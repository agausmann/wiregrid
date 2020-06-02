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

class BoxMode extends Mode:
	var start_tile: Vector2
	var end_tile: Vector2
	
	func _init(w).(w) -> void:
		start_tile = world.selected_tile
		end_tile = world.selected_tile
	
	func process(_delta: float) -> void:
		end_tile = world.selected_tile
	
	func selected_tiles(start: Vector2=start_tile, end: Vector2=end_tile) -> Array:
		var result := []
		for y in range(min(start.y, end.y), max(start.y, end.y) + 1):
			for x in range(min(start.x, end.x), max(start.x, end.x) + 1):
				result.append(Vector2(x, y))
		return result

class LineMode extends BoxMode:
	func _init(w).(w) -> void: pass
	
	func process(_delta: float) -> void:
		end_tile = world.selected_tile
		var line_delta := end_tile - start_tile
		if abs(line_delta.x) < abs(line_delta.y):
			end_tile.x = start_tile.x
		else:
			end_tile.y = start_tile.y

class PlaceComponent extends LineMode:
	func _init(w).(w) -> void: pass
	
	func process(delta: float) -> void:
		.process(delta)
		var ghost = world.get_node("EditorGhost")
		ghost.clear()
		for tile in selected_tiles():
			world.set_tile(ghost, tile, world.selected_component, State.OFF, world.selected_direction)
	
	func finish() -> void:
		for tile in selected_tiles():
			world.place_component(tile, world.selected_component, world.selected_direction)

class RemoveComponent extends BoxMode:
	var old_end: Vector2
	
	func _init(w).(w) -> void:
		old_end = end_tile
		var ghost = world.get_node("EditorGhost")
		var components = world.get_node("Components")
		ghost.clear()
		for tile in selected_tiles():
			world.copy_tile(components, ghost, tile)
			components.set_cellv(tile, -1)
	
	func process(delta: float) -> void:
		.process(delta)
		var ghost = world.get_node("EditorGhost")
		var components = world.get_node("Components")
		if end_tile != old_end:
			for tile in selected_tiles(start_tile, old_end):
				world.copy_tile(ghost, components, tile)
			ghost.clear()
			for tile in selected_tiles():
				world.copy_tile(components, ghost, tile)
				components.set_cellv(tile, -1)
			old_end = end_tile
	
	func finish() -> void:
		.finish()
		for tile in selected_tiles():
			world.remove_component(tile)
	
	func cancel() -> void:
		.cancel()
		var ghost = world.get_node("EditorGhost")
		var components = world.get_node("Components")
		for tile in selected_tiles():
			world.copy_tile(ghost, components, tile)

class PlaceWire extends LineMode:
	func _init(w).(w) -> void: pass
	
	func process(delta: float) -> void:
		.process(delta)
		var line_delta := end_tile - start_tile
		var direction: int
		if abs(line_delta.x) > abs(line_delta.y):
			direction = Direction.EAST
		else:
			direction = Direction.SOUTH
			
		var ghost = world.get_node("EditorGhost")
		ghost.clear()
		var selected_tiles := selected_tiles()
		if len(selected_tiles) > 1:
			world.set_tile(ghost, selected_tiles[0], Component.WIRE1, State.OFF, direction)
			world.set_tile(ghost, selected_tiles[-1], Component.WIRE1, State.OFF, world.opposite(direction))
			for tile in selected_tiles.slice(1, -2):
				world.set_tile(ghost, tile, Component.WIRE2B, State.OFF, direction)
	
	func finish() -> void:
		.finish()
		var selected_tiles := selected_tiles()
		if len(selected_tiles) <= 1:
			return
		var line_delta := end_tile - start_tile
		var directions: Array
		if abs(line_delta.x) > abs(line_delta.y):
			directions = [Direction.EAST, Direction.WEST]
		else:
			directions = [Direction.SOUTH, Direction.NORTH]
		world.place_wire(selected_tiles[0], [directions[0]])
		world.place_wire(selected_tiles[-1], [directions[1]])
		for tile in selected_tiles.slice(1, -2):
			world.place_wire(tile, directions, false)

class RemoveWire extends Mode:
	func _init(w).(w) -> void: pass

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

func opposite(direction: int) -> int:
	return (direction + 2) % 4

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

func place_wire(cell: Vector2, directions: Array, cross_connect: bool=false) -> void:
	pass

func remove_wire(cell: Vector2, directions: Array) -> void:
	pass

func _process(delta: float) -> void:
	current_pan += (delta * pan_speed) * (pan_input / current_zoom)
	current_zoom *= 1.0 + delta * zoom_speed * zoom_input
	
	var viewport = get_viewport()
	viewport.canvas_transform = Transform2D(
		Vector2(current_zoom, 0),
		Vector2(0, current_zoom),
		current_pan * current_zoom
			+ viewport.size / 2
	)
	mode.process(delta)
	$Background.offset = ((-current_pan - viewport.size / (2 * current_zoom)) / 16).floor() * 16
	$Background.region_rect = Rect2(Vector2.ZERO, viewport.size / current_zoom + Vector2(16, 16))

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
			#change_mode(PlaceComponent.new(self))
			change_mode(PlaceWire.new(self))
	elif event.is_action_released("primary"):
		#if mode is PlaceComponent:
		if mode is PlaceWire:
			finish_mode()
	elif event.is_action_pressed("secondary"):
		if mode is Normal:
			change_mode(RemoveComponent.new(self))
	elif event.is_action_released("secondary"):
		if mode is RemoveComponent:
			finish_mode()
	
	mode.input(event)
