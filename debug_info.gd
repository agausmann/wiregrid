extends Label

const Direction := preload("res://direction.gd")

func _process(_delta: float) -> void:
	var world: WiregridWorld = $"..".world
	text = ""
	text += "Selected tile: %s\n" % world.selected_tile
	
	text += "Wires:\n"
	var wire_connections = world._tile_wires.get(world.selected_tile, {})
	var directions := [
		Direction.LEFT,
		Direction.RIGHT,
		Direction.UP,
		Direction.DOWN,
	]
	for direction in directions:
		text += "    %s: %d\n" % [
			Direction.to_str(direction),
			wire_connections.get(direction, -1),
		]
