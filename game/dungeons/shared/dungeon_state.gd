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
