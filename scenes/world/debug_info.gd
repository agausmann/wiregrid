extends Label

onready var world: WiregridWorld = $"../.."

func _process(_delta: float) -> void:
	text = ""
	text += "FPS: %s\n" % Engine.get_frames_per_second()
	text += "\n"
	text += "Cursor: x %s, y %s\n" % [world.cursor.x, world.cursor.y]
	text += "Tile: x %s, y %s\n" % [world.cursor_tile.x, world.cursor_tile.y]
	text += "\n"
	text += "Pan: x %s, y %s\n" % [world.pan.x, world.pan.y]
	text += "Zoom: %s\n" % world.zoom
