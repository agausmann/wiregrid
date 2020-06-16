extends Node2D

const Direction := preload('res://direction.gd')
const Simulation := preload('res://simulation/simulation.gdns')

var _current_mode: Mode = NormalMode.new(self)
var _tile_wires := {}
var _wires := []
var _free_wires := []
var _simulation := Simulation.new()
var _update_tiles := {}


func _process(delta: float) -> void:
	_current_mode.process(delta)


func _input(event: InputEvent) -> void:
	_current_mode.input(event)


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
	
	# Middle segments
	for i in range(1, length - 1):
		var loc := start + dv * i
		wire = _place_wire_part(loc, direction, wire)
		wire = _place_wire_part(loc, Direction.opposite(direction), wire)
	_simulation.finish_atomic()


func _get_endpoint_wire(loc: Vector2, direction: int) -> int:
	var wire := -1
	for _i in range(4):
		if _tile_wires[loc].has(direction):
			wire = _tile_wires[loc][direction]
			break
		direction = Direction.rotate_left(direction)
	return wire


func _place_wire_part(loc: Vector2, direction: int, wire_id: int) -> int:
	if _tile_wires[loc].has(direction):
		var new_wire = _tile_wires[loc][direction]
		if wire_id == -1:
			wire_id = new_wire
		elif wire_id != new_wire:
			_merge_wire(wire_id, new_wire)
	else:
		if wire_id == -1:
			wire_id = _create_wire()
		_tile_wires[loc][direction] = wire_id
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
	return wire_id


func _merge_wire(dst: int, src: int) -> void:
	assert(dst != -1)
	if src == dst or src == -1:
		return
	_simulation.start_atomic()
	_free_wires.append(src)
	_simulation.finish_atomic()


class Mode:
	var world
	
	func _init(w) -> void:
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
	var selected_tile: Vector2
	
	func _init(w).(w): pass
	
	func input(event: InputEvent) -> void:
		if event is InputEventMouseMotion:
			pass


class Wire:
	func _init():
		pass
