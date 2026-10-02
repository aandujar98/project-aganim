extends StaticBody2D

enum Condition { SWITCHES, ROOM_CLEAR, MINIBOSS, COMPLETED }

@export var dungeon_id: StringName
@export var condition: Condition = Condition.SWITCHES
@export var required_switch_ids: Array[StringName] = []
@export var required_room_id: StringName
var is_open: bool = false


func _ready() -> void:
	DungeonManager.state_changed.connect(_on_state_changed)
	_refresh()


func _on_state_changed(id: StringName) -> void:
	if id == dungeon_id:
		_refresh()


func _refresh() -> void:
	if dungeon_id.is_empty():
		push_error("Dungeon barrier needs an explicit dungeon ID.")
		return
	var state: DungeonState = DungeonManager.get_state(dungeon_id)
	match condition:
		Condition.SWITCHES:
			is_open = not required_switch_ids.is_empty()
			for switch_id: StringName in required_switch_ids:
				is_open = is_open and state.activated_switches.has(switch_id)
		Condition.ROOM_CLEAR:
			is_open = state.cleared_rooms.has(required_room_id)
		Condition.MINIBOSS:
			is_open = state.miniboss_defeated
		Condition.COMPLETED:
			is_open = state.completed
	$Visual.visible = not is_open
	$CollisionShape2D.set_deferred("disabled", is_open)
