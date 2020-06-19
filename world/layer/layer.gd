extends Node2D

const Component := TileGrid.ComponentType
const State := TileGrid.State
const Direction := preload("res://direction.gd")
const Rotation := Direction.Rotation

onready var wire_top := $WireTop
onready var input := $Input
onready var output := $Output
onready var body := $Body
onready var wire_bottom := $WireBottom


func world_to_map(pos: Vector2) -> Vector2:
	return self.wire_bottom.world_to_map(pos)


func clear() -> void:
	self.wire_top.clear()
	self.input.clear()
	self.output.clear()
	self.body.clear()
	self.wire_bottom.clear()


func place_wire(pos: Vector2, wire: int, direction: int, states: Array) -> void:
	self.wire_bottom.set_tile(pos, wire, direction, states)


func place_component(pos: Vector2, component: int, direction: int, input_state: int, output_state: int) -> void:
	input.set_tile(pos, component, direction, [input_state])
	output.set_tile(pos, component, direction, [output_state])
	body.set_tile(pos, component, direction, [])
