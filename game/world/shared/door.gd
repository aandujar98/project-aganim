extends Interactable

signal opened

@export var persistent: bool = false
@export var persistent_id: StringName
@export var locked: bool = false
@export var locked_message: DialogueData

var is_open: bool = false


func _ready() -> void:
	if persistent and persistent_id.is_empty():
		enabled = false
		push_warning("Persistent door requires a stable ID.")
	elif persistent and get_node("/root/WorldState").has_flag(&"opened_doors", persistent_id):
		is_open = true
		enabled = false
		$Visual.hide()
		$Solid/CollisionShape2D.set_deferred("disabled", true)
	$Visual.color = Color(0.66, 0.3, 0.35) if locked else Color(0.3, 0.65, 0.72)


func interact(actor: Node, manager: DialogueManager) -> void:
	if locked:
		_show_dialogue(actor, manager, locked_message)
	elif _begin(actor):
		is_open = true
		enabled = false
		$Visual.hide()
		$Solid/CollisionShape2D.set_deferred("disabled", true)
		if persistent:
			get_node("/root/WorldState").set_flag(&"opened_doors", persistent_id)
		opened.emit()
		_finish()
