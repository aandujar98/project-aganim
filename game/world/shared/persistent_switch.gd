extends Interactable

@export var persistent_id: StringName
var activated: bool = false


func _ready() -> void:
	if persistent_id.is_empty():
		push_warning("Persistent switch needs a stable ID: " + str(get_path()))
	_refresh_visual()


func _refresh_visual() -> void:
	activated = get_node("/root/WorldState").has_flag(&"activated_switches", persistent_id)
	enabled = not activated and not persistent_id.is_empty()
	$Visual.color = Color(1, 0.68, 0.25) if activated else Color(0.4, 0.5, 0.65)


func interact(actor: Node, _manager: DialogueManager) -> void:
	if enabled and _begin(actor):
		get_node("/root/WorldState").set_flag(&"activated_switches", persistent_id)
		_refresh_visual()
		_finish()
