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
	if _changing or item == null or item.category in [ItemData.ItemCategory.KEY_ITEM, ItemData.ItemCategory.DUNGEON_ITEM, ItemData.ItemCategory.QUEST_ITEM] or not has_item(item_id, amount):
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


func can_exchange_quest_items(removals: Dictionary, additions: Dictionary) -> bool:
	if _changing:
		return false
	for id: StringName in removals:
		var item: ItemData = ItemDatabase.get_item(id)
		var amount: int = int(removals[id])
		if item == null or item.category != ItemData.ItemCategory.QUEST_ITEM or amount <= 0 or not has_item(id, amount):
			return false
	for id: StringName in additions:
		var item: ItemData = ItemDatabase.get_item(id)
		var amount: int = int(additions[id])
		if item == null or amount <= 0 or get_quantity(id) - int(removals.get(id, 0)) + amount > item.quantity_limit():
			return false
	return true


func exchange_quest_items(removals: Dictionary, additions: Dictionary) -> bool:
	# Snapshot transaction inputs before synchronous notification callbacks.
	var removed: Dictionary = removals.duplicate()
	var added: Dictionary = additions.duplicate()
	if not can_exchange_quest_items(removed, added):
		return false
	_changing = true
	for id: StringName in removed:
		_decrease(id, int(removed[id]))
	for id: StringName in added:
		if not _entries.has(id):
			_entries[id] = InventoryEntry.new(id)
		var entry: InventoryEntry = _entries[id]
		entry.quantity += int(added[id])
	if not removed.is_empty() or not added.is_empty():
		inventory_changed.emit()
	for id: StringName in removed:
		item_removed.emit(id, int(removed[id]))
	for id: StringName in added:
		item_added.emit(id, int(added[id]))
	_changing = false
	return true


func to_save_data() -> Dictionary:
	var items: Array[Dictionary] = []
	for entry: InventoryEntry in get_entries():
		items.append({"item_id": str(entry.item_id), "quantity": entry.quantity})
	return {"items": items}


func load_save_data(data: Dictionary) -> void:
	_entries.clear()
	for raw: Variant in SaveValues.array(data.get("items", [])):
		var saved: Dictionary = SaveValues.dictionary(raw)
		var id: StringName = SaveValues.identifier(saved.get("item_id"))
		if id.is_empty():
			continue
		var item: ItemData = ItemDatabase.get_item(id)
		if item == null:
			continue # Removed development items do not invalidate the whole slot.
		var quantity: int = SaveValues.integer(saved.get("quantity"), 0, 0, item.quantity_limit())
		if quantity > 0 and not _entries.has(id):
			_entries[id] = InventoryEntry.new(id, quantity)
	_changing = false
	last_use_message = ""
	inventory_changed.emit() # Restore never emits item_added or grants quest progress.


func reset_runtime_state() -> void:
	load_save_data({})
