class_name InventoryEntry
extends RefCounted

var item_id: StringName
var quantity: int


func _init(entry_id: StringName = &"", amount: int = 0) -> void:
	item_id = entry_id
	quantity = amount
