extends Interactable

@export var dungeon_id: StringName
@export var door_id: StringName
var is_open: bool = false


func _ready() -> void:
	if dungeon_id.is_empty() or door_id.is_empty():
		enabled = false
		push_error("Persistent dungeon door needs stable IDs.")
		return
	DungeonManager.state_changed.connect(_on_state_changed)
	_restore()


func _on_state_changed(id: StringName) -> void:
	if id == dungeon_id:
		_restore()


func _restore() -> void:
	is_open = DungeonManager.has_flag(dungeon_id, &"unlocked_doors", door_id)
	enabled = not is_open
	$Visual.visible = not is_open
	$Solid/CollisionShape2D.set_deferred("disabled", is_open)


func interact(actor: Node, manager: DialogueManager) -> void:
	if is_open or not enabled:
		return
	if not _can_unlock():
		_show_dialogue(actor, manager, _message(_locked_text()))
	elif _begin(actor):
		_unlock()
		_restore()
		_finish()


func _can_unlock() -> bool:
	return DungeonManager.get_state(dungeon_id).small_keys > 0


func _unlock() -> void:
	DungeonManager.unlock_with_key(dungeon_id, door_id)


func _locked_text() -> String:
	return "The door is locked."


func _message(text: String) -> DialogueData:
	var data: DialogueData = DialogueData.new()
	var line: DialogueLine = DialogueLine.new()
	line.text = text
	data.lines.append(line)
	return data
