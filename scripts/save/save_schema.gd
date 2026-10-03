class_name SaveSchema
extends RefCounted

const CURRENT_SAVE_VERSION: int = 1
var error: String = ""


func validate_and_migrate(raw: Variant) -> Dictionary:
	error = ""
	if not raw is Dictionary:
		return _reject("Save root must be an object.")
	var data: Dictionary = raw.duplicate(true)
	if typeof(data.get("save_version")) not in [TYPE_INT, TYPE_FLOAT] or data.save_version != CURRENT_SAVE_VERSION:
		return _reject("Unsupported or missing save version.")
	data = _migrate_save_data(data)
	if not data.get("profile") is Dictionary or not data.profile.get("name") is String or data.profile.name.strip_edges().is_empty() or data.profile.name.length() > 24:
		return _reject("Save needs a valid player profile/name.")
	if not data.get("player") is Dictionary or not data.player.get("scene") is String:
		return _reject("Save needs a player scene identifier.")
	var scene: String = data.player.scene
	if not scene.begins_with("res://game/") or not scene.ends_with(".tscn") or not ResourceLoader.exists(scene, "PackedScene"):
		return _reject("Saved scene is missing or invalid: " + scene)
	for field: String in ["inventory", "wallet", "quests", "dungeons", "world_state", "shop_stock"]:
		if data.has(field) and not data[field] is Dictionary:
			return _reject("Invalid save section: " + field)
		if not data.has(field):
			data[field] = {}
	for field: String in ["position", "facing"]:
		if data.player.has(field):
			var vector: Variant = data.player[field]
			if not vector is Dictionary or not _finite_number(vector.get("x")) or not _finite_number(vector.get("y")):
				return _reject("Invalid player " + field + ".")
	if data.player.has("facing"):
		var facing: Vector2 = Vector2(data.player.facing.x, data.player.facing.y)
		if facing not in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
			return _reject("Saved facing must be cardinal.")
	data.player.max_health = SaveValues.integer(data.player.get("max_health", 6), 6, 1, 100)
	data.player.current_health = SaveValues.integer(data.player.get("current_health", data.player.max_health), data.player.max_health, 1, data.player.max_health)
	return data


func _finite_number(value: Variant) -> bool:
	return typeof(value) in [TYPE_INT, TYPE_FLOAT] and is_finite(float(value)) and absf(float(value)) <= 1000000.0


func _migrate_save_data(data: Dictionary) -> Dictionary:
	# Version 1 is the first format. Future sequential upgrades belong here.
	return data


func _reject(message: String) -> Dictionary:
	error = message
	return {}
