class_name DungeonState
extends RefCounted

var dungeon_id: StringName
var small_keys: int = 0
var activated_switches: Dictionary = {}
var unlocked_doors: Dictionary = {}
var opened_chests: Dictionary = {}
var cleared_rooms: Dictionary = {}
var miniboss_defeated: bool = false
var boss_defeated: bool = false
var dungeon_item_obtained: bool = false
var completed: bool = false


func _init(id: StringName = &"") -> void:
	dungeon_id = id


func to_save_data() -> Dictionary:
	return {"small_keys": small_keys, "activated_switches": activated_switches.keys(),
		"unlocked_doors": unlocked_doors.keys(), "opened_chests": opened_chests.keys(),
		"cleared_rooms": cleared_rooms.keys(), "miniboss_defeated": miniboss_defeated,
		"boss_defeated": boss_defeated, "dungeon_item_obtained": dungeon_item_obtained, "completed": completed}


func load_save_data(data: Dictionary) -> void:
	small_keys = SaveValues.integer(data.get("small_keys", 0))
	activated_switches = SaveValues.flags(data.get("activated_switches", []))
	unlocked_doors = SaveValues.flags(data.get("unlocked_doors", []))
	opened_chests = SaveValues.flags(data.get("opened_chests", []))
	cleared_rooms = SaveValues.flags(data.get("cleared_rooms", []))
	miniboss_defeated = typeof(data.get("miniboss_defeated")) == TYPE_BOOL and bool(data["miniboss_defeated"])
	boss_defeated = typeof(data.get("boss_defeated")) == TYPE_BOOL and bool(data["boss_defeated"])
	dungeon_item_obtained = typeof(data.get("dungeon_item_obtained")) == TYPE_BOOL and bool(data["dungeon_item_obtained"])
	completed = typeof(data.get("completed")) == TYPE_BOOL and bool(data["completed"])
