class_name CameraBounds
extends Node2D

@export var bounds: Rect2i = Rect2i(0, 0, 384, 216)


func is_valid() -> bool:
	# Rooms smaller than the view are allowed; apply_to() centers them.
	return bounds.size.x > 0 and bounds.size.y > 0


func apply_to(camera: Camera2D) -> void:
	var origin: Vector2i = Vector2i(global_position.round()) + bounds.position
	var limits: Rect2i = Rect2i(origin, bounds.size)
	# Grow undersized rooms evenly around their center so they sit mid-screen
	# (the clear color fills the margin) instead of pinning to the top-left.
	var view: Vector2i = Vector2i((camera.get_viewport_rect().size / camera.zoom).ceil())
	var extra: Vector2i = (view - limits.size).max(Vector2i.ZERO)
	limits = limits.grow_individual(extra.x >> 1, extra.y >> 1, extra.x - (extra.x >> 1), extra.y - (extra.y >> 1))
	camera.limit_left = limits.position.x
	camera.limit_top = limits.position.y
	camera.limit_right = limits.end.x
	camera.limit_bottom = limits.end.y
	camera.position_smoothing_enabled = false
	camera.limit_smoothed = false
	camera.reset_smoothing()
	camera.force_update_scroll()
