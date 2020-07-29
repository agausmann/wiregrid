extends Label

func _process(_delta: float) -> void:
	var world: WiregridWorld = $"../.."
	text = ""
	text += "FPS: %s\n" % Engine.get_frames_per_second()
