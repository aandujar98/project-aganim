extends Node

signal game_saved(slot: int)
signal game_loaded(slot: int)
signal slots_changed
signal operation_failed(message: String)

const CURRENT_SAVE_VERSION: int = SaveSchema.CURRENT_SAVE_VERSION
const SLOT_COUNT: int = 3
const SAVE_DIRECTORY: String = "user://saves"
const START_SCENE: String = "res://game/world/districts/transition_test/test_exterior.tscn"
const MAX_FILE_BYTES: int = 2097152
var active_slot: int = -1
var busy: bool = false
var last_error: String = ""
var _schema: SaveSchema = SaveSchema.new()


func slot_path(slot: int) -> String:
	return SAVE_DIRECTORY + "/slot_%02d.json" % slot if slot >= 1 and slot <= SLOT_COUNT else ""


func has_save(slot: int) -> bool:
	return not slot_path(slot).is_empty() and FileAccess.file_exists(slot_path(slot))


func _read_slot(slot: int) -> Dictionary:
	var path: String = slot_path(slot)
	if path.is_empty() or not FileAccess.file_exists(path):
		last_error = "Save slot is empty or invalid."
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > MAX_FILE_BYTES:
		last_error = "Cannot read save file (missing access or oversized file)."
		return {}
	var json: JSON = JSON.new()
	var parse_error: Error = json.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		last_error = "Corrupted save: " + json.get_error_message()
		return {}
	var data: Dictionary = _schema.validate_and_migrate(json.data)
	last_error = _schema.error
	return data


func get_slot_metadata(slot: int) -> Dictionary:
	if not has_save(slot):
		return {"empty": true}
	var data: Dictionary = _read_slot(slot)
	if data.is_empty():
		return {"empty": false, "corrupted": true, "error": last_error}
	var metadata: Dictionary = SaveValues.dictionary(data.get("metadata", {}))
	return {"empty": false, "corrupted": false, "player_name": data.profile.name,
		"playtime_seconds": SaveValues.integer(data.profile.get("playtime_seconds", 0)),
		"last_saved_timestamp": str(metadata.get("last_saved_timestamp", "Unknown")),
		"current_area_name": str(metadata.get("current_area_name", String(data.player.scene).get_file().get_basename())),
		"save_version": CURRENT_SAVE_VERSION}


func _runtime_idle() -> bool:
	return not busy and not SceneTransitions.busy and not Inventory._changing and not Wallet._changing and not ShopManager._buying and not QuestManager._reward_in_progress


func can_save() -> bool:
	var area: WorldArea = get_tree().current_scene as WorldArea
	if not _runtime_idle() or area == null or active_slot < 1:
		return false
	var actor: CharacterBody2D = area.find_player()
	return actor != null and actor.health.is_alive() and actor.state == actor.PlayerState.NORMAL and not actor.is_transition_locked()


func dump_current_save_snapshot() -> Dictionary:
	var area: WorldArea = get_tree().current_scene as WorldArea
	if area == null or area.find_player() == null:
		return {}
	var actor: CharacterBody2D = area.find_player()
	var position: Vector2 = actor.global_position.round()
	return {"save_version": CURRENT_SAVE_VERSION, "metadata": {
		"last_saved_timestamp": Time.get_datetime_string_from_system(true), "current_area_name": str(area.name)},
		"profile": PlayerProfile.to_save_data(), "player": {"scene": area.scene_file_path,
		"position": {"x": position.x, "y": position.y}, "facing": {"x": actor.facing_direction.x, "y": actor.facing_direction.y},
		"current_health": actor.health.current_health, "max_health": actor.health.max_health},
		"inventory": Inventory.to_save_data(), "wallet": Wallet.to_save_data(),
		"quests": QuestManager.to_save_data(), "dungeons": DungeonManager.to_save_data(),
		"world_state": WorldState.to_save_data(), "shop_stock": ShopManager.to_save_data()}


