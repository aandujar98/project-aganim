extends Interactable

@export var dungeon_id: StringName
@export var switch_id: StringName
@export var required_item_id: StringName
@export var inactive_message: String = "The switch needs an item."
var activated: bool = false


func _ready() -> void:
	if dungeon_id.is_empty() or switch_id.is_empty():
		enabled = false
		push_error("Persistent switch needs stable IDs.")
		return
	DungeonManager.state_changed.connect(_on_state_changed)
	_restore()


func _on_state_changed(id: StringName) -> void:
	if id == dungeon_id:
		_restore()


func _restore() -> void:
	activated = DungeonManager.has_flag(dungeon_id, &"activated_switches", switch_id)
	enabled = not activated
	$Visual.color = Color(1.0, 0.68, 0.25) if activated else Color(0.4, 0.5, 0.65)


func interact(actor: Node, manager: DialogueManager) -> void:
	if activated or not enabled:
		return
	if not required_item_id.is_empty() and not Inventory.has_item(required_item_id):
		var data: DialogueData = DialogueData.new()
		var line: DialogueLine = DialogueLine.new()
		line.text = inactive_message
		data.lines.append(line)
		_show_dialogue(actor, manager, data)
	elif _begin(actor):
		DungeonManager.set_flag(dungeon_id, &"activated_switches", switch_id)
		_finish()
