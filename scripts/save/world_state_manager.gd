extends Node

signal state_changed(category: StringName, object_id: StringName)
const CATEGORIES: Array[StringName] = [&"opened_chests", &"opened_doors", &"activated_switches", &"collected_pickups", &"defeated_unique_enemies", &"story_objects"]
var _flags: Dictionary = {}


func has_flag(category: StringName, id: StringName) -> bool:
	return _flags.has(category) and _flags[category].has(id)


func set_flag(category: StringName, id: StringName) -> bool:
	if category not in CATEGORIES or id.is_empty():
		return false
	if not _flags.has(category):
		_flags[category] = {}
	if not _flags[category].has(id):
		_flags[category][id] = true
		state_changed.emit(category, id)
	return true


func to_save_data() -> Dictionary:
	var data: Dictionary = {}
	for category: StringName in CATEGORIES:
		data[str(category)] = _flags.get(category, {}).keys()
	return data


func load_save_data(data: Dictionary) -> void:
	_flags.clear()
	for category: StringName in CATEGORIES:
		_flags[category] = SaveValues.flags(data.get(str(category), []))


func reset_runtime_state() -> void:
	_flags.clear()
