@tool
class_name QuickSlot
extends Control
## One HUD quick-use slot: frame, icon, button badge, and optional quantity.
## Display only; assigning and using items is a later inventory feature.

const FRAME: Texture2D = preload("res://art/ui/hud/slot_frame.png")
const FRAME_SELECTED: Texture2D = preload("res://art/ui/hud/slot_frame_selected.png")
const BADGES: Texture2D = preload("res://art/ui/hud/button_badges.png")
const BADGE_ORDER: String = "AYXRBL"
const SLOT_SIZE: Vector2i = Vector2i(26, 26)
const BADGE_SIZE: Vector2i = Vector2i(14, 13)
const ICON_SIZE: Vector2i = Vector2i(16, 16)

## Button label drawn under the slot. Labels describe the default gamepad layout
## and may change when control remapping is designed.
@export_enum("A", "Y", "X", "R", "B", "L") var button: String = "A":
	set(value):
		button = value
		queue_redraw()
@export var selected: bool = false:
	set(value):
		selected = value
		queue_redraw()
## Fixed icon (e.g. the sword). Replaced by the item's icon when item_id resolves.
@export var icon: Texture2D:
	set(value):
		icon = value
		queue_redraw()
## Optional inventory item shown in this slot; its quantity comes from Inventory.
@export var item_id: StringName
@export var show_quantity: bool = true
## Presentation-only count for slots without an item_id (visual test scenes).
## -1 hides the number.
@export var preview_quantity: int = -1

var _quantity: int = -1
var _quantity_label: PixelText


func _ready() -> void:
	custom_minimum_size = Vector2(SLOT_SIZE.x, SLOT_SIZE.y + BADGE_SIZE.y - 4)
	_quantity_label = PixelText.new()
	_quantity_label.align = PixelText.Align.RIGHT
	_quantity_label.position = Vector2(0, SLOT_SIZE.y - 11)
	_quantity_label.size = Vector2(SLOT_SIZE.x - 3, 9)
	add_child(_quantity_label)
	if not Engine.is_editor_hint() and not item_id.is_empty():
		var item: ItemData = ItemDatabase.get_item(item_id)
		if item != null and item.icon != null:
			icon = item.icon
		Inventory.inventory_changed.connect(refresh)
	refresh()


func refresh() -> void:
	if item_id.is_empty() or Engine.is_editor_hint():
		_quantity = preview_quantity
	else:
		_quantity = Inventory.get_quantity(item_id)
	_quantity_label.text = str(_quantity) if show_quantity and _quantity > 0 else ""
	queue_redraw()


func _draw() -> void:
	draw_texture(FRAME_SELECTED if selected else FRAME, Vector2.ZERO)
	if icon != null:
		# An inventory item with an empty stack is dimmed but still identifies the slot.
		var tint: Color = Color(1, 1, 1, 0.35) if _quantity == 0 and not item_id.is_empty() else Color.WHITE
		var at: Vector2 = (Vector2(SLOT_SIZE - ICON_SIZE) / 2.0).floor()
		draw_texture_rect(icon, Rect2(at, Vector2(ICON_SIZE)), false, tint)
	var badge_index: int = BADGE_ORDER.find(button)
	var badge_at: Vector2 = Vector2((SLOT_SIZE.x - BADGE_SIZE.x) / 2.0, SLOT_SIZE.y - 4).floor()
	draw_texture_rect_region(BADGES, Rect2(badge_at, Vector2(BADGE_SIZE)), Rect2(badge_index * BADGE_SIZE.x, 0, BADGE_SIZE.x, BADGE_SIZE.y))
