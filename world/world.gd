class_name WiregridWorld
extends Node2D

const ComponentType := TileGrid.ComponentType
const WireType := TileGrid.WireType
const State := TileGrid.State
const Direction := preload('res://direction.gd')
const Rotation := Direction.Rotation
const Simulation := preload('res://simulation/simulation.gdns')

var selected_tile := Vector2.ZERO
var selected_component: int = ComponentType.INVERTER
var selected_direction: int = Direction.UP
onready var main_layer := $MainLayer
onready var ghost_layer := $GhostLayer
onready var highlight_layer := $HighlightLayer
var _current_mode: Mode = NormalMode.new(self)
var _tile_wires := {}
var _wires := []
var _free_wires := []
var _simulation := Simulation.new()
var _update_tiles := {}


func _process(delta: float) -> void:
	var viewport = get_viewport()
	var viewport_transform = get_viewport_transform().affine_inverse()
	var local_transform = get_transform().affine_inverse()
	selected_tile = main_layer.world_to_map(
		local_transform.xform(viewport_transform.xform(viewport.get_mouse_position()))
	)
	_current_mode.process(delta)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("primary"):
		if _current_mode is NormalMode:
			change_mode(PlaceWireMode.new(self))
	if event.is_action_released("primary"):
		if _current_mode is PlaceWireMode:
			finish_mode()
	_current_mode.input(event)


func change_mode(new_mode: Mode) -> void:
	_current_mode.cancel()
	_current_mode = new_mode


func finish_mode() -> void:
	_current_mode.finish()
	_current_mode = NormalMode.new(self)


func place_wire(start: Vector2, direction: int, length: int) -> void:
	if length == 0:
		return
	
	_simulation.start_atomic()
	var dv := _direction_vector(direction)
	var end := start + dv * length
	
	# Endpoints
	var wire: int
	var start_wire := _get_endpoint_wire(start, direction)
	var end_wire := _get_endpoint_wire(end, direction)
	if start_wire == -1:
		wire = end_wire
	elif end_wire == -1:
		wire = start_wire
	else:
		_merge_wire(start_wire, end_wire)
		wire = start_wire

	wire = _place_wire_part(start, direction, wire)
	wire = _place_wire_part(end, Direction.opposite(direction), wire)
	_draw_wire(start)
	_draw_wire(end)
	
	# Middle segments
	for i in range(1, length):
		var loc := start + dv * i
		wire = _place_wire_part(loc, direction, wire)
		wire = _place_wire_part(loc, Direction.opposite(direction), wire)
		_draw_wire(loc)
	_simulation.finish_atomic()


func remove_wire(start: Vector2, direction: int, length: int) -> void:
	pass


func _get_endpoint_wire(loc: Vector2, direction: int) -> int:
	var wire := -1
	for _i in range(4):
		if _tile_wires.has(loc) and _tile_wires[loc].has(direction):
			wire = _tile_wires[loc][direction]
			break
		direction = Direction.left(direction)
	return wire


func _place_wire_part(loc: Vector2, direction: int, wire_id: int) -> int:
	if _tile_wires.has(loc) and _tile_wires[loc].has(direction):
		var new_wire = _tile_wires[loc][direction]
		if wire_id == -1:
			wire_id = new_wire
		elif wire_id != new_wire:
			_merge_wire(wire_id, new_wire)
	else:
		if wire_id == -1:
			wire_id = _create_wire()
		if not _tile_wires.has(loc):
			_tile_wires[loc] = {}
		_tile_wires[loc][direction] = wire_id
	_wires[wire_id].connected_tiles[loc] = null
	return wire_id


func _direction_vector(direction: int) -> Vector2:
	return {
		Direction.RIGHT: Vector2.RIGHT,
		Direction.LEFT: Vector2.LEFT,
		Direction.UP: Vector2.UP,
		Direction.DOWN: Vector2.DOWN,
	}[direction]


func _create_wire() -> int:
	var wire_id: int
	if _free_wires.empty():
		wire_id = len(_wires)
		_wires.append(Wire.new())
	else:
		wire_id = _free_wires.pop_back()
		_wires[wire_id] = Wire.new()
	return wire_id


