extends Node2D

func _ready() -> void:
	# Enable immersive mode on Android
	if OS.has_feature("android"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_KEEP_SCREEN_ON, true)
