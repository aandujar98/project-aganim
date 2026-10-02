extends Node

signal state_changed(dungeon_id: StringName)
signal active_dungeon_changed(dungeon_id: StringName)

var active_dungeon_id: StringName = &""
var _states: Dictionary = {}


func enter_dungeon(id: StringName) -> void:
	if not id.is_empty():
		get_state(id)
	if active_dungeon_id != id:
		active_dungeon_id = id
		active_dungeon_changed.emit(id)


func get_state(id: StringName) -> DungeonState:
	if id.is_empty():
		push_error("Dungeon state requires an explicit stable dungeon ID.")
		return null
	if not _states.has(id):
		_states[id] = DungeonState.new(id)
	return _states[id] as DungeonState


func add_small_keys(id: StringName, amount: int = 1) -> bool:
	if id.is_empty() or amount <= 0:
		return false
	get_state(id).small_keys += amount
	state_changed.emit(id)
	return true


func remove_small_keys(id: StringName, amount: int = 1) -> bool:
	if id.is_empty() or amount <= 0 or get_state(id).small_keys < amount:
		return false
	get_state(id).small_keys -= amount
	state_changed.emit(id)
	return true


func unlock_with_key(id: StringName, door_id: StringName) -> bool:
	if id.is_empty() or door_id.is_empty():
		return false
	var state: DungeonState = get_state(id)
	if state.unlocked_doors.has(door_id):
		return true
	if state.small_keys < 1:
		return false
	# Commit both fields before notifying listeners: one key, once per door.
	state.small_keys -= 1
	state.unlocked_doors[door_id] = true
	state_changed.emit(id)
	return true


func set_flag(id: StringName, collection: StringName, object_id: StringName) -> bool:
	if id.is_empty() or object_id.is_empty() or collection not in [&"activated_switches", &"unlocked_doors", &"opened_chests", &"cleared_rooms"]:
		return false
	var flags: Dictionary = get_state(id).get(collection)
	if not flags.has(object_id):
		flags[object_id] = true
		state_changed.emit(id)
	return true


func has_flag(id: StringName, collection: StringName, object_id: StringName) -> bool:
	if id.is_empty() or collection not in [&"activated_switches", &"unlocked_doors", &"opened_chests", &"cleared_rooms"]:
		return false
	var flags: Dictionary = get_state(id).get(collection)
	return flags.has(object_id)


func mark_item_obtained(id: StringName) -> void:
	get_state(id).dungeon_item_obtained = true
	state_changed.emit(id)


func finish_room(id: StringName, room_id: StringName, encounter: int = 0) -> void:
	var state: DungeonState = get_state(id)
	state.cleared_rooms[room_id] = true
	if encounter == 1:
		state.miniboss_defeated = true
	elif encounter == 2:
		state.boss_defeated = true
		state.completed = true
	state_changed.emit(id)


func reset_dungeon(id: StringName) -> void:
	# Development only: reload the room after reset to reconstruct enemies.
	if not OS.is_debug_build() or id.is_empty():
		return
	_states[id] = DungeonState.new(id)
	state_changed.emit(id)
