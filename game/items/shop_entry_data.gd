class_name ShopEntryData
extends Resource

@export var item_id: StringName
@export var price_override: int = -1
@export var stock: int = -1


func is_valid_definition() -> bool:
	return not item_id.is_empty() and price_override >= -1 and stock >= -1
