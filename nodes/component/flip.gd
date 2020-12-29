class_name FlipComponent
extends Component

const BODY_TEXTURE = preload("res://assets/flip/body.png")
const INPUT_TEXTURE = preload("res://assets/flip/input.png")
const OUTPUT_TEXTURE = preload("res://assets/flip/output.png")

const Direction = preload("res://util/direction.gd")

var location: Vector2 setget set_location
var direction: int setget set_direction
var untinted: Node2D

func _init(location: Vector2, direction: int) -> void:
	state_tinted = Sprite.new()
	state_tinted.scale = Vector2(1.0 / 16, 1.0 / 16)
	state_tinted.texture = INPUT_TEXTURE
	state_tinted.z_index = 2
	
	flip_tinted = Sprite.new()
	flip_tinted.scale = Vector2(1.0 / 16, 1.0 / 16)
	flip_tinted.texture = OUTPUT_TEXTURE
	
	untinted = Sprite.new()
	untinted.scale = Vector2(1.0 / 16, 1.0 / 16)
	untinted.texture = BODY_TEXTURE
	add_child(untinted)
	
	set_location(location)
	set_direction(direction)


func set_location(new_location: Vector2) -> void:
	location = new_location
	var offset = location + Vector2(0.5, 0.5)
	self.state_tinted.position = offset
	self.flip_tinted.position = offset
	self.untinted.position = offset


func set_direction(new_direction: int) -> void:
	direction = new_direction
	self.state_tinted.rotation = Direction.radians(Direction.relative(Direction.LEFT, direction))
	self.flip_tinted.rotation = Direction.radians(Direction.relative(Direction.RIGHT, direction))
	self.untinted.rotation = Direction.radians(Direction.relative(Direction.RIGHT, direction))
