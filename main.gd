extends Control

var pan_speed := 800.0
var mouse_panning := false
var pan_input := Vector2.ZERO
var current_pan := Vector2.ZERO
var zoom_speed := 2.0
var zoom_step := 0.2
var zoom_input := 0.0
var current_zoom := 1.0
var cursor_speed := 20.0
var cursor_input := Vector2.ZERO
onready var world_view := $WorldView/Viewport
onready var world := $WorldView/Viewport/World


func _input(event: InputEvent) -> void:
	if event.is_action("pan_modifier"):
		mouse_panning = event.is_action_pressed("pan_modifier")
	if event is InputEventMouseMotion and mouse_panning:
		current_pan += event.relative / current_zoom
	if event.is_action("pan_up") or event.is_action("pan_down") \
			or event.is_action("pan_left") or event.is_action("pan_right"):
		pan_input = (
			Vector2.UP * Input.get_action_strength("pan_up")
			+ Vector2.DOWN * Input.get_action_strength("pan_down")
			+ Vector2.LEFT * Input.get_action_strength("pan_left")
			+ Vector2.RIGHT * Input.get_action_strength("pan_right")
		)
	if event.is_action("zoom_in") or event.is_action("zoom_out"):
		zoom_input = (
			Input.get_action_strength("zoom_in")
			- Input.get_action_strength("zoom_out")
		)
	if event.is_action_pressed("zoom_in_step"):
		current_zoom *= (1 + zoom_step)
	if event.is_action_pressed("zoom_out_step"):
		current_zoom *= 1 / (1 + zoom_step)
	if event.is_action("cursor_up") or event.is_action("cursor_down") \
			or event.is_action("cursor_left") or event.is_action("cursor_right"):
		cursor_input = (
			Vector2.UP * Input.get_action_strength("cursor_up")
			+ Vector2.DOWN * Input.get_action_strength("cursor_down")
			+ Vector2.LEFT * Input.get_action_strength("cursor_left")
			+ Vector2.RIGHT * Input.get_action_strength("cursor_right")
		)


func _process(delta: float) -> void:
	current_pan -= (pan_speed * delta / current_zoom) * pan_input
	current_zoom *= 1 + (zoom_speed * delta * zoom_input)
	current_zoom = clamp(current_zoom, 0.5, 8)
	if cursor_input.length_squared() > 0.1:
		Input.warp_mouse_position(get_global_mouse_position() + cursor_speed * cursor_input)
	world_view.set_canvas_transform(Transform2D(
		Vector2(current_zoom, 0),
		Vector2(0, current_zoom),
		current_pan * current_zoom + world_view.size / 2
	))
