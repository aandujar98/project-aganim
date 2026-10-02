extends CanvasLayer

@export var dungeon_id: StringName
@export var room_title: String
@export var instructions: String


func _ready() -> void:
	DungeonManager.state_changed.connect(_on_state_changed)
	_refresh()


func _on_state_changed(id: StringName) -> void:
	if id == dungeon_id:
		_refresh()


func _refresh() -> void:
	var state: DungeonState = DungeonManager.get_state(dungeon_id)
	$Status.text = "%s · Keys %d
Mini %s · Boss %s · Item %s" % [room_title, state.small_keys,
		"defeated" if state.miniboss_defeated else "alive", "defeated" if state.boss_defeated else "alive",
		"obtained" if state.dungeon_item_obtained else "missing"]
	$Instructions.text = "The dungeon's power has faded." if state.completed else instructions
