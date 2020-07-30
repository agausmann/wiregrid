class_name WiregridWorld
extends Node2D

const Component := preload("res://util/component.gd")
const Direction := preload("res://util/direction.gd")
const Simulation := preload("res://simulation/simulation.gdns")

var pan_speed := 500.0
var zoom_speed := 2.0
var zoom_step := 0.05
var min_zoom := 0.5
var max_zoom := 8.0

var pan := Vector2.ZERO
var zoom := 1.0

var wires := []
var segments := []
var tiles := {}
var _free_wires := []
var _free_segments := []
var _simulation := Simulation.new()


func _process(delta: float) -> void:
	pan += delta * pan_speed / zoom * (
		Vector2.RIGHT * Input.get_action_strength("pan_right")
		+ Vector2.LEFT * Input.get_action_strength("pan_left")
		+ Vector2.UP * Input.get_action_strength("pan_up")
		+ Vector2.DOWN * Input.get_action_strength("pan_down")
	)
	zoom *= 1 + delta * zoom_speed * (
		Input.get_action_strength("zoom_in")
		- Input.get_action_strength("zoom_out")
	)
	zoom = clamp(zoom, min_zoom, max_zoom)
	
	get_viewport().canvas_transform = Transform2D(
		Vector2(zoom, 0.0),
		Vector2(0.0, zoom),
		0.5 * get_viewport_rect().size - pan * zoom
	)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("zoom_in_step"):
		zoom *= 1 + zoom_step
	if event.is_action_pressed("zoom_out_step"):
		zoom /= 1 + zoom_step
