extends Label

onready var world: WiregridWorld = $"../.."

func _process(_delta: float) -> void:
	text = ""
	text += "FPS: %s\n" % Engine.get_frames_per_second()
	text += "\n"
	text += "X: %s Y: %s\n" % [world.cursor.x, world.cursor.y]
