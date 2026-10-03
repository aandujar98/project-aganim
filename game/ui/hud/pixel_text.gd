@tool
class_name PixelText
extends Control
## Draws short HUD strings (quantities, Yen, area names) from the proportional
## 7px pixel font atlas. Glyphs carry a baked 1px outline so they stay readable
## over any world background. Origin is the top of the capital letters.

const ATLAS: Texture2D = preload("res://art/ui/hud/pixel_font.png")
const GLYPHS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789¥-×.,: /abcdefghijklmnopqrstuvwxyz"
## Ink width of each glyph in GLYPHS order; characters advance by width + 1.
const WIDTHS: PackedByteArray = [4, 4, 4, 4, 4, 4, 4, 4, 3, 4, 4, 4, 5, 4, 4, 4, 4, 4, 4, 5, 4, 5, 5, 4, 5, 4,
	4, 3, 4, 4, 4, 4, 4, 4, 4, 4, 5, 3, 3, 1, 2, 1, 2, 4,
	4, 4, 3, 4, 4, 3, 4, 4, 1, 2, 4, 2, 5, 4, 4, 4, 4, 3, 4, 3, 4, 3, 5, 3, 4, 4]
const CELL: Vector2i = Vector2i(7, 11)

enum Align { LEFT, CENTER, RIGHT }

@export var text: String = "":
	set(value):
		text = value
		queue_redraw()
@export var align: Align = Align.LEFT:
	set(value):
		align = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func text_width() -> int:
	var width: int = 0
	for character: String in text:
		var index: int = GLYPHS.find(character)
		width += (WIDTHS[index] if index >= 0 else 2) + 1
	return maxi(width - 1, 0)


func _draw() -> void:
	var x: int = 0
	if align == Align.CENTER:
		x = int((size.x - text_width()) / 2.0)
	elif align == Align.RIGHT:
		x = int(size.x) - text_width()
	for character: String in text:
		var index: int = GLYPHS.find(character)
		if index < 0:
			x += 3
			continue
		# Each atlas cell holds the glyph at (1, 1) inside its outline margin.
		draw_texture_rect_region(ATLAS, Rect2(x - 1, -1, CELL.x, CELL.y), Rect2(index * CELL.x, 0, CELL.x, CELL.y))
		x += WIDTHS[index] + 1
