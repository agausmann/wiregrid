class_name WiregridWorld
extends Node2D

const Component := preload("res://util/component.gd")
const Direction := preload("res://util/direction.gd")
const Simulation := preload("res://simulation/simulation.gdns")
const Wire := preload("res://scenes/wire/wire.tscn")

var pan_speed := 30.0
var zoom_speed := 2.0
var zoom_step := 0.05
var min_zoom := 0.5
var max_zoom := 8.0

var pan := Vector2.ZERO
var zoom := 1.0

var cursor := Vector2.ZERO
var cursor_tile := Vector2.ZERO

var _simulation := Simulation.new()


func _ready():
	var wire := Wire.instance()
	add_child(wire)
	wire.add_segment(WireSegment.new(Vector2.ZERO, Direction.RIGHT, Direction.Relative.LEFT, 5))
	wire.add_component(BufferComponent.new(Vector2(3, -2), Direction.RIGHT))
	wire.add_component(InverterComponent.new(Vector2.ZERO, Direction.DOWN))
	#wire.current_state = true
	#wire.buffer_state = true


func _process(delta: float) -> void:
	pan += delta * pan_speed / zoom * (
		Vector2.RIGHT * Input.get_action_strength("pan_right")
		+ Vector2.LEFT * Input.get_action_strength("pan_left")
		+ Vector2.UP * Input.get_action_strength("pan_up")
		+ Vector2.DOWN * Input.get_action_strength("pan_down")
	)
	zoom_in(1.0 + delta * zoom_speed * (
		Input.get_action_strength("zoom_in")
		- Input.get_action_strength("zoom_out")
	))
	
	get_viewport().canvas_transform = Transform2D(
		Vector2(zoom, 0.0),
		Vector2(0.0, zoom),
		0.5 * get_viewport_rect().size - 16 * pan * zoom
	)
	cursor = get_local_mouse_position()
	cursor_tile = cursor.floor()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in_step"):
		zoom_in(1.0 + zoom_step)
	if event.is_action_pressed("zoom_out_step"):
		zoom_in(1.0 / (1.0 + zoom_step))


func zoom_in(z: float) -> void:
	if z == 1.0:
		return
	z = clamp(zoom * z, min_zoom, max_zoom) / zoom
	zoom *= z
	pan = cursor + (pan - cursor) / z


func is_wire_valid(segment: WireSegment) -> bool:
	return false


func place_wire(segment: WireSegment) -> void:
	pass


func remove_wire(segment: WireSegment) -> void:
	pass


func is_component_valid(component: Component) -> bool:
	return false


func place_component(component: Component) -> void:
	pass


func remove_component(component: Component) -> void:
	pass
