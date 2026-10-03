extends Node

const ITEM_PATHS: Array[String] = [
	"res://game/items/data/consumables/small_healing_drink.tres",
	"res://game/items/data/key_items/shrine_charm.tres",
	"res://game/items/data/materials/spirit_fragment.tres",
	"res://game/items/data/dungeon_items/ember_gauntlet.tres",
	"res://game/items/data/quest_items/lost_lucky_charm.tres",
	"res://game/items/data/consumables/energy_soda.tres"
]

var _items: Dictionary = {}


func _ready() -> void:
	# Load once at runtime, after Godot has imported textures on first open.
	for path: String in ITEM_PATHS:
		var item: ItemData = load(path) as ItemData
		if item == null or not item.is_valid_definition():
			push_warning("ItemDatabase rejected an invalid definition.")
			continue
		if _items.has(item.id):
			push_warning("ItemDatabase rejected duplicate ID: " + str(item.id))
			continue
		_items[item.id] = item


func get_item(item_id: StringName) -> ItemData:
	var item: ItemData = _items.get(item_id) as ItemData
	if item == null:
		push_warning("Unknown item ID: " + str(item_id))
	return item
