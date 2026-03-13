extends Node2D

func _ready() -> void:
	# Enable immersive mode on Android
	if OS.has_feature("android"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		DisplayServer.screen_set_keep_on(true)
	else:
		_adapt_desktop_window()


func _adapt_desktop_window() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
