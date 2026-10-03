@tool
class_name HeartMeter
extends Control
## Heart row for health. By default one health point fills one heart, so the
## Player's starting 6 health shows six hearts. Set health_per_heart to 2 for half hearts.

const ATLAS: Texture2D = preload("res://art/ui/hud/heart.png")
const HEART: Vector2i = Vector2i(12, 11)
const SPACING: int = 14

@export_range(1, 4, 1) var health_per_heart: int = 1
@export_range(1, 20, 1) var hearts_per_row: int = 10
@export var current: int = 6:
	set(value):
		current = value
		queue_redraw()
@export var maximum: int = 6:
	set(value):
		maximum = value
		queue_redraw()


func set_values(value: int, max_value: int) -> void:
	current = value
	maximum = max_value


func _draw() -> void:
	var count: int = ceili(float(maximum) / health_per_heart)
	for i: int in count:
		var filled: int = clampi(current - i * health_per_heart, 0, health_per_heart)
		# Atlas frames: 0 full, 1 half, 2 empty.
		var frame: int = 0 if filled == health_per_heart else (2 if filled == 0 else 1)
		var row: int = floori(i / float(hearts_per_row))
		var at: Vector2 = Vector2((i % hearts_per_row) * SPACING, row * (HEART.y + 3))
		draw_texture_rect_region(ATLAS, Rect2(at, HEART), Rect2(frame * HEART.x, 0, HEART.x, HEART.y))
