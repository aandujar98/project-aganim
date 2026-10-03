extends Node

var player_name: String = "Kai"
var playtime_seconds: float = 0.0


func _process(delta: float) -> void:
	if get_tree().current_scene != null:
		playtime_seconds += delta


func to_save_data() -> Dictionary:
	return {"name": player_name, "playtime_seconds": floori(playtime_seconds)}


func load_save_data(data: Dictionary) -> void:
	player_name = str(data.get("name", "Kai")).strip_edges().left(24)
	playtime_seconds = SaveValues.integer(data.get("playtime_seconds", 0))


func reset_runtime_state() -> void:
	player_name = "Kai"
	playtime_seconds = 0.0
