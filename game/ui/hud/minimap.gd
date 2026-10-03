@tool
class_name Minimap
extends Control
## Framed overview that scrolls a pre-rendered area map around the player, with
## the area name in the frame's bottom bar. Areas without a map texture still
## show the frame and name.

const FRAME: Texture2D = preload("res://art/ui/hud/minimap_frame.png")
const MARKER: Texture2D = preload("res://art/ui/hud/minimap_player.png")
## Map window inside the frame, and the name bar below it.
const VIEW_RECT: Rect2i = Rect2i(3, 3, 54, 58)
const LABEL_TOP: int = 64

@export var map_texture: Texture2D:
	set(value):
		map_texture = value
		queue_redraw()
## Minimap pixels per world pixel (the area map is rendered at quarter scale).
@export var map_scale: float = 0.25
@export var area_name: String = "":
	set(value):
		area_name = value
		if _label != null:
			_label.text = value

var target: Node2D
var _label: PixelText


func _ready() -> void:
	custom_minimum_size = Vector2(FRAME.get_size())
	_label = PixelText.new()
	_label.align = PixelText.Align.CENTER
	_label.position = Vector2(0, LABEL_TOP)
	_label.size = Vector2(FRAME.get_width(), 9)
	_label.text = area_name
	add_child(_label)


func _process(_delta: float) -> void:
	if is_instance_valid(target):
		queue_redraw()


func _draw() -> void:
	var view: Vector2 = Vector2(VIEW_RECT.size)
	var view_at: Vector2 = Vector2(VIEW_RECT.position)
	draw_rect(Rect2(view_at, view), Color(0.05, 0.05, 0.12))
	if map_texture != null:
		var map_size: Vector2 = map_texture.get_size()
		var focus: Vector2 = map_size * 0.5
		if is_instance_valid(target):
			focus = (target.global_position * map_scale).round()
		# Keep the visible window inside the map so the frame never shows empty space.
		var origin: Vector2 = (focus - view * 0.5).clamp(Vector2.ZERO, (map_size - view).max(Vector2.ZERO)).round()
		var region: Rect2 = Rect2(origin, view.min(map_size))
		draw_texture_rect_region(map_texture, Rect2(view_at, region.size), region)
		if is_instance_valid(target):
			var marker_at: Vector2 = view_at + focus - origin - Vector2(MARKER.get_size()) * 0.5
			draw_texture(MARKER, marker_at.round())
	draw_texture(FRAME, Vector2.ZERO)
