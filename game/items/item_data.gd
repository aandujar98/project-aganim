class_name ItemData
extends Resource

enum ItemCategory { CONSUMABLE, KEY_ITEM, MATERIAL, COLLECTIBLE, DUNGEON_ITEM }

@export var id: StringName
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var category: ItemCategory = ItemCategory.MATERIAL
@export var stackable: bool = true
@export_range(1, 999, 1) var max_stack: int = 99
@export var use_effect: StringName
@export_range(0, 100, 1) var effect_value: int = 0


func is_valid_definition() -> bool:
	return not id.is_empty() and not display_name.is_empty() and max_stack > 0 and category >= ItemCategory.CONSUMABLE and category <= ItemCategory.DUNGEON_ITEM


func quantity_limit() -> int:
	# Key and dungeon items are unique, regardless of the Inspector stackable flag.
	return max_stack if stackable and category not in [ItemCategory.KEY_ITEM, ItemCategory.DUNGEON_ITEM] else 1


func category_name() -> String:
	return ["Consumable", "Key Item", "Material", "Collectible", "Dungeon Item"][category]