func save_game(slot: int = -1, overwrite_confirmed: bool = false) -> bool:
	if slot == -1:
		slot = active_slot
	if slot_path(slot).is_empty() or not can_save():
		return _fail("Save requires an active slot and normal gameplay in a WorldArea; close menus first.")
	if slot != active_slot and has_save(slot) and not overwrite_confirmed:
		return _fail("Confirm before overwriting a different slot.")
	var data: Dictionary = dump_current_save_snapshot()
	if _schema.validate_and_migrate(data).is_empty():
		return _fail(_schema.error)
	busy = true
	var success: bool = _write_slot(slot, data)
	busy = false
	if success:
		active_slot = slot
		last_error = ""
		game_saved.emit(slot)
		slots_changed.emit()
	return success


func _write_slot(slot: int, data: Dictionary) -> bool:
	var serialized: String = JSON.stringify(data, "\t")
	if serialized.to_utf8_buffer().size() > MAX_FILE_BYTES:
		return _fail("Save snapshot exceeds size limit.")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIRECTORY)) != OK:
		return _fail("Cannot create save directory.")
	var path: String = slot_path(slot)
	var temporary: String = path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _fail("Cannot write temporary save.")
	file.store_string(serialized)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return _fail("Save write failed; previous slot was kept.")
	# Keep one backup only when the previous primary is valid JSON/schema.
	if has_save(slot) and not _read_slot(slot).is_empty():
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak")) != OK:
			DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
			return _fail("Cannot back up previous save; overwrite cancelled.")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		return _fail("Cannot replace slot; previous save was kept.")
	return true


func load_game(slot: int) -> bool:
	if not _runtime_idle():
		return _fail("Wait for the current operation to finish.")
	var data: Dictionary = _read_slot(slot)
	if data.is_empty():
		return _fail(last_error)
	return await _restore(slot, data)


func new_game(slot: int, player_name: String, overwrite_confirmed: bool = false) -> bool:
	player_name = player_name.strip_edges()
	if not _runtime_idle() or slot_path(slot).is_empty() or player_name.is_empty() or player_name.length() > 24:
		return _fail("Choose a valid slot and a name of 1–24 characters.")
	if has_save(slot) and not overwrite_confirmed:
		return _fail("Confirm before starting a new game in an occupied slot.")
	var data: Dictionary = {"save_version": CURRENT_SAVE_VERSION, "profile": {"name": player_name},
		"player": {"scene": START_SCENE, "max_health": 6, "current_health": 6}}
	data = _schema.validate_and_migrate(data)
	return await _restore(slot, data)


func _restore(slot: int, data: Dictionary) -> bool:
	# Transition service preflights the destination before calling this apply callback.
	busy = true
	var success: bool = await SceneTransitions.restore_game_scene(data.player, _apply_managers.bind(data))
	busy = false
	if not success:
		return _fail("Load cancelled or destination lacks WorldArea, one Player, spawn, or bounds.")
	active_slot = slot
	last_error = ""
	game_loaded.emit(slot)
	return true


func _apply_managers(data: Dictionary) -> void:
	# Source scene is detached; old objects cannot react to restore signals.
	QuestManager.reset_runtime_state() # Invalidates callbacks from the previous slot.
	Wallet.reset_runtime_state()
	Inventory.reset_runtime_state()
	DungeonManager.reset_runtime_state()
	WorldState.reset_runtime_state()
	ShopManager.reset_runtime_state()
	PlayerProfile.reset_runtime_state()
	Wallet.load_save_data(data.wallet)
	Inventory.load_save_data(data.inventory)
	QuestManager.load_save_data(data.quests)
	DungeonManager.load_save_data(data.dungeons)
	WorldState.load_save_data(data.world_state)
	ShopManager.load_save_data(data.shop_stock)
	PlayerProfile.load_save_data(data.profile)


func delete_save(slot: int, confirmed: bool = false) -> bool:
	if not confirmed or not _runtime_idle() or slot_path(slot).is_empty():
		return _fail("Confirm deletion and finish current operations first.")
	for suffix: String in ["", ".bak", ".tmp"]:
		var path: String = slot_path(slot) + suffix
		if FileAccess.file_exists(path) and DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) != OK:
			return _fail("Cannot delete slot file.")
	if active_slot == slot:
		active_slot = -1
	last_error = ""
	slots_changed.emit()
	return true


func validate_slot(slot: int) -> bool:
	return not _read_slot(slot).is_empty()


func _fail(message: String) -> bool:
	last_error = message
	operation_failed.emit(message)
	return false
