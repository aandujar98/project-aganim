extends Interactable

signal opened

@export var locked: bool = false
@export var locked_message: DialogueData

var is_open: bool = false


func _ready() -> void:
	$Visual.color = Color(0.66, 0.3, 0.35) if locked else Color(0.3, 0.65, 0.72)


func interact(actor: Node, manager: DialogueManager) -> void:
	if locked:
		_show_dialogue(actor, manager, locked_message)
	elif _begin(actor):
		is_open = true
		enabled = false
		$Visual.hide()
		$Solid/CollisionShape2D.set_deferred("disabled", true)
		opened.emit()
		_finish()
