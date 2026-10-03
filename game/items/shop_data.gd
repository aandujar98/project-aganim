class_name ShopData
extends Resource

@export var id: StringName
@export var display_name: String
@export var entries: Array[ShopEntryData] = []


func is_valid_definition() -> bool:
	return not id.is_empty() and not display_name.is_empty()
