class_name CameraBounds
extends Node2D

@export var bounds: Rect2i = Rect2i(0, 0, 384, 216)


func is_valid() -> bool:
	var viewport_size: Vector2i = Vector2i(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		ProjectSettings.get_setting("display/window/size/viewport_height")
	)
	return bounds.size.x >= viewport_size.x and bounds.size.y >= viewport_size.y


func apply_to(camera: Camera2D) -> void:
	var origin: Vector2i = Vector2i(global_position.round()) + bounds.position
	camera.limit_left = origin.x
	camera.limit_top = origin.y
	camera.limit_right = origin.x + bounds.size.x
	camera.limit_bottom = origin.y + bounds.size.y
	camera.position_smoothing_enabled = false
	camera.limit_smoothed = false
	camera.reset_smoothing()
	camera.force_update_scroll()
