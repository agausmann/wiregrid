extends Label

func _process(_delta: float) -> void:
	text = ""
	text += "FPS: %s\n" % Engine.get_frames_per_second()
