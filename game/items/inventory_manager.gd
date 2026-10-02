extends Node

signal inventory_changed
signal item_added(item_id: StringName, amount: int)
signal item_removed(item_id: StringName, amount: int)
signal item_used(item_id: StringName)

var last_use_message: String = ""
var _entries: Dictionary = {}
var _changing: bool = false


func get_quantity(item_id: StringName) -> int:
	var entry: InventoryEntry = _entries.get(item_id) as InventoryEntry
	return entry.quantity if entry != null else 0


func has_item(item_id: StringName, amount: int = 1) -> bool:
	return amount > 0 and get_quantity(item_id) >= amount


func get_entries() -> Array[InventoryEntry]:
	# Return snapshots so UI/callers cannot alter owned quantities by reference.
	var contents: Array[InventoryEntry] = []
	for entry: InventoryEntry in _entries.values():
		contents.append(InventoryEntry.new(entry.item_id, entry.quantity))
	return contents


func can_add_item(item_id: StringName, amount: int = 1) -> bool:
	var item: ItemData = ItemDatabase.get_item(item_id)
	return not _changing and item != null and amount > 0 and amount <= item.quantity_limit() - get_quantity(item_id)


func add_item(item_id: StringName, amount: int = 1) -> bool:
	if not can_add_item(item_id, amount):
		return false
	_changing = true
	if not _entries.has(item_id):
		_entries[item_id] = InventoryEntry.new(item_id)
	var entry: InventoryEntry = _entries[item_id]
	entry.quantity += amount
	inventory_changed.emit()
	item_added.emit(item_id, amount)
	_changing = false
	return true


func remove_item(item_id: StringName, amount: int = 1) -> bool:
	var item: ItemData = ItemDatabase.get_item(item_id)
	if _changing or item == null or item.category in [ItemData.ItemCategory.KEY_ITEM, ItemData.ItemCategory.DUNGEON_ITEM] or not has_item(item_id, amount):
		return false
	_changing = true
	_decrease(item_id, amount)
	inventory_changed.emit()
	item_removed.emit(item_id, amount)
	_changing = false
	return true


func use_item(item_id: StringName, actor: CharacterBody2D) -> bool:
	var item: ItemData = ItemDatabase.get_item(item_id)
	if _changing or item == null or not has_item(item_id):
		last_use_message = "That item is not available."
		return false
	last_use_message = ItemEffectHandler.failure_reason(item, actor)
	if not last_use_message.is_empty():
		return false
	# Health signals can call back into gameplay; guard the entire transaction.
	_changing = true
	if not ItemEffectHandler.apply(item, actor):
		_changing = false
		last_use_message = "The item could not be used."
		return false
	_decrease(item_id, 1)
	last_use_message = "Used %s." % item.display_name
	inventory_changed.emit()
	item_removed.emit(item_id, 1)
	item_used.emit(item_id)
	_changing = false
	return true


func _decrease(item_id: StringName, amount: int) -> void:
	var entry: InventoryEntry = _entries[item_id]
	entry.quantity -= amount
	if entry.quantity == 0:
		_entries.erase(item_id)