func _merge_wire(dst: int, src: int) -> void:
	assert(dst != -1)
	if src == dst or src == -1:
		return
	for tile_loc in _wires[src].connected_tiles.keys():
		_wires[dst].connected_tiles[tile_loc] = null
		var tile_wires = _tile_wires[tile_loc]
		for direction in tile_wires.keys():
			if tile_wires[direction] == src:
				tile_wires[direction] = dst
			elif tile_wires[direction] == dst:
				# used to be a crossed wire, force redraw
				_draw_wire(tile_loc)
	_simulation.start_atomic()
	_free_wires.append(src)
	_simulation.finish_atomic()


func _split_wire(src: int) -> int:
	return -1


func _draw_wire(tile: Vector2) -> void:
	#TODO retrieve wire group states
	var directions = _tile_wires.get(tile, {})
	var id := (
		int(directions.has(Direction.RIGHT))
		| int(directions.has(Direction.UP)) << 1
		| int(directions.has(Direction.LEFT)) << 2
		| int(directions.has(Direction.DOWN)) << 3
	)
	var wire_type
	var rotation
	var states
	if id == 15:
		rotation = Rotation.SAME
		if directions[Direction.RIGHT] == directions[Direction.UP]:
			wire_type = WireType.WIRE4
			states = [State.OFF]
		else:
			wire_type = WireType.WIRE_CROSS
			states = [State.OFF, State.OFF]
	else:
		var variants := [
			[WireType.NONE, Rotation.SAME],
			[WireType.WIRE1, Rotation.SAME],
			[WireType.WIRE1, Rotation.LEFT],
			[WireType.WIRE2B, Rotation.SAME],
			[WireType.WIRE1, Rotation.OPPOSITE],
			[WireType.WIRE2A, Rotation.SAME],
			[WireType.WIRE2B, Rotation.LEFT],
			[WireType.WIRE3, Rotation.LEFT],
			[WireType.WIRE1, Rotation.RIGHT],
			[WireType.WIRE2B, Rotation.RIGHT],
			[WireType.WIRE2A, Rotation.LEFT],
			[WireType.WIRE3, Rotation.SAME],
			[WireType.WIRE2B, Rotation.OPPOSITE],
			[WireType.WIRE3, Rotation.RIGHT],
			[WireType.WIRE3, Rotation.OPPOSITE],
		]
		wire_type = variants[id][0]
		rotation = variants[id][1]
		states = [State.OFF]
	main_layer.place_wire(tile, wire_type, rotation, states)


class Mode:
	var world: WiregridWorld
	
	func _init(w: WiregridWorld) -> void:
		world = w
	
	func process(_delta: float) -> void:
		pass
	
	func input(_event: InputEvent) -> void:
		pass
	
	func finish() -> void:
		pass
	
	func cancel() -> void:
		pass


class NormalMode extends Mode:
	func _init(w).(w): pass
		
	func process(_delta: float) -> void:
		world.ghost_layer.clear()
		world.ghost_layer.place_component(
			world.selected_tile,
			world.selected_component,
			world.selected_direction,
			State.OFF,
			State.ON
		)


class LineMode extends Mode:
	var start: Vector2
	var direction := Direction.RIGHT
	var length := 0
	
	func _init(w).(w):
		start = world.selected_tile
	
	func process(_delta: float) -> void:
		var delta = world.selected_tile - start
		direction = Direction.nearest(delta)
		length = int(max(abs(delta.x), abs(delta.y)))


class PlaceWireMode extends LineMode:
	func _init(w).(w): pass
	
	func process(delta: float) -> void:
		.process(delta)
		var dv := Direction.to_vector(direction)
		world.ghost_layer.clear()
		if length == 0:
			world.ghost_layer.place_wire(start, WireType.WIRE0, Direction.RIGHT, [State.OFF])
		else:
			world.ghost_layer.place_wire(start, WireType.WIRE1, direction, [State.OFF])
			world.ghost_layer.place_wire(start + dv * length, WireType.WIRE1, Direction.opposite(direction), [State.OFF])
			for i in range(1, length):
				world.ghost_layer.place_wire(start + dv * i, WireType.WIRE2A, direction, [State.OFF])
	
	func finish() -> void:
		world.place_wire(start, direction, length)


class Wire:
	var connected_tiles := {}
	
	func _init():
		pass
