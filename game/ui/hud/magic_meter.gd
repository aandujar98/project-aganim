@tool
class_name MagicMeter
extends Control
## Blue orb row for magic. No magic system exists yet; the meter hides itself
## while maximum is 0 and is fed through set_values() once one does.

const ATLAS: Texture2D = preload("res://art/ui/hud/magic_orb.png")
const ORB: Vector2i = Vector2i(12, 12)
const SPACING: int = 14

@export var current: int = 0:
	set(value):
		current = value
		queue_redraw()
@export var maximum: int = 0:
	set(value):
		maximum = value
		visible = maximum > 0
		queue_redraw()


func set_values(value: int, max_value: int) -> void:
	current = value
	maximum = max_value


func _draw() -> void:
	for i: int in maximum:
		var frame: int = 0 if i < current else 1
		draw_texture_rect_region(ATLAS, Rect2(Vector2(i * SPACING, 0), ORB), Rect2(frame * ORB.x, 0, ORB.x, ORB.y))
