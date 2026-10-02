extends "res://game/dungeons/shared/dungeon_locked_door.gd"


func _can_unlock() -> bool:
	return DungeonManager.get_state(dungeon_id).miniboss_defeated


func _unlock() -> void:
	DungeonManager.set_flag(dungeon_id, &"unlocked_doors", door_id)


func _locked_text() -> String:
	return "Defeat the dungeon guardian's lieutenant first."
